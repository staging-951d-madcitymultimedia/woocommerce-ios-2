import Foundation
import StoreKit
import Yosemite

protocol WPComPlanProduct {
    // The localized product name, to be used as title in UI
    var displayName: String { get }
    // The localized product description
    var description: String { get }
    // The unique product identifier. To be used in further actions e.g purchasing a product
    var id: String { get }
    // The localized price, including currency
    var displayPrice: String { get }
}

extension StoreKit.Product: WPComPlanProduct {}

protocol InAppPurchasesForWPComPlansProtocol {
    /// Retrieves asynchronously all WPCom plans In-App Purchases products.
    ///
    func fetchProducts() async throws -> [WPComPlanProduct]

    /// Returns whether the user purchases the product identified with the passed id.
    ///
    /// - Parameters:
    ///     - id: the id of the product whose purchase is to be verified
    ///
    func userDidPurchaseProduct(with id: String) async throws -> Bool

    /// Triggers the purchase of WPCom plan specified by the passed product id, linked to the passed site Id.
    ///
    /// - Parameters:
    ///     id: the id of the product to be purchased
    ///     remoteSiteId: the id of the site linked to the purchasing plan
    ///
    func purchaseProduct(with id: String, for remoteSiteId: Int64) async throws

    /// Retries forwarding the product purchase to our backend, so the plan can be unlocked.
    /// This can happen when the purchase was previously successful but unlocking the WPCom plan request
    /// failed.
    ///
    /// - Parameters:
    ///     id: the id of the purchased product whose WPCom plan unlock failed
    ///
    func retryWPComSyncForPurchasedProduct(with id: String) async throws

    /// Returns whether In-App Purchases are supported for the current user configuration
    ///
    func inAppPurchasesAreSupported() async -> Bool
}

@MainActor
final class InAppPurchasesForWPComPlansManager: InAppPurchasesForWPComPlansProtocol {
    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    func fetchProducts() async throws -> [WPComPlanProduct] {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(InAppPurchaseAction.loadProducts(completion: { result in
                switch result {
                case .success(let products):
                    continuation.resume(returning: products)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }))
        }
    }

    func userDidPurchaseProduct(with id: String) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(InAppPurchaseAction.userDidPurchaseProduct(productID: id, completion: { result in
                switch result {
                case .success(let productIsPurchased):
                    continuation.resume(returning: productIsPurchased)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }))
        }
    }

    func purchaseProduct(with id: String, for remoteSiteId: Int64) async throws {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(InAppPurchaseAction.purchaseProduct(siteID: remoteSiteId, productID: id, completion: { result in
                switch result {
                case .success(_):
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }))
        }
    }

    func retryWPComSyncForPurchasedProduct(with id: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(InAppPurchaseAction.retryWPComSyncForPurchasedProduct(productID: id, completion: { result in
                switch result {
                case .success(let products):
                    continuation.resume(returning: products)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }))
        }
    }

    func inAppPurchasesAreSupported() async -> Bool {
        await withCheckedContinuation { continuation in
            stores.dispatch(InAppPurchaseAction.inAppPurchasesAreSupported(completion: { result in
                continuation.resume(returning: result)
            }))
        }
    }
}
