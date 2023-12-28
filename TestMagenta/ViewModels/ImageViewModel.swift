import UIKit

protocol ImageViewModelDelegate: AnyObject {
    func didRemoveItem(at index: Int)
}

class ImageViewModel {
    var randomImages: [ImageModel] = []
    var favoriteImages: [ImageModel] = []
    var currentTab: Tab = .random
    var isFavoritesTab: Bool = false
    var userDefaults: UserDefaults = UserDefaults.standard

    weak var delegate: ImageViewModelDelegate?
    
    func loadImage(for image: ImageModel, completion: @escaping (UIImage?) -> Void) {
        guard let imageUrl = URL(string: image.download_url) else {
            completion(nil)
            return
        }
        
        ImageService.shared.loadImage(from: imageUrl) { loadedImage in
            DispatchQueue.main.async {
                completion(loadedImage)
            }
        }
    }
}

extension ImageViewModel {
    func getRandomImage(at index: Int) -> ImageModel? {
        guard index >= 0, index < randomImages.count else {
            return nil
        }
        return randomImages[index]
    }

    func getFavoriteImage(at index: Int) -> ImageModel? {
        guard index >= 0, index < favoriteImages.count else {
            return nil
        }
        return favoriteImages[index]
    }
}

extension ImageViewModel {
    var numberOfRandomImages: Int {
        return randomImages.count
    }

    var numberOfFavoriteImages: Int {
        return favoriteImages.count
    }

    var numberOfImages: Int {
        switch currentTab {
        case .random:
            return randomImages.count
        case .favorites:
            return favoriteImages.count
        }
    }
}

extension ImageViewModel {
    func removeFromRandom(at index: Int) {
        guard index >= 0, index < randomImages.count else {
            return
        }
        randomImages.remove(at: index)
    }

    func toggleFavorite(at index: Int) {
        guard let image = getRandomImage(at: index) else {
            return
        }

        if favoriteImages.contains(where: { $0.id == image.id }) {
            print("Removing from favorites at index: \(index)")
            removeFromFavorites(at: index)
        } else {
            print("Adding to favorites at index: \(index)")
            addToFavorites(image, completion: {_ in 
                
            })
        }
    }

    func isFavorite(image: ImageModel) -> Bool {
        return favoriteImages.contains { $0.id == image.id }
    }

    func addToFavorites(_ image: ImageModel, completion: @escaping (Result<Void, Error>) -> Void) {
        guard !isFavorite(image: image) else {
            completion(.success(())) // Image is already in favorites
            return
        }

        favoriteImages.append(image)
        saveFavorites()

        if let imageUrl = URL(string: image.download_url) {
            ImageService.shared.loadImage(from: imageUrl) { [weak self] loadedImage in
                guard let self = self, let loadedImage = loadedImage else {
                    completion(.failure(NSError(domain: "YourDomain", code: 0, userInfo: nil)))
                    return
                }

                self.cacheRandomImage(image, uiImage: loadedImage)
                completion(.success(()))
            }
        } else {
            completion(.failure(NSError(domain: "YourDomain", code: 0, userInfo: nil)))
        }
    }

    func removeFromFavorites(at index: Int) {
        guard index >= 0, index < favoriteImages.count else {
            return
        }

        let removedImage = favoriteImages.remove(at: index)
        saveFavorites()

        let userDefaultsKey = "RandomImage_\(removedImage.id)"
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)

        delegate?.didRemoveItem(at: index)
    }
}

extension ImageViewModel {
    func loadMoreRandomImagesIfNeeded(at index: Int, completion: @escaping () -> Void) {
        let threshold = 10
        let remainingCount = numberOfRandomImages - index
        if remainingCount <= threshold {
            ImageService.shared.getRandomImages { [weak self] newImages in
                guard let newImages = newImages else {
                    completion()
                    return
                }

                self?.randomImages.append(contentsOf: newImages)
                completion()
            }
        }
    }

    func loadFavoritesFromCache(completion: @escaping () -> Void) {
        guard currentTab == .favorites else {
            completion()
            return
        }

        DispatchQueue.global().async { [weak self] in
            var cachedImages: [ImageModel] = []

            for favoriteImage in self?.favoriteImages ?? [] {
                if let cachedImage = self?.getCachedRandomImage(at: favoriteImage) {
                    var updatedFavoriteImage = favoriteImage
                    updatedFavoriteImage.image = cachedImage
                    cachedImages.append(updatedFavoriteImage)
                }
            }

            self?.favoriteImages = cachedImages

            DispatchQueue.main.async {
                completion()
            }
        }
    }
}

extension ImageViewModel {
    private func saveFavorites() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(favoriteImages) {
            UserDefaults.standard.set(encoded, forKey: "favorites")
        }
    }

    func loadFavorites() {
        if let favoritesData = UserDefaults.standard.data(forKey: "favorites") {
            let decoder = JSONDecoder()
            if let favorites = try? decoder.decode([ImageModel].self, from: favoritesData) {
                favoriteImages = favorites
            }
        }
    }

    func cacheRandomImage(_ image: ImageModel, uiImage: UIImage) {
        let imageId = image.id
        let userDefaultsKey = "RandomImage_\(imageId)"

        if let imageData = uiImage.jpegData(compressionQuality: 1.0) {
            UserDefaults.standard.set(imageData, forKey: userDefaultsKey)
            UserDefaults.standard.set(imageId, forKey: "RandomImageId_\(imageId)")
        }
    }

    func getCachedRandomImage(at image: ImageModel) -> UIImage? {
        let userDefaultsKey = "RandomImage_\(image.id)"

        if let savedImageData = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedImage = UIImage(data: savedImageData) {
            return savedImage
        }

        return nil
    }
}
