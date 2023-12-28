import UIKit

struct ImageModel: Codable, Equatable {
    let id: String
    let author: String
    let width: Int
    let height: Int
    let url: String
    let download_url: String
    var isFavorite: Bool = false
    var image: UIImage?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case author
        case width
        case height
        case url
        case download_url
    }
    
    static func == (lhs: ImageModel, rhs: ImageModel) -> Bool {
        return lhs.id == rhs.id
    }
}

enum Tab {
    case random
    case favorites
}
