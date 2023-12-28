import UIKit

protocol ImageViewModelDelegate: AnyObject {
    func didRemoveItem(at index: Int)
}

protocol ImageViewModelDelegateAdd: AnyObject {
    func didToggleFavorite(at index: Int, with image: UIImage?)
}

protocol ImageServiceProtocol {
    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void)
}
