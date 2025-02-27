import XCTest
@testable import Networking


/// ProductMapper Unit Tests
///
final class ProductMapperTests: XCTestCase {

    private enum ProductMapperTestsError: Error {
        case unableToLoadFile
    }

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 33334444

    /// Dummy Product ID.
    ///
    private let dummyProductID: Int64 = 282

    /// Verifies that all of the Product Fields are parsed correctly.
    ///
    func test_Product_fields_are_properly_parsed() throws {
        let productsToTest = try mapLoadProductResponse()
        for product in productsToTest {
            XCTAssertEqual(product.siteID, dummySiteID)
            XCTAssertEqual(product.productID, dummyProductID)
            XCTAssertEqual(product.name, "Book the Green Room")
            XCTAssertEqual(product.slug, "book-the-green-room")
            XCTAssertEqual(product.permalink, "https://example.com/product/book-the-green-room/")

            let dateCreated = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-02-19T17:33:31")
            let dateModified = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-02-19T17:48:01")
            XCTAssertEqual(product.dateCreated, dateCreated)
            XCTAssertEqual(product.dateModified, dateModified)

            XCTAssertEqual(product.productTypeKey, "booking")
            XCTAssertEqual(product.statusKey, "publish")
            XCTAssertFalse(product.featured)
            XCTAssertEqual(product.catalogVisibilityKey, "visible")

            XCTAssertEqual(product.fullDescription, "<p>This is the party room!</p>\n")
            XCTAssertEqual(product.shortDescription, """
            [contact-form]\n<p>The green room&#8217;s max capacity is 30 people. Reserving the date / time of your event is free. \
            We can also accommodate large groups, with seating for 85 board game players at a time. If you have a large group, let \
            us know and we&#8217;ll send you our large group rate.</p>\n<p>GROUP RATES</p>\n<p>Reserve your event for up to 30 guests for $100.</p>\n
            """)
            XCTAssertEqual(product.sku, "")

            XCTAssertEqual(product.price, "0")
            XCTAssertEqual(product.regularPrice, "")
            XCTAssertEqual(product.salePrice, "")
            XCTAssertFalse(product.onSale)

            XCTAssertTrue(product.purchasable)
            XCTAssertEqual(product.totalSales, 0)
            XCTAssertTrue(product.virtual)

            XCTAssertTrue(product.downloadable)
            XCTAssertEqual(product.downloads.count, 3)
            XCTAssertEqual(product.downloadLimit, 1)
            XCTAssertEqual(product.downloadExpiry, 1)

            XCTAssertEqual(product.externalURL, "http://somewhere.com")
            XCTAssertEqual(product.taxStatusKey, "taxable")
            XCTAssertEqual(product.taxClass, "")

            XCTAssertFalse(product.manageStock)
            XCTAssertNil(product.stockQuantity)
            XCTAssertEqual(product.stockStatusKey, "instock")

            XCTAssertEqual(product.backordersKey, "no")
            XCTAssertEqual(product.backordersSetting, .notAllowed)
            XCTAssertFalse(product.backordersAllowed)
            XCTAssertFalse(product.backordered)

            XCTAssertTrue(product.soldIndividually)
            XCTAssertEqual(product.weight, "213")

            XCTAssertFalse(product.shippingRequired)
            XCTAssertFalse(product.shippingTaxable)
            XCTAssertEqual(product.shippingClass, "")
            XCTAssertEqual(product.shippingClassID, 134)

            XCTAssertTrue(product.reviewsAllowed)
            XCTAssertEqual(product.averageRating, "4.30")
            XCTAssertEqual(product.ratingCount, 23)

            XCTAssertEqual(product.relatedIDs, [31, 22, 369, 414, 56])
            XCTAssertEqual(product.upsellIDs, [99, 1234566])
            XCTAssertEqual(product.crossSellIDs, [1234, 234234, 3])
            XCTAssertEqual(product.parentID, 0)

            XCTAssertEqual(product.purchaseNote, "Thank you!")
            XCTAssertEqual(product.images.count, 1)

            XCTAssertEqual(product.attributes.count, 2)
            XCTAssertEqual(product.defaultAttributes.count, 2)
            XCTAssertEqual(product.variations.count, 3)
            XCTAssertEqual(product.groupedProducts, [])

            XCTAssertEqual(product.menuOrder, 0)
            XCTAssertEqual(product.productType, ProductType(rawValue: "booking"))
        }
    }

    /// Verifies that the fields of the Product with alternative types are parsed correctly when they have different types than in the struct.
    /// Currently, `price`, `regularPrice`, `salePrice`, `manageStock`, `soldIndividually`, `purchasable`, and `permalink`  allow alternative types.
    ///
    func test_that_product_alternative_types_are_properly_parsed() throws {
        let product = try XCTUnwrap(mapLoadProductResponseWithAlternativeTypes())

        XCTAssertEqual(product.price, "17")
        XCTAssertEqual(product.regularPrice, "12.89")
        XCTAssertEqual(product.salePrice, "26.73")
        XCTAssertTrue(product.manageStock)
        XCTAssertFalse(product.soldIndividually)
        XCTAssertTrue(product.purchasable)
        XCTAssertEqual(product.permalink, "")
    }

    /// Verifies that the `salePrice` field of the Product are parsed correctly when the product is on sale, and the sale price is an empty string
    ///
    func test_that_product_sale_price_is_properly_parsed() {
        guard let product = mapLoadProductOnSaleWithEmptySalePriceResponse() else {
            XCTFail("Failed to parse product")
            return
        }

        XCTAssertEqual(product.salePrice, "0")
        XCTAssertTrue(product.onSale)
    }

    /// Test that ProductTypeKey converts to a ProductType enum properly.
    ///
    func test_that_product_type_key_converts_to_enum_properly() throws {
        let productsToTest = try mapLoadProductResponse()
        for product in productsToTest {
            let customType = ProductType(rawValue: "booking")
            XCTAssertEqual(product.productTypeKey, "booking")
            XCTAssertEqual(product.productType, customType)
        }
    }

    /// Test that categories are properly mapped.
    ///
    func test_that_product_categories_are_properly_mapped() throws {
        let productsToTest = try mapLoadProductResponse()
        for product in productsToTest {
            let categories = product.categories
            XCTAssertEqual(categories.count, 1)

            let category = product.categories[0]

            XCTAssertEqual(category.categoryID, 36)
            XCTAssertEqual(category.name, "Events")
            XCTAssertEqual(category.slug, "events")
            XCTAssertTrue(category.categoryID == 36)
        }
    }

    /// Test that tags are properly mapped.
    ///
    func test_that_product_tags_are_properly_mapped() throws {
        let productsToTest = try mapLoadProductResponse()
        for product in productsToTest {
            let tags = product.tags
            XCTAssertNotNil(tags)
            XCTAssertEqual(tags.count, 9)

            let tag = tags[1]
            XCTAssertEqual(tag.tagID, 38)
            XCTAssertEqual(tag.name, "party room")
            XCTAssertEqual(tag.slug, "party-room")
        }
    }

    /// Test that product images are properly mapped.
    ///
    func test_that_product_images_are_properly_mapped() throws {
        let productsToTest = try mapLoadProductResponse()
        for product in productsToTest {
            let images = product.images
            XCTAssertEqual(images.count, 1)

            let productImage = images[0]
            let dateCreated = DateFormatter.Defaults.dateTimeFormatter.date(from: "2018-01-26T21:49:45")
            let dateModified = DateFormatter.Defaults.dateTimeFormatter.date(from: "2018-01-26T21:50:11")
            XCTAssertEqual(productImage.imageID, 19)
            XCTAssertEqual(productImage.dateCreated, dateCreated)
            XCTAssertEqual(productImage.dateModified, dateModified)
            XCTAssertEqual(productImage.src,
                           "https://somewebsite.com/thuy-nonjtpk.mystagingwebsite.com/wp-content/uploads/2018/01/vneck-tee.jpg.png")
            XCTAssertEqual(productImage.name, "Vneck Tshirt")
            XCTAssert(productImage.alt?.isEmpty == true)
        }
    }

    /// Test that product downloadable files are properly mapped.
    ///
    func test_that_product_downloadable_files_are_properly_mapped() throws {
        // Given
        let productsToTest = try mapLoadProductResponse()
        for product in productsToTest {
            // When
            let files = product.downloads

            XCTAssertEqual(files.count, 3)
            let actualDownloadableFile = files[0]
            let expectedDownloadableFile = ProductDownload(downloadID: "1f9c11f99ceba63d4403c03bd5391b11",
                                                           name: "Song #1",
                                                           fileURL: "https://example.com/woo-single-1.ogg")

            // Then
            XCTAssertEqual(actualDownloadableFile, expectedDownloadableFile)
        }
    }

    /// Test that product attributes are properly mapped
    ///
    func test_that_product_attributes_are_properly_mapped() throws {
        let productsToTest = try mapLoadProductResponse()
        for product in productsToTest {
            let attributes = product.attributes
            XCTAssertEqual(attributes.count, 2)

            let attribute = attributes[0]

            XCTAssertEqual(attribute.attributeID, 0)
            XCTAssertEqual(attribute.name, "Color")
            XCTAssertEqual(attribute.position, 1)
            XCTAssertTrue(attribute.visible)
            XCTAssertTrue(attribute.variation)

            let option1 = attribute.options[0]
            let option2 = attribute.options[1]
            let option3 = attribute.options[2]
            XCTAssertEqual(option1, "Purple")
            XCTAssertEqual(option2, "Yellow")
            XCTAssertEqual(option3, "Hot Pink")
        }
    }

    /// Test that the default product attributes map properly
    ///
    func test_that_default_product_attributes_map_properly() throws {
        let productsToTest = try mapLoadProductResponse()
        for product in productsToTest {
            let defaultAttributes = product.defaultAttributes
            XCTAssertEqual(defaultAttributes.count, 2)

            let attribute1 = defaultAttributes[0]
            let attribute2 = defaultAttributes[1]

            XCTAssertEqual(attribute1.attributeID, 0)
            XCTAssertEqual(attribute1.name, "Color")
            XCTAssertEqual(attribute1.option, "Purple")

            XCTAssert(attribute2.attributeID == 0)
            XCTAssertEqual(attribute2.name, "Size")
            XCTAssertEqual(attribute2.option, "Medium")
        }
    }

    /// Test that product add-ons are properly parsed.
    ///
    func test_product_add_ons_are_properly_parsed() throws {
        let productsToTest = try mapLoadProductResponse()
        for product in productsToTest {
            let addOns = product.addOns
            XCTAssertEqual(addOns.count, 3)

            let firstAddOn = addOns[0]
            XCTAssertEqual(firstAddOn.name, "Topping")
            XCTAssertEqual(firstAddOn.options.count, 4)

            let firstOption = firstAddOn.options[0]
            XCTAssertEqual(firstOption.label, "Peperoni")
            XCTAssertEqual(firstOption.price, "3")
        }
    }

    func test_product_image_alt_is_nil_when_malformed() throws {
        // Given
        let product = try XCTUnwrap(mapLoadProductWithMalformedImageAltAndVariations())

        // Then
        XCTAssertFalse(product.images.isEmpty)
        XCTAssertNil(product.images.first?.alt)
    }

    func test_product_variation_list_is_empty_when_malformed() throws {
        // Given
        let product = try XCTUnwrap(mapLoadProductWithMalformedImageAltAndVariations())

        // Then
        XCTAssertTrue(product.variations.isEmpty)
    }

    /// Test that products with the `bundle` product type are properly parsed.
    ///
    func test_product_bundles_are_properly_parsed() throws {
        // Given
        let product = try XCTUnwrap(mapLoadProductBundleResponse())
        let bundledItem = try XCTUnwrap(product.bundledItems.first)

        // Then
        // Check parsed Product properties
        XCTAssertEqual(product.productType, .bundle)
        XCTAssertEqual(product.bundleStockStatus, .insufficientStock)
        XCTAssertEqual(product.bundleStockQuantity, 0)
        XCTAssertEqual(product.bundledItems.count, 3)

        // Check parsed ProductBundleItem properties
        XCTAssertEqual(bundledItem.bundledItemID, 6)
        XCTAssertEqual(bundledItem.productID, 36)
        XCTAssertEqual(bundledItem.menuOrder, 0)
        XCTAssertEqual(bundledItem.title, "Beanie with Logo")
        XCTAssertEqual(bundledItem.stockStatus, .inStock)
    }

    /// Test that products with the `composite` product type are properly parsed.
    ///
    func test_composite_products_are_properly_parsed() throws {
        // Given
        let product = try XCTUnwrap(mapLoadCompositeProductResponse())
        let compositeComponent = try XCTUnwrap(product.compositeComponents.first)

        // Then
        // Check parsed Product properties
        XCTAssertEqual(product.productType, .composite)
        XCTAssertEqual(product.compositeComponents.count, 3)

        // Check parsed ProductCompositeComponent properties
        XCTAssertEqual(compositeComponent.componentID, "1679310855")
        XCTAssertEqual(compositeComponent.title, "Camera Body")
        XCTAssertEqual(compositeComponent.description,
                       "<p>Choose between the Nikon D600 or the powerful 5D Mark III and take your creativity to new levels.</p>\n")
        XCTAssertEqual(compositeComponent.imageURL, "https://example.com/woo.jpg")
        XCTAssertEqual(compositeComponent.optionType, .productIDs)
        XCTAssertEqual(compositeComponent.optionIDs, [413, 412])
        XCTAssertEqual(compositeComponent.defaultOptionID, "413")
    }
}


/// Private Methods.
///
private extension ProductMapperTests {

    /// Returns the ProductMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapProduct(from filename: String) -> Product? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try! ProductMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the ProductMapper output upon receiving `product`
    ///
    func mapLoadProductResponse() throws -> [Product] {
        guard let product = mapProduct(from: "product") else {
            throw ProductMapperTestsError.unableToLoadFile
        }

        guard let productWithoutDataEnvelope = mapProduct(from: "product-without-data") else {
            throw ProductMapperTestsError.unableToLoadFile
        }

        return [product, productWithoutDataEnvelope]
    }

    /// Returns the ProductMapper output upon receiving `product-alternative-types`
    ///
    func mapLoadProductResponseWithAlternativeTypes() -> Product? {
        return mapProduct(from: "product-alternative-types")
    }

    /// Returns the ProductMapper output upon receiving `product` on sale, with empty sale price
    ///
    func mapLoadProductOnSaleWithEmptySalePriceResponse() -> Product? {
        return mapProduct(from: "product-on-sale-with-empty-sale-price")
    }

    /// Returns the ProductMapper output upon receiving `product` with malformed image `alt` and `variations`
    ///
    func mapLoadProductWithMalformedImageAltAndVariations() -> Product? {
        return mapProduct(from: "product-malformed-variations-and-image-alt")
    }

    /// Returns the ProductMapper output upon receiving `product-bundle`
    ///
    func mapLoadProductBundleResponse() -> Product? {
        return mapProduct(from: "product-bundle")
    }

    /// Returns the ProductMapper output upon receiving `product-composite`
    ///
    func mapLoadCompositeProductResponse() -> Product? {
        return mapProduct(from: "product-composite")
    }
}
