//	
// Copyright © 2021 Essential Developer. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {
	
	convenience init() {
		self.init(nibName: nil, bundle: nil)
		self.setupViewController()
	}

	private func setupViewController() {
		viewControllers = [
			makeNav(for: makeFriendsList(), title: "Friends", icon: "person.2.fill"),
			makeTransfersList(),
			makeNav(for: makeCardsList(), title: "Cards", icon: "creditcard.fill")
		]
	}
	
	private func makeNav(for vc: UIViewController, title: String, icon: String) -> UIViewController {
		vc.navigationItem.largeTitleDisplayMode = .always
		
		let nav = UINavigationController(rootViewController: vc)
		nav.tabBarItem.image = UIImage(
			systemName: icon,
			withConfiguration: UIImage.SymbolConfiguration(scale: .large)
		)
		nav.tabBarItem.title = title
		nav.navigationBar.prefersLargeTitles = true
		return nav
	}
	
	private func makeTransfersList() -> UIViewController {
		let sent = makeSentTransfersList()
		sent.navigationItem.title = "Sent"
		sent.navigationItem.largeTitleDisplayMode = .always
		
		let received = makeReceivedTransfersList()
		received.navigationItem.title = "Received"
		received.navigationItem.largeTitleDisplayMode = .always
		
		let vc = SegmentNavigationViewController(first: sent, second: received)
		vc.tabBarItem.image = UIImage(
			systemName: "arrow.left.arrow.right",
			withConfiguration: UIImage.SymbolConfiguration(scale: .large)
		)
		vc.title = "Transfers"
		vc.navigationBar.prefersLargeTitles = true
		return vc
	}
	
	private func makeFriendsList() -> ListViewController {
		let vc = ListViewController()
		vc.fromFriendsScreen = true
        vc.service = FriendsAPIItemsServiceAdapter(api: FriendsAPI.shared, cache: (UIApplication.shared.connectedScenes.first?.delegate as! SceneDelegate).cache, isPremium: User.shared?.isPremium == true, select: { [weak vc] item in
            vc?.select(friend: item)
        })
        
        // injecting this service into the ListVC. thus ListVC doesn't need to know the concrete type of that service
		return vc
	}
	
	private func makeSentTransfersList() -> ListViewController {
		let vc = ListViewController()
		vc.fromSentTransfersScreen = true
		return vc
	}
	
	private func makeReceivedTransfersList() -> ListViewController {
		let vc = ListViewController()
		vc.fromReceivedTransfersScreen = true
		return vc
	}
	
	private func makeCardsList() -> ListViewController {
		let vc = ListViewController()
		vc.fromCardsScreen = true
		return vc
	}
	
}


// moved it to the composition here
// the creation of the service needs to go to where you create the viewController

// if we make it as a struct. we get initializeer for free
struct FriendsAPIItemsServiceAdapter: ItemService {
//class FriendsAPIItemsServiceAdapter: ItemService {
    
    let api: FriendsAPI // API dependency
    let cache: FriendsCache
    let isPremium: Bool
    
    // need a dependency for selecting the friend
    // we don't want adapter here depanding perform this logic so we can just define it as a closure
    let select: (Friend) -> Void // could push vc, call api requests, could change the state of the database.
    // that's up to whoever inject thid dependency here to decide
    
    // we can also define all the dependencies explicitly instead of accessing globally
    
    func loadItems(completion: @escaping (Result<[ItemViewModel], Error>) -> Void) {
        // decouple the vc from a specific API
//        FriendsAPI.shared.loadFriends { /*[weak self]*/ result in // doesn't neetd to be 'weak'. cause structs are not reference types
        
        api.loadFriends { result in
            DispatchQueue.mainAsyncIfNeeded {
//                self?.handleAPIResult(result.map { items in
                completion(result.map { items in
                    
//                    if User.shared?.isPremium == true {
                    if isPremium { // we don't have to access User globally
//                        (UIApplication.shared.connectedScenes.first?.delegate as! SceneDelegate).cache.save(items) // we don't need to access like this anymore
                        cache.save(items)
                        // it's up to however create the adapter to pass a cache as a dependency it's explicitly in the interface. you can only create an adapter if you give it a cache thus the adapter doesn't need to  access this cache globally which leads to the issue we described
                    }
                    
                    return items.map { item in
                        ItemViewModel(friend: item, selection: {
                            // in this context, we know the concrete type. doesn't need to convert it to Any
//                            self?.select(friend: item)
                            // we use dependency injection here
                            select(item)
                        })
                    }
                })
            }
        }
    }
    
    
}
