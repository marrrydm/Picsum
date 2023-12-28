import CoreData
import UIKit

class ImageViewModel {
    var randomImages: [ImageModel] = []
    var favoriteImages: [FavoriteImageEntity] = []
    var currentTab: Tab = .random
    var isFavoritesTab: Bool = false
    var imageService: ImageServiceProtocol = ImageService.shared

    weak var delegate: ImageViewModelDelegate?
    weak var delegateAdd: ImageViewModelDelegateAdd?
    
    func loadImage(for image: ImageModel, completion: @escaping (UIImage?) -> Void) {
        guard let urlString = image.download_url.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed),
              let imageUrl = URL(string: urlString) else {
            completion(nil)
            return
        }

        ImageService.shared.loadImage(from: imageUrl) { loadedImage in
            DispatchQueue.main.async {
                if let loadedImage = loadedImage {
                    completion(loadedImage)
                } else {
                    let error = NSError(domain: "YourDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to load image"])
                    print("Error loading image: \(error)")
                    completion(nil)
                }
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
        
        let favoriteEntity = favoriteImages[index]
        
        let author = favoriteEntity.author ?? ""
        let url = favoriteEntity.url ?? ""
        let downloadUrl = favoriteEntity.download_url ?? ""
        
        let imageModel = ImageModel(
            id: favoriteEntity.id ?? "",
            author: author,
            width: Int(favoriteEntity.width),
            height: Int(favoriteEntity.height),
            url: url,
            download_url: downloadUrl,
            isFavorite: favoriteEntity.isFavorite,
            image: UIImage(data: favoriteEntity.image ?? Data())
        )
        
        return imageModel
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
            
            loadImage(for: image) { [weak self] loadedImage in
                guard let self = self, let loadedImage = loadedImage else {
                    return
                }
                
                self.delegateAdd?.didToggleFavorite(at: index, with: loadedImage)
                self.addToFavorites(image, completion: {_ in })
            }
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

        guard let context = CoreDataStack.shared.context else {
            print("Error: ManagedObjectContext is nil")
            completion(.failure(NSError(domain: "YourDomain", code: 0, userInfo: nil)))
            return
        }

        imageService.loadImage(from: URL(string: image.download_url)!) { [weak self] loadedImage in
            guard let self = self, let loadedImage = loadedImage else {
                completion(.failure(NSError(domain: "YourDomain", code: 0, userInfo: nil)))
                return
            }

            do {
                let favoriteEntity = try FavoriteImageEntity.create(in: context, image: image, uiImage: loadedImage)

                try context.save()

                self.favoriteImages.append(favoriteEntity)
                completion(.success(()))
            } catch {
                print("Error creating or saving FavoriteImageEntity: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    func isFavoriteImageInRandom(at index: Int) -> Bool {
        guard let randomImage = getRandomImage(at: index) else { return false }
        return isFavorite(image: randomImage)
    }
    
    func removeFromFavorites(at index: Int) {
        guard index >= 0, index < favoriteImages.count else { return }
        
        let removedImage = favoriteImages.remove(at: index)
        CoreDataStack.shared.context?.delete(removedImage)
        CoreDataStack.shared.saveContext()
        
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
            guard let context = CoreDataStack.shared.context else {
                print("Error: ManagedObjectContext is nil")
                DispatchQueue.main.async {
                    completion()
                }
                return
            }
            
            let fetchRequest = NSFetchRequest<FavoriteImageEntity>(entityName: "FavoriteImageEntity")
            
            do {
                let cachedImages = try context.fetch(fetchRequest)
                let favoriteEntities = cachedImages.map { favoriteEntity in
                    favoriteEntity
                }
                
                DispatchQueue.main.async {
                    // Обновляем массив favoriteImages
                    self?.favoriteImages = favoriteEntities
                    completion()
                }
            } catch {
                print("Error fetching cached images from Core Data: \(error)")
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }
    
    func cacheRandomImage(with imageId: String, uiImage: UIImage) {
        let userDefaultsKey = "RandomImage_\(imageId)"
        
        if let imageData = uiImage.jpegData(compressionQuality: 1.0) {
            UserDefaults.standard.set(imageData, forKey: userDefaultsKey)
            UserDefaults.standard.set(imageId, forKey: "RandomImageId_\(imageId)")
        }
    }
    
    func loadFavorites(completion: @escaping () -> Void) {
        guard let context = CoreDataStack.shared.context else {
            print("Error: ManagedObjectContext is nil")
            completion()
            return
        }
        
        let fetchRequest = NSFetchRequest<FavoriteImageEntity>(entityName: "FavoriteImageEntity")
        
        do {
            let favoriteImages = try context.fetch(fetchRequest)
            self.favoriteImages = favoriteImages
            completion()
        } catch {
            print("Error fetching favorite images from Core Data: \(error)")
            completion()
        }
    }
}

extension ImageViewModel {
    func getCachedRandomImage(at image: ImageModel) -> UIImage? {
        guard let context = CoreDataStack.shared.context else {
            print("Error: ManagedObjectContext is nil")
            return nil
        }
        
        let fetchRequest: NSFetchRequest<FavoriteImageEntity> = FavoriteImageEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", image.id)
        
        do {
            let result = try context.fetch(fetchRequest)
            if let favoriteEntity = result.first {
                if let imageData = favoriteEntity.image {
                    return UIImage(data: imageData)
                }
            }
        } catch {
            print("Error fetching cached image from Core Data: \(error)")
        }
        
        return nil
    }
}

