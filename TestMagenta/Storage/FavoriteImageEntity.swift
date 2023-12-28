import UIKit
import CoreData

extension FavoriteImageEntity {
    class func create(in context: NSManagedObjectContext, image: ImageModel, uiImage: UIImage) throws -> FavoriteImageEntity {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "FavoriteImageEntity", into: context) as! FavoriteImageEntity

        entity.id = image.id
        entity.author = image.author
        entity.width = Int32(image.width)
        entity.height = Int32(image.height)
        entity.url = image.url
        entity.download_url = image.download_url
        entity.isFavorite = image.isFavorite
        if let imageData = uiImage.jpegData(compressionQuality: 1.0) {
            entity.image = imageData
        }

        return entity
    }
}
