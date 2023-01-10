import Networking
import XCTest

/// Mock for `PaymentRemote`.
///
final class MockPaymentRemote {
    /// The results to return in `loadPlan`.
    private var loadPlanResult: Result<WPComPlan, Error>?

    /// The results to return in `loadSiteCurrentPlan`.
    private var loadSiteCurrentPlanResult: Result<WPComSitePlan, Error>?

    /// The results to return in `createCart`.
    private var createCartResult: Result<Void, Error>?

    /// Returns the value when `loadPlan` is called.
    func whenLoadingPlan(thenReturn result: Result<WPComPlan, Error>) {
        loadPlanResult = result
    }

    /// Returns the value when `loadSiteCurrentPlan` is called.
    func whenLoadingSiteCurrentPlan(thenReturn result: Result<WPComSitePlan, Error>) {
        loadSiteCurrentPlanResult = result
    }

    /// Returns the value when `createCart` is called.
    func whenCreatingCart(thenReturn result: Result<Void, Error>) {
        createCartResult = result
    }
}

extension MockPaymentRemote: PaymentRemoteProtocol {
    func loadPlan(thatMatchesID productID: Int64) async throws -> WPComPlan {
        guard let result = loadPlanResult else {
            XCTFail("Could not find result for loading a plan.")
            throw NetworkError.notFound
        }
        return try result.get()
    }

    func loadSiteCurrentPlan(siteID: Int64) async throws -> WPComSitePlan {
        guard let result = loadSiteCurrentPlanResult else {
            XCTFail("Could not find result for loading a site's current plan.")
            throw NetworkError.notFound
        }
        return try result.get()
    }

    func createCart(siteID: Int64, productID: Int64) async throws {
        guard let result = createCartResult else {
            XCTFail("Could not find result for creating a cart.")
            throw NetworkError.notFound
        }
        return try result.get()
    }
}
