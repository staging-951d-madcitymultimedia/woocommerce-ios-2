import Foundation
import WebKit

/// View model used for the web view controller to setup Jetpack connection during the login flow.
///
final class StoreCreationWebViewModel: AuthenticatedWebViewModel {
    // `AuthenticatedWebViewModel` protocol conformance.
    let title = Localization.title
    let initialURL: URL? = Constants.storeCreationURL

    private let completion: (Result<String, Error>) -> Void

    init(completion: @escaping (Result<String, Error>) -> Void) {
        self.completion = completion
    }

    func handleDismissal() {
        // no-op: dismissal is handled in the close button in the navigation bar.
    }

    func handleRedirect(for url: URL?) {
        guard let path = url?.absoluteString else {
            return
        }
        handleCompletionIfPossible(path)
    }

    func decidePolicy(for navigationURL: URL) async -> WKNavigationActionPolicy {
        handleCompletionIfPossible(navigationURL.absoluteString)
        return .allow
    }
}

enum StoreCreationError: Error {
    case noSiteURLInCompletionPath
    case invalidCompletionPath
    case newSiteUnavailable
    case newSiteIsNotJetpackSite
}

private extension StoreCreationWebViewModel {
    @discardableResult
    func handleCompletionIfPossible(_ url: String) -> Bool {
        guard url.starts(with: Constants.completionURLPrefix) else {
            return false
        }
        do {
            // A successful URL looks like `https://wordpress.com/checkout/thank-you/{{site_url}}/.*`.
            // There is usually more than one URL requests like this, with different parameters.
            let regex = try NSRegularExpression(pattern: "\(Constants.completionURLPrefix)" + #"(?<siteURL>[^/]+)"#, options: [])
            let urlRange = NSRange(location: 0, length: url.count)
            let matches = regex.matches(in: url, options: [], range: urlRange)
            guard let match = matches.first else {
                throw StoreCreationError.invalidCompletionPath
            }

            // Extracts the site URL substring matching the named capture group `siteURL` in the regex.
            let siteURL: String? = {
                let matchRange = match.range(withName: "siteURL")
                guard let substringRange = Range(matchRange, in: url) else {
                    return nil
                }
                return String(url[substringRange])
            }()
            guard let siteURL = siteURL else {
                throw StoreCreationError.noSiteURLInCompletionPath
            }
            // Running on the main thread is necessary if this method is triggered from `decidePolicy`.
            DispatchQueue.main.async { [weak self] in
                self?.handleSuccess(siteURL: siteURL)
            }
            return true
        } catch {
            handleError(error)
            return false
        }
    }

    func handleSuccess(siteURL: String) {
        completion(.success(siteURL))
    }

    func handleError(_ error: Error) {
        completion(.failure(error))
    }
}

private extension StoreCreationWebViewModel {
    enum Constants {
        static let storeCreationURL = WooConstants.URLs.storeCreation.asURL()
        static let completionURLPrefix = "https://wordpress.com/checkout/thank-you/"
    }

    enum Localization {
        static let title = NSLocalizedString("Create a store", comment: "Title of the store creation web view.")
    }
}
