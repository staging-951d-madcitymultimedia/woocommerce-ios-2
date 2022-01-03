import ScreenObject
import XCTest

public final class ProductsScreen: ScreenObject {

    static var isVisible: Bool {
        (try? ProductsScreen().isLoaded) ?? false
    }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                // swiftlint:disable next opening_brace
                { $0.buttons["product-add-button"] },
                { $0.buttons["product-search-button"]}
                // swiftlint:enable next opening_brace
            ],
            app: app
        )
    }

    @discardableResult
    public func collapseTopBannerIfNeeded() -> Self {

        /// Without the info label, we don't need to collapse the top banner
        guard app.buttons["top-banner-view-info-label"].waitForExistence(timeout: 3) else {
           return self
        }

        /// If the banner isn't present, there's no need to collapse it
        guard app.buttons["top-banner-view-expand-collapse-button"].waitForExistence(timeout: 3) else {
            return self
        }

        app.buttons["top-banner-view-expand-collapse-button"].tap()
        return self
    }

    @discardableResult
    public func selectProduct(atIndex index: Int) throws -> SingleProductScreen {
        app.tables.cells.element(boundBy: index).tap()
        return try SingleProductScreen()
    }

    @discardableResult
    public func selectProduct(byName name: String) throws -> SingleProductScreen {
        app.tables.cells.staticTexts[name].tap()
        return try SingleProductScreen()
    }

    @discardableResult
    public func verifyProductListOnProductsScreen(products: [ProductData]) throws -> Self {
        app.assertTextVisibilityCount(textToFind: products[0].name)
        app.assertElementExistsOnCell(mainCell: products[0].name, elementToFind: products[0].stock_status)
        app.assertCorrectCellCountDisplayed(expectedCount: products.count, actualCount: app.tables.cells.count)

        return self
    }

    @discardableResult
    public func verifyProductsScreenLoaded() throws -> Self {
        XCTAssertTrue(isLoaded)
        return self
    }
}
