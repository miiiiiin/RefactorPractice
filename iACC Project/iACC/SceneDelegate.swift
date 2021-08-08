//
// Copyright © 2021 Essential Developer. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	var window: UIWindow?
	var cache = FriendsCache()
	
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		guard let windowScene = scene as? UIWindowScene else { return }
		
		window = UIWindow(windowScene: windowScene)
		window?.rootViewController = makeRootViewController()
		window?.makeKeyAndVisible()
	}
	
	func makeRootViewController() -> MainTabBarController {
//		MainTabBarController()
        MainTabBarController(friendsCache: (UIApplication.shared.connectedScenes.first?.delegate as! SceneDelegate).cache)
        
        // instead of accessing the dependency directly in the sceneDelegate. we can pass dependencies explicitly/directly 
	}
}
