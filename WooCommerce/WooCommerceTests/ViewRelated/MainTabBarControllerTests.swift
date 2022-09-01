import Combine
import TestKit
import XCTest
@testable import WooCommerce
import Yosemite

final class MainTabBarControllerTests: XCTestCase {
    private var stores: StoresManager!
    // For test cases that assert on a view controller's navigation behavior, a retained window is required
    // with its `rootViewController` set to the view controller.
    private let window = UIWindow(frame: UIScreen.main.bounds)

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        let mockAuthenticationManager = MockAuthenticationManager()
        ServiceLocator.setAuthenticationManager(mockAuthenticationManager)
        stores = DefaultStoresManager.testingInstance
        ServiceLocator.setStores(stores)

        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)

        window.makeKeyAndVisible()
    }

    override func tearDown() {
        window.resignKey()
        window.rootViewController = nil

        analytics = nil
        analyticsProvider = nil

        SessionManager.testingInstance.reset()
        stores = nil
        super.tearDown()
    }

    func test_tab_view_controllers_are_not_empty_after_updating_default_site() {

        // Arrange
        // Sets mock `FeatureFlagService` before `MainTabBarController` is initialized so that the feature flags are set correctly.
        let featureFlagService = MockFeatureFlagService()
        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder, featureFlagService: featureFlagService)
        }) else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // Action
        let siteID: Int64 = 134
        stores.updateDefaultStore(storeID: siteID)

        // Assert
        XCTAssertEqual(tabBarController.viewControllers?.count, 4)
        assertThat(tabBarController.tabNavigationController(tab: .myStore)?.topViewController,
                   isAnInstanceOf: DashboardViewController.self)
        assertThat(tabBarController.tabNavigationController(tab: .orders)?.topViewController,
                   isAnInstanceOf: OrdersRootViewController.self)
        assertThat(tabBarController.tabNavigationController(tab: .products)?.topViewController,
                   isAnInstanceOf: ProductsViewController.self)
        assertThat(tabBarController.tabNavigationController(tab: .hubMenu)?.topViewController,
                   isAnInstanceOf: HubMenuViewController.self)
    }

    func test_tab_view_controllers_returns_expected_values_with_hub_menu_enabled() {
        // Arrange
        // Sets mock `FeatureFlagService` before `MainTabBarController` is initialized so that the feature flags are set correctly.
        let featureFlagService = MockFeatureFlagService()
        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder, featureFlagService: featureFlagService)
        }) else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // Action
        let siteID: Int64 = 134
        stores.updateDefaultStore(storeID: siteID)

        // Assert
        XCTAssertEqual(tabBarController.viewControllers?.count, 4)
        assertThat(tabBarController.tabNavigationController(tab: .myStore)?.topViewController,
                   isAnInstanceOf: DashboardViewController.self)
        assertThat(tabBarController.tabNavigationController(tab: .orders)?.topViewController,
                   isAnInstanceOf: OrdersRootViewController.self)
        assertThat(tabBarController.tabNavigationController(tab: .products)?.topViewController,
                   isAnInstanceOf: ProductsViewController.self)
        assertThat(tabBarController.tabNavigationController(tab: .hubMenu)?.topViewController,
                   isAnInstanceOf: HubMenuViewController.self)
    }

    func test_tab_view_controllers_returns_expected_values_with_hub_menu_and_split_view_in_orders_tab_enabled() {
        // Arrange
        // Sets mock `FeatureFlagService` before `MainTabBarController` is initialized so that the feature flags are set correctly.
        let isSplitViewInOrdersTabOn = true
        let featureFlagService = MockFeatureFlagService(isSplitViewInOrdersTabOn: isSplitViewInOrdersTabOn)

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder, featureFlagService: featureFlagService)
        }) else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // Action
        let siteID: Int64 = 134
        stores.updateDefaultStore(storeID: siteID)

        // Assert
        XCTAssertEqual(tabBarController.viewControllers?.count, 4)
        assertThat(tabBarController.tabNavigationController(tab: .myStore)?.topViewController,
                   isAnInstanceOf: DashboardViewController.self)
        assertThat(tabBarController.tabNavigationController(tab: .orders)?.topViewController,
                   isAnInstanceOf: OrdersSplitViewWrapperController.self)
        assertThat(tabBarController.tabNavigationController(tab: .products)?.topViewController,
                   isAnInstanceOf: ProductsViewController.self)
        assertThat(tabBarController.tabNavigationController(tab: .hubMenu)?.topViewController,
                   isAnInstanceOf: HubMenuViewController.self)
    }

    func test_tab_root_viewControllers_are_replaced_after_updating_to_a_different_site() throws {
        // Arrange
        ServiceLocator.setFeatureFlagService(MockFeatureFlagService())
        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as? MainTabBarController else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // Action
        stores.updateDefaultStore(storeID: 134)
        let viewControllersBeforeSiteChange = tabBarController.tabRootViewControllers
        stores.updateDefaultStore(storeID: 630)
        let viewControllersAfterSiteChange = tabBarController.tabRootViewControllers

        // Assert
        XCTAssertEqual(viewControllersBeforeSiteChange.count, viewControllersAfterSiteChange.count)
        XCTAssertNotEqual(viewControllersBeforeSiteChange[WooTab.myStore.visibleIndex()],
                          viewControllersAfterSiteChange[WooTab.myStore.visibleIndex()])
        XCTAssertNotEqual(viewControllersBeforeSiteChange[WooTab.orders.visibleIndex()],
                          viewControllersAfterSiteChange[WooTab.orders.visibleIndex()])
        XCTAssertNotEqual(viewControllersBeforeSiteChange[WooTab.products.visibleIndex()],
                          viewControllersAfterSiteChange[WooTab.products.visibleIndex()])
        XCTAssertNotEqual(viewControllersBeforeSiteChange[WooTab.hubMenu.visibleIndex()],
                          viewControllersAfterSiteChange[WooTab.hubMenu.visibleIndex()])
    }

    func test_tab_view_controllers_stay_the_same_after_updating_to_the_same_site() throws {
        // Arrange
        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as? MainTabBarController else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // Action
        let siteID: Int64 = 134
        stores.updateDefaultStore(storeID: siteID)
        let viewControllersBeforeSiteChange = try XCTUnwrap(tabBarController.viewControllers)
        stores.updateDefaultStore(storeID: siteID)
        let viewControllersAfterSiteChange = try XCTUnwrap(tabBarController.viewControllers)

        // Assert
        XCTAssertEqual(viewControllersBeforeSiteChange, viewControllersAfterSiteChange)
    }

    func test_selected_tab_is_dashboard_after_navigating_to_products_tab_then_updating_to_a_different_site() throws {
        // Arrange
        ServiceLocator.setFeatureFlagService(MockFeatureFlagService())
        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as? MainTabBarController else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // Action
        stores.updateDefaultStore(storeID: 134)
        tabBarController.navigateTo(.products)
        let selectedTabIndexBeforeSiteChange = tabBarController.selectedIndex
        stores.updateDefaultStore(storeID: 630)
        let selectedTabIndexAfterSiteChange = tabBarController.selectedIndex

        // Assert
        XCTAssertEqual(selectedTabIndexBeforeSiteChange, WooTab.products.visibleIndex())
        XCTAssertEqual(selectedTabIndexAfterSiteChange, WooTab.myStore.visibleIndex())
    }

    func test_when_receiving_product_image_upload_error_a_notice_is_enqueued() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isBackgroundImageUploadEnabled: true)
        let noticePresenter = MockNoticePresenter()
        let statusUpdates = PassthroughSubject<ProductImageUploadErrorInfo, Never>()
        let productImageUploader = MockProductImageUploader(errors: statusUpdates.eraseToAnyPublisher())

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder,
                                        featureFlagService: featureFlagService,
                                        noticePresenter: noticePresenter,
                                        productImageUploader: productImageUploader)
        }) else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)
        XCTAssertEqual(noticePresenter.queuedNotices.count, 0)

        // When
        statusUpdates.send(.init(siteID: 134,
                                 productOrVariationID: .product(id: 606),
                                 productImageStatuses: [],
                                 error: .failedUploadingImage(error: NSError(domain: "", code: 8))))

        // Given
        XCTAssertEqual(noticePresenter.queuedNotices.count, 1)
        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        XCTAssertEqual(notice.title, MainTabBarController.Localization.imageUploadFailureNoticeTitle)
    }

    func test_when_receiving_product_images_saving_error_a_notice_is_enqueued() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isBackgroundImageUploadEnabled: true)
        let noticePresenter = MockNoticePresenter()
        let statusUpdates = PassthroughSubject<ProductImageUploadErrorInfo, Never>()
        let productImageUploader = MockProductImageUploader(errors: statusUpdates.eraseToAnyPublisher())

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder,
                                        featureFlagService: featureFlagService,
                                        noticePresenter: noticePresenter,
                                        productImageUploader: productImageUploader)
        }) else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)
        XCTAssertEqual(noticePresenter.queuedNotices.count, 0)

        // When
        statusUpdates.send(.init(siteID: 134,
                                 productOrVariationID: .product(id: 606),
                                 productImageStatuses: [],
                                 error: .failedSavingProductAfterImageUpload(error: NSError(domain: "", code: 18))))

        // Given
        XCTAssertEqual(noticePresenter.queuedNotices.count, 1)
        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        XCTAssertEqual(notice.title, MainTabBarController.Localization.productImagesSavingFailureNoticeTitle)
    }

    func test_when_receiving_variation_image_saving_error_a_notice_is_enqueued() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isBackgroundImageUploadEnabled: true)
        let noticePresenter = MockNoticePresenter()
        let statusUpdates = PassthroughSubject<ProductImageUploadErrorInfo, Never>()
        let productImageUploader = MockProductImageUploader(errors: statusUpdates.eraseToAnyPublisher())

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder,
                                        featureFlagService: featureFlagService,
                                        noticePresenter: noticePresenter,
                                        productImageUploader: productImageUploader)
        }) else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)
        XCTAssertEqual(noticePresenter.queuedNotices.count, 0)

        // When
        statusUpdates.send(.init(siteID: 134,
                                 productOrVariationID: .variation(productID: 0, variationID: 608),
                                 productImageStatuses: [],
                                 error: .failedSavingProductAfterImageUpload(error: NSError(domain: "", code: 18))))

        // Given
        XCTAssertEqual(noticePresenter.queuedNotices.count, 1)
        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        XCTAssertEqual(notice.title, MainTabBarController.Localization.variationImageSavingFailureNoticeTitle)
    }

    func test_when_tapping_product_image_upload_error_notice_product_details_is_pushed_to_products_tab() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isBackgroundImageUploadEnabled: true)
        let noticePresenter = MockNoticePresenter()
        let statusUpdates = PassthroughSubject<ProductImageUploadErrorInfo, Never>()
        let productImageUploader = MockProductImageUploader(errors: statusUpdates.eraseToAnyPublisher())

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder,
                                        featureFlagService: featureFlagService,
                                        noticePresenter: noticePresenter,
                                        productImageUploader: productImageUploader)
        }) else {
            return
        }
        window.rootViewController = tabBarController

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // When
        let error = NSError(domain: "", code: 8)
        statusUpdates.send(.init(siteID: 134,
                                 productOrVariationID: .product(id: 606),
                                 productImageStatuses: [],
                                 error: .failedUploadingImage(error: error)))
        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        notice.actionHandler?()

        let productsNavigationController = try XCTUnwrap(tabBarController.tabNavigationController(tab: .products))
        waitUntil {
            productsNavigationController.presentedViewController != nil
        }

        // Then
        let productNavigationController = try XCTUnwrap(productsNavigationController.presentedViewController as? UINavigationController)
        assertThat(productNavigationController.topViewController, isAnInstanceOf: ProductLoaderViewController.self)
    }

    func test_when_receiving_product_image_upload_error_with_feature_flag_off_a_notice_is_not_enqueued() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isBackgroundImageUploadEnabled: false)
        let noticePresenter = MockNoticePresenter()
        let statusUpdates = PassthroughSubject<ProductImageUploadErrorInfo, Never>()
        let productImageUploader = MockProductImageUploader(errors: statusUpdates.eraseToAnyPublisher())

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder,
                                        featureFlagService: featureFlagService,
                                        noticePresenter: noticePresenter,
                                        productImageUploader: productImageUploader)
        }) else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)
        XCTAssertEqual(noticePresenter.queuedNotices.count, 0)

        // When
        let error = NSError(domain: "", code: 8)
        statusUpdates.send(.init(siteID: 134,
                                 productOrVariationID: .product(id: 606),
                                 productImageStatuses: [],
                                 error: .failedUploadingImage(error: error)))

        // Then
        XCTAssertEqual(noticePresenter.queuedNotices.count, 0)
    }

    // MARK: - Analytics

    func test_failureUploadingImageNotice_events_are_tracked_when_showing_and_tapping_product_image_upload_error_notice() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isBackgroundImageUploadEnabled: true)
        let noticePresenter = MockNoticePresenter()
        let statusUpdates = PassthroughSubject<ProductImageUploadErrorInfo, Never>()
        let productImageUploader = MockProductImageUploader(errors: statusUpdates.eraseToAnyPublisher())

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder,
                                        featureFlagService: featureFlagService,
                                        noticePresenter: noticePresenter,
                                        productImageUploader: productImageUploader,
                                        analytics: self.analytics)
        }) else {
            return
        }
        window.rootViewController = tabBarController

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // When
        let error = NSError(domain: "", code: 8)
        statusUpdates.send(.init(siteID: 134,
                                 productOrVariationID: .product(id: 606),
                                 productImageStatuses: [],
                                 error: .failedUploadingImage(error: error)))
        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        notice.actionHandler?()

        let productsNavigationController = try XCTUnwrap(tabBarController.tabNavigationController(tab: .products))
        waitUntil {
            productsNavigationController.presentedViewController != nil
        }

        // Then
        assertEqual([
            WooAnalyticsStat.failureUploadingImageNoticeShown.rawValue,
            WooAnalyticsStat.failureUploadingImageNoticeTapped.rawValue,
        ], analyticsProvider.receivedEvents)
        assertEqual("product", analyticsProvider.receivedProperties[safe: 0]?["type"] as? String)
        assertEqual("product", analyticsProvider.receivedProperties[safe: 1]?["type"] as? String)
    }

    func test_failureSavingProductAfterImageUploadNotice_events_are_tracked_when_showing_and_tapping_product_saving_error_notice() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isBackgroundImageUploadEnabled: true)
        let noticePresenter = MockNoticePresenter()
        let statusUpdates = PassthroughSubject<ProductImageUploadErrorInfo, Never>()
        let productImageUploader = MockProductImageUploader(errors: statusUpdates.eraseToAnyPublisher())

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder,
                                        featureFlagService: featureFlagService,
                                        noticePresenter: noticePresenter,
                                        productImageUploader: productImageUploader,
                                        analytics: self.analytics)
        }) else {
            return
        }
        window.rootViewController = tabBarController

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // When
        let error = NSError(domain: "", code: 8)
        statusUpdates.send(.init(siteID: 134,
                                 productOrVariationID: .product(id: 606),
                                 productImageStatuses: [],
                                 error: .failedSavingProductAfterImageUpload(error: error)))
        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        notice.actionHandler?()

        let productsNavigationController = try XCTUnwrap(tabBarController
                    .tabNavigationController(tab: .products))
        waitUntil {
            productsNavigationController.presentedViewController != nil
        }

        // Then
        assertEqual([
            WooAnalyticsStat.failureSavingProductAfterImageUploadNoticeShown.rawValue,
            WooAnalyticsStat.failureSavingProductAfterImageUploadNoticeTapped.rawValue,
        ], analyticsProvider.receivedEvents)
        assertEqual("product", analyticsProvider.receivedProperties[safe: 0]?["type"] as? String)
        assertEqual("product", analyticsProvider.receivedProperties[safe: 1]?["type"] as? String)
    }
}

private extension MainTabBarController {
    var tabRootViewControllers: [UIViewController] {
        viewControllers?.compactMap { $0 as? UINavigationController }.compactMap { $0.viewControllers.first } ?? []
    }

    func tabNavigationController(tab: WooTab) -> UINavigationController? {
        guard let navigationController = viewControllers?.compactMap({ $0 as? UINavigationController })[tab.visibleIndex()] else {
            XCTFail("Unexpected access to navigation controller at tab: \(tab)")
            return nil
        }
        return navigationController
    }
}
