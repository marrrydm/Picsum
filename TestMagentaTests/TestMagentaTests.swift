import XCTest
@testable import TestMagenta

class ImageServiceTests: XCTestCase {
    var imageService: ImageService!

    override func setUpWithError() throws {
        imageService = ImageService.shared
    }

    override func tearDownWithError() throws {
        imageService = nil
    }

    func testGetRandomImages() {
        let expectation = XCTestExpectation(description: "Fetch random images")

        imageService.getRandomImages { images in
            XCTAssertNotNil(images, "Failed to fetch random images")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func testLoadImage_FailedRequest_ReturnsNil() {
        // Arrange
        let imageService = ImageService.shared
        let invalidURL = URL(string: "https://invalid-url")!

        // Создаем XCTestExpectation, чтобы отслеживать выполнение асинхронной операции
        let expectation = XCTestExpectation(description: "Load image expectation")

        // Act
        imageService.loadImage(from: invalidURL) { (image) in
            // Assert
            XCTAssertNil(image, "Image should be nil for a failed request")
            expectation.fulfill()
        }

        // Ждем выполнения ожидания с таймаутом в 10 секунд
        wait(for: [expectation], timeout: 10.0)
    }
}

class ImageViewModelTests: XCTestCase {
    var viewModel: ImageViewModel!

    override func setUp() {
        super.setUp()
        viewModel = ImageViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func createTestImage(id: String = "1", author: String = "Test Author", width: Int = 100, height: Int = 100, url: String = "http://example.com/image.jpg", downloadUrl: String = "http://example.com/download.jpg") -> ImageModel {
        return ImageModel(id: id, author: author, width: width, height: height, url: url, download_url: downloadUrl)
    }

    func testToggleFavorite() {
        let testImage = ImageModel(
            id: "123",
            author: "test_author",
            width: 100,
            height: 100,
            url: "test_url",
            download_url: "test_download_url"
        )
        viewModel.randomImages = [testImage]

        // Переключаем избранное и проверяем, что тестовое изображение находится в списке избранных
        viewModel.toggleFavorite(at: 0)
        XCTAssertTrue(viewModel.isFavorite(image: testImage))

        // Повторно переключаем избранное и проверяем, что тестовое изображение удалено из списка избранных
        viewModel.toggleFavorite(at: 0)
        XCTAssertFalse(viewModel.isFavorite(image: testImage))
    }

    // Тест добавления изображения в избранное
    func testAddToFavorites_ImageNotInFavorites_ImageAdded() {
        let image = createTestImage()

        viewModel.addToFavorites(image, completion: {_ in

        })

        XCTAssertTrue(viewModel.isFavorite(image: image))
        XCTAssertEqual(viewModel.numberOfFavoriteImages, 1)
    }

    // Тест добавления изображения в избранное, когда оно уже там
    func testAddToFavorites_ImageAlreadyInFavorites_NoChange() {
        let image = createTestImage()

        viewModel.addToFavorites(image, completion: {_ in

        })
        viewModel.addToFavorites(image, completion: {_ in

        })

        XCTAssertTrue(viewModel.isFavorite(image: image))
        XCTAssertEqual(viewModel.numberOfFavoriteImages, 1)
    }

    // Тест удаления изображения из избранного
    func testRemoveFromFavorites_ValidIndex_ImageRemoved() {
        let image = createTestImage()
        viewModel.addToFavorites(image, completion: {_ in

        })

        viewModel.removeFromFavorites(at: 0)

        XCTAssertFalse(viewModel.isFavorite(image: image))
        XCTAssertEqual(viewModel.numberOfFavoriteImages, 0)
    }

    // Тест удаления изображения из избранного с недопустимым индексом
    func testRemoveFromFavorites_InvalidIndex_NoChange() {
        let image = createTestImage()
        viewModel.addToFavorites(image, completion: {_ in

        })

        viewModel.removeFromFavorites(at: 1)

        XCTAssertTrue(viewModel.isFavorite(image: image))
        XCTAssertEqual(viewModel.numberOfFavoriteImages, 1)
    }

    // Тест проверки, что изображение в избранном
    func testIsFavorite_ImageInFavorites_ReturnsTrue() {
        let image = createTestImage()
        viewModel.addToFavorites(image, completion: {_ in

        })

        let isFavorite = viewModel.isFavorite(image: image)

        XCTAssertTrue(isFavorite)
    }

    // Тест проверки, что изображение не в избранном
    func testIsFavorite_ImageNotInFavorites_ReturnsFalse() {
        let image = createTestImage()

        let isFavorite = viewModel.isFavorite(image: image)

        XCTAssertFalse(isFavorite)
    }

    // Тест загрузки дополнительных случайных изображений (порог не достигнут)
    func testLoadMoreRandomImagesIfNeeded_ThresholdNotReached_NoChange() {
        let initialCount = viewModel.numberOfRandomImages

        viewModel.loadMoreRandomImagesIfNeeded(at: initialCount - 1) {
        }

        XCTAssertEqual(viewModel.numberOfRandomImages, initialCount)
    }

    // Тест кеширования случайного изображения
    func testCacheRandomImage_ValidInput_ImageCached() {
        // Arrange
        let image = createTestImage()
        let uiImage = UIImage(systemName: "heart.fill")! // Просто для примера

        // Act
        viewModel.cacheRandomImage(image, uiImage: uiImage)

        // Assert
        XCTAssertNotNil(viewModel.getCachedRandomImage(at: image))
    }

    // Тест получения кешированного случайного изображения
    func testGetCachedRandomImage_ImageCached_ReturnsImage() {
        // Arrange
        let image = createTestImage()
        let uiImage = UIImage(systemName: "heart.fill")! // Просто для примера
        viewModel.cacheRandomImage(image, uiImage: uiImage)

        // Act
        let cachedImage = viewModel.getCachedRandomImage(at: image)
        
        // Assert
        XCTAssertNotNil(cachedImage)
    }
}
