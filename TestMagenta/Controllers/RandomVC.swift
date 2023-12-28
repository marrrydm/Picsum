import UIKit

class RandomViewController: UIViewController {
    fileprivate let collectionView: UICollectionView = {
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
        viewModel.currentTab = .random
        setupCollectionView()
        fetchRandomImages()
        viewModel.loadFavorites()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.isFavoritesTab = tabBarController?.selectedIndex == 1
    }
}

private extension RandomViewController {
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

private extension RandomViewController {
    func fetchRandomImages() {
        viewModel.loadMoreRandomImagesIfNeeded(at: viewModel.numberOfRandomImages - 1, completion: {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        })
    }
}

// MARK: - UICollectionViewDataSource
extension RandomViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfImages
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCell.reuseIdentifier, for: indexPath) as? ImageCell else {
            return UICollectionViewCell()
        }

        if let image = viewModel.getRandomImage(at: indexPath.item) {
            cell.configureForRandom(with: image, isFavoriteTab: false, viewModel: viewModel)

            cell.toggleFavorite = { [weak self] in
                self?.viewModel.toggleFavorite(at: indexPath.item)
                cell.updateFavoriteButton(isFavorite: self?.viewModel.isFavorite(image: image) ?? .random())
                self?.viewModel.loadFavorites()
                self?.collectionView.reloadItems(at: [indexPath])
            }
        }

        if indexPath.item == viewModel.numberOfRandomImages - 1 {
            fetchRandomImages()
        }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension RandomViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (collectionView.frame.width - 16) / 2, height: 200)
    }
}
