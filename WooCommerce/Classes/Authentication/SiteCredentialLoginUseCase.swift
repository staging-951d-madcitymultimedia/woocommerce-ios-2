import Foundation

protocol SiteCredentialLoginProtocol {
    func setupHandlers(onLoginSuccess: @escaping () -> Void,
                       onLoginFailure: @escaping (SiteCredentialLoginError) -> Void)

    func handleLogin(username: String, password: String)
}

enum SiteCredentialLoginError: Error {
    static let errorDomain = "SiteCredentialLogin"
    case loginFailed(message: String)
    case invalidLoginResponse
    case inaccessibleLoginPage
    case inaccessibleAdminPage
    case unacceptableStatusCode(code: Int)
    case genericFailure(underlyingError: Error)

    /// Used for tracking error code
    ///
    var underlyingError: NSError {
        switch self {
        case .inaccessibleLoginPage:
            return NSError(domain: Self.errorDomain, code: 404, userInfo: nil)
        case .inaccessibleAdminPage:
            return NSError(domain: Self.errorDomain, code: 404, userInfo: nil)
        case .invalidLoginResponse:
            return NSError(domain: Self.errorDomain, code: -1, userInfo: nil)
        case .loginFailed(let message):
            return NSError(domain: Self.errorDomain, code: 401, userInfo: [NSLocalizedDescriptionKey: message])
        case .unacceptableStatusCode(let code):
            return NSError(domain: Self.errorDomain, code: code, userInfo: nil)
        case .genericFailure(let underlyingError):
            return underlyingError as NSError
        }
    }
}

/// This use case handles site credential login without the need to use XMLRPC API.
/// Steps for login:
/// - Handle cookie authentication with provided credentials.
/// - Attempt retrieving plugin details. If the request fails with 401 error, the authentication fails.
///
final class SiteCredentialLoginUseCase: NSObject, SiteCredentialLoginProtocol {
    private let siteURL: String
    private let cookieJar: HTTPCookieStorage
    private var successHandler: (() -> Void)?
    private var errorHandler: ((SiteCredentialLoginError) -> Void)?
    private lazy var session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)

    init(siteURL: String,
         cookieJar: HTTPCookieStorage = HTTPCookieStorage.shared) {
        self.siteURL = siteURL
        self.cookieJar = cookieJar
        super.init()
    }

    func setupHandlers(onLoginSuccess: @escaping () -> Void,
                       onLoginFailure: @escaping (SiteCredentialLoginError) -> Void) {
        self.successHandler = onLoginSuccess
        self.errorHandler = onLoginFailure
    }

    func handleLogin(username: String, password: String) {
        // Old cookies can make the login succeeds even with incorrect credentials
        // So we need to clear all cookies before login.
        clearAllCookies()
        guard let loginRequest = buildLoginRequest(username: username, password: password),
            let nonceRequest = buildNonceRetrievalRequest() else {
            DDLogError("⛔️ Error constructing login requests")
            return
        }
        Task { @MainActor in
            do {
                try await startLogin(with: loginRequest)
            } catch let error as SiteCredentialLoginError {
                errorHandler?(error)
            } catch {
                let nsError = error as NSError
                guard nsError.domain == NSURLErrorDomain, nsError.code == -999 else {
                    errorHandler?(.genericFailure(underlyingError: nsError))
                    return
                }
                /// The previous task was cancelled upon redirect,
                /// now check the admin page access.
                do {
                    try await checkAdminPageAccess(with: nonceRequest)
                    successHandler?()
                } catch let error as SiteCredentialLoginError {
                    errorHandler?(error)
                } catch {
                    errorHandler?(.genericFailure(underlyingError: nsError))
                }
            }
        }
    }
}

private extension SiteCredentialLoginUseCase {
    func clearAllCookies() {
        if let cookies = cookieJar.cookies {
            for cookie in cookies {
                cookieJar.deleteCookie(cookie)
            }
        }
    }

    func startLogin(with loginRequest: URLRequest) async throws {
        let (data, response) = try await session.data(for: loginRequest)
        guard let response = response as? HTTPURLResponse else {
            throw SiteCredentialLoginError.invalidLoginResponse
        }

        switch response.statusCode {
        case 404:
            errorHandler?(.inaccessibleLoginPage)
        case 200:
            guard let html = String(data: data, encoding: .utf8) else {
                throw SiteCredentialLoginError.invalidLoginResponse
            }
            if let errorMessage = html.findLoginErrorMessage() {
                throw SiteCredentialLoginError.loginFailed(message: errorMessage)
            } else {
                throw SiteCredentialLoginError.invalidLoginResponse
            }
        default:
            throw SiteCredentialLoginError.unacceptableStatusCode(code: response.statusCode)
        }
    }

    func checkAdminPageAccess(with nonceRequest: URLRequest) async throws {
        let (_, response) = try await session.data(for: nonceRequest)
        guard let response = response as? HTTPURLResponse else {
            throw SiteCredentialLoginError.invalidLoginResponse
        }
        switch response.statusCode {
        case 200:
            return // success 🎉
        case 404:
            throw SiteCredentialLoginError.inaccessibleAdminPage
        default:
            throw SiteCredentialLoginError.unacceptableStatusCode(code: response.statusCode)
        }
    }

    func buildLoginRequest(username: String, password: String) -> URLRequest? {
        guard let loginURL = URL(string: siteURL + Constants.loginPath) else {
            return nil
        }

        let nonceRetrievalPath = siteURL + Constants.adminPath + Constants.wporgNoncePath
        var request = URLRequest(url: loginURL)

        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var parameters = [URLQueryItem]()
        parameters.append(URLQueryItem(name: "log", value: username))
        parameters.append(URLQueryItem(name: "pwd", value: password))
        parameters.append(URLQueryItem(name: "redirect_to", value: nonceRetrievalPath))
        var components = URLComponents()
        components.queryItems = parameters

        /// `percentEncodedQuery` creates a validly escaped URL query component, but
        /// doesn't encode the '+'. Percent encodes '+' to avoid this ambiguity.
        let characterSet = CharacterSet(charactersIn: "+").inverted
        request.httpBody = components.percentEncodedQuery?.addingPercentEncoding(withAllowedCharacters: characterSet)?.data(using: .utf8)
        return request
    }

    func buildNonceRetrievalRequest() -> URLRequest? {
        guard let nonceRetrievalURL = URL(string: siteURL + Constants.adminPath + Constants.wporgNoncePath) else {
            return nil
        }
        let request = try? URLRequest(url: nonceRetrievalURL, method: .get)
        return request
    }
}

extension SiteCredentialLoginUseCase: URLSessionDataDelegate {
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest) async -> URLRequest? {
        // Disables redirection if the request is to load the nonce retrieval URL
        if let url = request.url,
            url.absoluteString.hasSuffix(Constants.wporgNoncePath) {
            task.cancel()
            return nil
        }
        return request
    }
}

extension SiteCredentialLoginUseCase {
    enum Constants {
        static let loginPath = "/wp-login.php"
        static let adminPath = "/wp-admin"
        static let wporgNoncePath = "/admin-ajax.php?action=rest-nonce"
    }
}

private extension String {
    /// Gets contents between HTML tags with regex.
    ///
    func findLoginErrorMessage() -> String? {
        let pattern = "<div[^>]*id=\"login_error\">([\\s\\S]+?)</div>"
        let urlPattern = "<a href=\".*\">[^~]*?</a>"
        let regexOptions = NSRegularExpression.Options.caseInsensitive
        let matchOptions = NSRegularExpression.MatchingOptions(rawValue: UInt(0))
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: regexOptions)
            guard let textCheckingResult = regex.firstMatch(in: self,
                                                            options: matchOptions,
                                                            range: NSMakeRange(0, count)) else {
                return nil
            }
            let matchRange = textCheckingResult.range(at: 0)
            let match = (self as NSString).substring(with: matchRange)

            /// Removes any <a> tag
            let urlRegex = try NSRegularExpression(pattern: urlPattern, options: regexOptions)
            let results = urlRegex.matches(in: match,
                                           options: matchOptions,
                                           range: NSMakeRange(0, match.count))
            var urlMatches: [String] = []
            for result in results {
                let range = result.range(at: 0)
                let urlMatch = (match as NSString).substring(with: range)
                urlMatches.append(urlMatch)
            }
            if urlMatches.isNotEmpty {
                var updatedMatch = match
                urlMatches.forEach { url in
                    updatedMatch = updatedMatch.replacingOccurrences(of: url, with: "")
                }
                return updatedMatch.strippedHTML.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return match.strippedHTML.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            DDLogError("⚠️" + pattern + "<-- not found in string -->" + self )
            return nil
        }
    }
}
