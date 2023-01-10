import Combine
import XCTest
import Yosemite
import enum Networking.DotcomError
@testable import WooCommerce

final class DomainSelectorViewModelTests: XCTestCase {
    private var stores: MockStoresManager!
    private var viewModel: DomainSelectorViewModel!
    private var subscriptions: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
        viewModel = .init(stores: stores, debounceDuration: 0)
    }

    override func tearDown() {
        viewModel = nil
        stores = nil
        super.tearDown()
    }

    func test_DomainAction_is_not_dispatched_when_searchTerm_is_empty() {
        // Given
        stores.whenReceivingAction(ofType: DomainAction.self) { action in
            // Then
            XCTFail("Unexpected action: \(action)")
        }

        // When
        viewModel.searchTerm = ""
        viewModel.searchTerm = ""
    }

    // MARK: - `isLoadingDomainSuggestions`

    func test_isLoadingDomainSuggestions_is_toggled_when_loading_suggestions() {
        var loadingValues: [Bool] = []
        viewModel.$isLoadingDomainSuggestions.sink { value in
            loadingValues.append(value)
        }.store(in: &subscriptions)

        mockDomainSuggestionsFailure(error: SampleError.first)

        // When
        viewModel.searchTerm = "Woo"

        // Then
        waitUntil {
            loadingValues == [false, true, false]
        }
    }

    // MARK: - `state`

    func test_state_is_placeholder_when_searchTerm_is_empty() {
        // When
        viewModel.searchTerm = ""

        // Then
        XCTAssertEqual(viewModel.state, .placeholder)
    }

    func test_state_is_results_with_free_domain_only_on_domain_suggestions_success() {
        // Given
        mockDomainSuggestionsSuccess(suggestions: [
            .init(name: "free.com", isFree: true),
            .init(name: "paid.com", isFree: false)
        ])

        // When
        viewModel.searchTerm = "woo"

        // Then
        waitUntil {
            self.viewModel.state == .results(domains: ["free.com"])
        }
    }

    func test_state_is_errorMessage_with_default_error_message_when_failure_is_not_DotcomError() {
        // Given
        mockDomainSuggestionsFailure(error: SampleError.first)

        // When
        viewModel.searchTerm = "woo"

        // Then
        waitUntil {
            self.viewModel.state == .error(message: DomainSelectorViewModel.Localization.defaultErrorMessage)
        }
    }

    func test_state_is_errorMessage_with_DotcomError_message_when_failure_is_DotcomError() {
        // Given
        mockDomainSuggestionsFailure(error: DotcomError.unknown(code: "", message: "error message"))

        // When
        viewModel.searchTerm = "woo"

        // Then
        waitUntil {
            self.viewModel.state == .error(message: "error message")
        }
    }

    func test_state_is_updated_from_errorMessage_to_results_when_changing_search_term_after_failure() {
        // Given
        mockDomainSuggestionsFailure(error: SampleError.first)

        // When
        viewModel.searchTerm = "woo"
        waitUntil {
            self.viewModel.state == .error(message: DomainSelectorViewModel.Localization.defaultErrorMessage)
        }

        mockDomainSuggestionsSuccess(suggestions: [])
        viewModel.searchTerm = "wooo"

        // Then
        waitUntil {
            self.viewModel.state == .results(domains: [])
        }
    }
}

private extension DomainSelectorViewModelTests {
    func mockDomainSuggestionsSuccess(suggestions: [FreeDomainSuggestion]) {
        stores.whenReceivingAction(ofType: DomainAction.self) { action in
            switch action {
            case let .loadFreeDomainSuggestions(_, completion):
                completion(.success(suggestions))
            default:
                return
            }
        }
    }

    func mockDomainSuggestionsFailure(error: Error) {
        stores.whenReceivingAction(ofType: DomainAction.self) { action in
            switch action {
            case let .loadFreeDomainSuggestions(_, completion):
                completion(.failure(error))
            default:
                return
            }
        }
    }
}
