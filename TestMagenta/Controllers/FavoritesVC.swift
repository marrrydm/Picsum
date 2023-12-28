import UIKit

class FavoritesViewController: UIViewController {
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 6
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: ImageCell.reuseIdentifier)
        return collectionView
    }()

    private let viewModel = ImageViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        viewModel.delegate = self
        viewModel.currentTab = .favorites
        setupCollectionView()
        fetchFavoriteImages()
        viewModel.loadFavorites()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadFavorites()
        fetchFavoriteImages()
    }
}

private extension FavoritesViewController {
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

private extension FavoritesViewController {
    func fetchFavoriteImages() {
        viewModel.loadFavoritesFromCache {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
}

extension FavoritesViewController: ImageViewModelDelegate {
    func didRemoveItem(at index: Int) {
        collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource
extension FavoritesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let numberOfItems = viewModel.numberOfImages
        return max(numberOfItems, 0)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCell.reuseIdentifier, for: indexPath) as? ImageCell else {
            return UICollectionViewCell()
        }

        if let image = viewModel.getFavoriteImage(at: indexPath.item),
           let cachedImage = viewModel.getCachedRandomImage(at: image) {
            cell.configureForFavorites(with: image, cachedImage: cachedImage, viewModel: viewModel)
            cell.toggleFavorite = { [weak self] in
                self?.viewModel.removeFromFavorites(at: indexPath.item)
            }
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension FavoritesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (collectionView.frame.width - 16) / 2, height: 200)
    }
}
