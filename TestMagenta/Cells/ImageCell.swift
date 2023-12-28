import UIKit

class ImageCell: UICollectionViewCell {
    static let reuseIdentifier = "ImageCell"

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        return imageView
    }()

    private lazy var likeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "heart"), for: .normal)
        button.tintColor = .red
        button.isUserInteractionEnabled = true
        button.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)
        return button
    }()

    var toggleFavorite: (() -> Void)?
    var imageViewModel: ImageViewModel?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ImageCell {
    func setupUI() {
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        addSubview(likeButton)
        likeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            likeButton.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            likeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            likeButton.widthAnchor.constraint(equalToConstant: 24),
            likeButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
}

private extension ImageCell {
    @objc func favoriteButtonTapped() {
        toggleFavorite?()
        if let image = imageView.image, let imageModel = imageViewModel?.getRandomImage(at: self.tag) {
            // Используем imageModel для получения id и обновления кэша
            let imageId = imageModel.id
            imageViewModel?.cacheRandomImage(with: imageId, uiImage: image)

        }
    }
}

//private extension ImageCell {
//    @objc func favoriteButtonTapped() {
//        toggleFavorite?()
//        if let image = imageView.image,
//           let imageModel = imageViewModel?.getRandomImage(at: self.tag) {
//            imageViewModel?.cacheRandomImage(imageModel, uiImage: image)
//        }
//    }
//}

extension ImageCell {
    func configureForRandom(with image: ImageModel, isFavoriteTab: Bool, viewModel: ImageViewModel) {
        imageView.image = nil

        viewModel.loadImage(for: image) { [weak self] loadedImage in
            guard let self = self, let loadedImage = loadedImage else { return }
            self.imageView.image = loadedImage

            let imageName = image.isFavorite ? UIImage(systemName: "heart.fill") : UIImage(systemName: "heart")
            let image = imageName
            self.likeButton.setImage(image, for: .normal)
        }
    }

    func configureForFavorites(with image: ImageModel, cachedImage: UIImage? = nil, viewModel: ImageViewModel) {
        if let cachedImage = cachedImage {
            imageView.image = cachedImage
        } else {
            viewModel.loadImage(for: image) { [weak self] loadedImage in
                guard let self = self, let loadedImage = loadedImage else { return }
                self.imageView.image = loadedImage
            }
        }
        let image = UIImage(systemName: "heart.fill")
        self.likeButton.setImage(image, for: .normal)
    }

    func updateFavoriteButton(isFavorite: Bool) {
        let imageName = isFavorite ? "heart.fill" : "heart"
        likeButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
}
