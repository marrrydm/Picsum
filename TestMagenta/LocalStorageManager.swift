import Foundation

class LocalStorageManager {
    static let favoriteImagesKey = "favoriteImages"

    static func saveFavoriteImage(_ image: ImageModel) {
        var favoriteImages = getFavoriteImages()
        favoriteImages.append(image)
        saveImages(favoriteImages)
    }

    static func removeFavoriteImage(_ image: ImageModel) {
        var favoriteImages = getFavoriteImages()
        if let index = favoriteImages.firstIndex(where: { $0.id == image.id }) {
            favoriteImages.remove(at: index)
            saveImages(favoriteImages)
        }
    }

    static func getFavoriteImages() -> [ImageModel] {
        guard let data = UserDefaults.standard.data(forKey: favoriteImagesKey) else {
            return []
        }

        do {
            let decoder = JSONDecoder()
            let favoriteImages = try decoder.decode([ImageModel].self, from: data)
            return favoriteImages
        } catch {
            print("Error decoding favorite images data: \(error)")
            return []
        }
    }

    private static func saveImages(_ images: [ImageModel]) {
        do {
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(images)
            UserDefaults.standard.set(encodedData, forKey: favoriteImagesKey)
        } catch {
            print("Error encoding images data: \(error)")
        }
    }
}
