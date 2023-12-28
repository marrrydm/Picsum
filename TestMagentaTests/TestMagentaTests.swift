import XCTest
import CoreData
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

class ImageViewModelTests2: XCTestCase {
    var imageViewModel: ImageViewModel!

    override func setUp() {
        super.setUp()
        imageViewModel = ImageViewModel()
    }

    override func tearDown() {
        imageViewModel = nil
        super.tearDown()
    }

    // Тест для метода addToFavorites
    func testAddToFavorites() {
        // Мок изображение для теста
        let fakeImage = ImageModel(
            id: "7",
            author: "Fake Author",
            width: 100,
            height: 100,
            url: "http://example.com/image.jpg",
            download_url: "http://example.com/image.jpg",
            isFavorite: false,
            image: nil
        )

        class MockImageService: ImageServiceProtocol {
            var loadImageCompletion: ((URL, @escaping (UIImage?) -> Void) -> Void)?
            // заглушка
            func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
                loadImageCompletion?(url, completion)
            }
        }

        // Создаем экземпляр ImageViewModel с MockImageService
        let imageViewModel = ImageViewModel()
        let mockImageService = MockImageService()
        imageViewModel.imageService = mockImageService

        // заглушка для метода loadImage
        mockImageService.loadImageCompletion = { _, completion in
            // заглушка для успешной загрузки изображения
            completion(UIImage(systemName: "heart.fill"))
        }

        // Запускаем метод addToFavorites и проверяем, что изображение добавляется в избранное
        let expectation = XCTestExpectation(description: "Add to favorites")

        imageViewModel.addToFavorites(fakeImage) { result in
            switch result {
            case .success:
                XCTAssertTrue(imageViewModel.isFavorite(image: fakeImage))
                XCTAssertEqual(imageViewModel.numberOfFavoriteImages, 1)
                print("Success: Image added to favorites")
            case .failure(let error):
                XCTFail("Failed to add to favorites with error: \(error)")
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    // Тест для метода removeFromFavorites
    func testRemoveFromFavorites() {
        // мок изображение
        let fakeFavoriteImage = FavoriteImageEntity(context: CoreDataStack.shared.context!)
        fakeFavoriteImage.id = "2"
        imageViewModel.favoriteImages = [fakeFavoriteImage]

        // проверка обновления избранные изображения
        let expectation = XCTestExpectation(description: "Remove from favorites")
        imageViewModel.removeFromFavorites(at: 0)
        XCTAssertEqual(imageViewModel.numberOfFavoriteImages, 0)
        expectation.fulfill()

        wait(for: [expectation], timeout: 5.0)
    }

    // Тест для метода loadFavoritesFromCache
    func testLoadFavoritesFromCache() {
        // мок данные
        let fakeFavorite1 = FavoriteImageEntity(context: CoreDataStack.shared.context!)
        fakeFavorite1.id = "3"
        let fakeFavorite2 = FavoriteImageEntity(context: CoreDataStack.shared.context!)
        fakeFavorite2.id = "4"
        imageViewModel.favoriteImages = [fakeFavorite1, fakeFavorite2]

        // проверка, что favoriteImages обновляется
        let expectation = XCTestExpectation(description: "Load favorites from cache")
        imageViewModel.loadFavoritesFromCache {
            XCTAssertEqual(self.imageViewModel.numberOfFavoriteImages, 2)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    // Тест для метода getCachedRandomImage
    func testGetCachedRandomImage() {
        // Создаем фейковое случайное изображение и кешируем его
        let imageId = "6"
        let fakeRandomImage = UIImage(named: "random")!
        imageViewModel.cacheRandomImage(with: imageId, uiImage: fakeRandomImage)

        // Запускаем метод getCachedRandomImage и проверяем, что изображение успешно загружается из кеша
        let cachedImage = imageViewModel.getCachedRandomImage(at: ImageModel(id: imageId, author: "Fake Author", width: 100, height: 100, url: "fake_url", download_url: "fake_download_url", isFavorite: false, image: nil))
        XCTAssertNotNil(cachedImage)
    }
}

class CoreDataStackTests: XCTestCase {

    var coreDataStack: CoreDataStack!

    override func setUpWithError() throws {
        try super.setUpWithError()
        coreDataStack = CoreDataStack.shared
    }

    override func tearDownWithError() throws {
        coreDataStack = nil
        try super.tearDownWithError()
    }

    func testPersistentContainerCreation() throws {
        XCTAssertNotNil(coreDataStack.persistentContainer, "Persistent container should not be nil")

        // Проверяем, что у нас есть хотя бы один persistentStoreCoordinator
        XCTAssertFalse(coreDataStack.persistentContainer.persistentStoreDescriptions.isEmpty, "Persistent container should have at least one persistent store")
    }

    func testManagedObjectContextCreation() throws {
        XCTAssertNotNil(coreDataStack.context, "Managed context should not be nil")
    }

    func testSaveContext() throws {
        let context = coreDataStack.context!
        let entity = NSEntityDescription.entity(forEntityName: "FavoriteImageEntity", in: context)!
        let favoriteEntity = NSManagedObject(entity: entity, insertInto: context)

        favoriteEntity.setValue("TestID", forKey: "id")

        // Сохраним
        coreDataStack.saveContext()

        // Получим объект, чтобы убедиться, что он сохранен.
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FavoriteImageEntity")
        fetchRequest.predicate = NSPredicate(format: "id == %@", "TestID")

        let fetchedObjects = try context.fetch(fetchRequest) as! [NSManagedObject]
        XCTAssertEqual(fetchedObjects.count, 1, "There should be one object in the context with ID 'TestID'")
    }
}

class ImageCellTests: XCTestCase {

    var cell: ImageCell!

    override func setUpWithError() throws {
        try super.setUpWithError()
        cell = ImageCell()
    }

    override func tearDownWithError() throws {
        cell = nil
        try super.tearDownWithError()
    }

    func testCellHasImageView() {
        XCTAssertNotNil(cell.getImageView())
    }

    func testCellHasLikeButton() {
        XCTAssertNotNil(cell.getLikeButton())
    }

    func testConfigureForRandom() {
        let image = ImageModel(id: "1", author: "Author", width: 100, height: 100, url: "http://example.com/image.jpg", download_url: "http://example.com/image.jpg", isFavorite: false, image: nil)

        // Mock ViewModel
        let viewModel = MockImageViewModel()
        viewModel.loadImageCompletion = { _, completion in
            completion(UIImage())
        }
        cell.imageViewModel = viewModel
        cell.tag = 0

        // Action
        cell.configureForRandom(with: image, isFavoriteTab: false, viewModel: viewModel)

        // Assertion
        XCTAssertNotNil(cell.getImageView().image)
        XCTAssertEqual(cell.getLikeButton().image(for: .normal), UIImage(systemName: "heart"))
    }

    func testConfigureForFavoritesWithCachedImage() {
        let image = ImageModel(id: "1", author: "Author", width: 100, height: 100, url: "http://example.com/image.jpg", download_url: "http://example.com/image.jpg", isFavorite: true, image: nil)

        // Mock ViewModel
        let viewModel = MockImageViewModel()
        viewModel.loadImageCompletion = { _, completion in
            completion(UIImage())
        }
        cell.imageViewModel = viewModel
        cell.tag = 0

        // Action
        cell.configureForFavorites(with: image, cachedImage: UIImage(), viewModel: viewModel)

        // Assertion
        XCTAssertNotNil(cell.getImageView().image)
        XCTAssertEqual(cell.getLikeButton().image(for: .normal), UIImage(systemName: "heart.fill"))
    }

    func testUpdateFavoriteButton() {
        // Action
        cell.updateFavoriteButton(isFavorite: true)

        // Assertion
        XCTAssertEqual(cell.getLikeButton().image(for: .normal), UIImage(systemName: "heart.fill"))
    }
}

class MockImageViewModel: ImageViewModel {

    var loadImageCompletion: ((ImageModel, @escaping (UIImage?) -> Void) -> Void)?

    override func loadImage(for image: ImageModel, completion: @escaping (UIImage?) -> Void) {
        loadImageCompletion?(image, completion)
    }
}
