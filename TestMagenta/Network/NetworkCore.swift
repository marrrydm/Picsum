import UIKit

class ImageService: ImageServiceProtocol {
    static let shared = ImageService()
    private let baseURL = "https://picsum.photos/v2/list?page=1&limit=10"
    private var currentPage = 1

    func getRandomImages(completion: @escaping ([ImageModel]?) -> Void) {
        let urlString = baseURL + "\(currentPage)"

        guard let url = URL(string: urlString) else {
            print("Invalid URL:", urlString)
            completion(nil)
            return
        }

        let urlRequest = URLRequest(url: url)

        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                print("Error fetching images:", error.localizedDescription)
                completion(nil)
                return
            }

            guard let data = data else {
                print("No data received")
                completion(nil)
                return
            }

            do {
                _ = String(data: data, encoding: .utf8)
                let images = try JSONDecoder().decode([ImageModel].self, from: data)
                completion(images)
            } catch {
                print("Error decoding images:", error.localizedDescription)
                completion(nil)
            }
        }.resume()

        currentPage += 1
    }

    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    completion(image)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
}
