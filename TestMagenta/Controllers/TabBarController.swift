import UIKit

class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tabBar.backgroundColor = .white
        self.tabBar.tintColor = .gray
        self.tabBar.barTintColor = .white

        let appearance = UITabBarItem.appearance()
        let attributes = [
            NSAttributedString.Key.font:
                UIFont.systemFont(ofSize: 12, weight: .medium),
            NSAttributedString.Key.foregroundColor: UIColor.gray.withAlphaComponent(0.5)
        ]

        appearance.setTitleTextAttributes(attributes as [NSAttributedString.Key : Any], for: .normal)

        let attributesSelected = [
            NSAttributedString.Key.font:
                UIFont.systemFont(ofSize: 12, weight: .medium),
            NSAttributedString.Key.foregroundColor: UIColor.gray.withAlphaComponent(1)
        ]

        appearance.setTitleTextAttributes(attributesSelected as [NSAttributedString.Key : Any], for: .selected)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let randomController = RandomViewController()
        randomController.title = "title.random".localize()
        let randomImagesNav = UINavigationController(rootViewController: randomController)
        let randomItem = UITabBarItem(title: "title.random".localize(), image: UIImage(named: "random"), selectedImage: UIImage(named: "random"))
        randomController.tabBarItem = randomItem

        let favoriteController = FavoritesViewController()
        favoriteController.title = "title.favorite".localize()
        let favoriteImagesNav = UINavigationController(rootViewController: favoriteController)
        let favoriteItem = UITabBarItem(title: "title.favorite".localize(), image: UIImage(named: "favorite"), selectedImage: UIImage(named: "favorited"))
        favoriteController.tabBarItem = favoriteItem

        self.viewControllers = [randomImagesNav, favoriteImagesNav]
    }
}
