//	
// Copyright © 2021 Essential Developer. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    private var friendsCache: FriendsCache! // explicit dependency
	
    convenience init(friendsCache: FriendsCache) { // we need to provide one when you're creating this
        // this is a dependency injection pattern called  constructor injection or initializer injection when you define statically in the initializer all the dependencies you need
		self.init(nibName: nil, bundle: nil)
        self.friendsCache = friendsCache
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
//		vc.fromFriendsScreen = true
//        vc.shouldRetry = true
//        vc.maxRetryCount = 2
        vc.title = "Friends"
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: vc, action: #selector(addFriend))
        
        let isPremium = User.shared?.isPremium == true
        
        let api = FriendsAPIItemsServiceAdapter(api: FriendsAPI.shared, cache: isPremium ?  friendsCache : NullFriendsCache(), select: { [weak vc] item in
            vc?.select(friend: item)
        }).retry(2)
        
        // injecting this service into the ListVC. thus ListVC doesn't need to know the concrete type of that service
        
        let cache = FriendsCacheItemsServiceAdapter(
            cache: friendsCache,
            select: { [weak vc] item in
            vc?.select(friend: item)
        })
        
//        vc.service = ItemServiceWithFallBack(primary: api, fallBack: cache)
        // it tries to load from the API. if it fails, it load from the cache
//        vc.service = api.fallBack(cache)
//        vc.service = isPremium ? api.fallBack(api).fallBack(cache) : api
//        vc.service = isPremium ? api.retry(2).fallBack(cache) : api.retry(2)
        vc.service = isPremium ? api.fallBack(cache) : api
		return vc
	}
	
	private func makeSentTransfersList() -> ListViewController {
		let vc = ListViewController()
//		vc.fromSentTransfersScreen = true
//        vc.shouldRetry = true
//        vc.maxRetryCount = 1
//        vc.longDateStyle = true

        vc.navigationItem.title = "Sent"
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .done, target: vc, action: #selector(sendMoney))
        
        
        vc.service = SentTransferAPIItemsServiceAdapter(api: TransfersAPI.shared, select: { [weak vc] item in
            vc?.select(transfer: item)
        }).retry(1)

		return vc
	}
	
	private func makeReceivedTransfersList() -> ListViewController {
		let vc = ListViewController()
//		vc.fromReceivedTransfersScreen = true
//        vc.shouldRetry = true
//        vc.maxRetryCount = 1
//        vc.longDateStyle = false 
        vc.navigationItem.title = "Received"
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Request", style: .done, target: vc, action: #selector(requestMoney))
        
        vc.service = ReceivedTransferAPIItemsServiceAdapter(api: TransfersAPI.shared, select: { [weak vc] item in
            vc?.select(transfer: item)
        }).retry(1)
		return vc
	}
	
	private func makeCardsList() -> ListViewController {
		let vc = ListViewController()
//		vc.fromCardsScreen = true
//        vc.shouldRetry = false
        vc.title = "Cards"
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: vc, action: #selector(addCard))
        
        // we can decide use a new instance or fake instance(we can  use polymorphism)
        vc.service = CardAPIItemsServiceAdapter(
            api: CardAPI.shared,
            select: { [weak vc] item in
            vc?.select(card: item)
        })
        
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
//    let isPremium: Bool
    
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
//                    if isPremium { // we don't have to access User globally
//                        (UIApplication.shared.connectedScenes.first?.delegate as! SceneDelegate).cache.save(items) // we don't need to access like this anymore
                        cache.save(items)
                        // it's up to however create the adapter to pass a cache as a dependency it's explicitly in the interface. you can only create an adapter if you give it a cache thus the adapter doesn't need to  access this cache globally which leads to the issue we described
//                    }
                    
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




struct CardAPIItemsServiceAdapter: ItemService {
    
    let api: CardAPI // API dependency
    let select: (Card) -> Void
    
    func loadItems(completion: @escaping (Result<[ItemViewModel], Error>) -> Void) {
        api.loadCards { result in
            DispatchQueue.mainAsyncIfNeeded {
                completion(result.map { items in
                    items.map { item in
                        ItemViewModel(card: item, selection: {
                            select(item)
                        })
                    }
                })
            }
        }
    }
}


struct SentTransferAPIItemsServiceAdapter: ItemService {
    
    let api: TransfersAPI // API dependency
//    let longDateStyle: Bool
//    let fromSentTransfersScreen: Bool
    let select: (Transfer) -> Void
    
    func loadItems(completion: @escaping (Result<[ItemViewModel], Error>) -> Void) {
        api.loadTransfers { result in
            DispatchQueue.mainAsyncIfNeeded {
                completion(result.map { items in
//                        var filteredItems = items
                    // filter the array of models
//                        if fromSentTransfersScreen {
//                            filteredItems = filteredItems.filter(\.isSender)
//                        } else {
//                            filteredItems = filteredItems.filter { !$0.isSender }
//                        }
                    
//                        return filteredItems
                    items
//                        .filter { fromSentTransfersScreen ? $0.isSender : !$0.isSender }
                        .filter { $0.isSender }
                        .map { item in
                        ItemViewModel(transfer: item,
                                      longDateStyle: true,
                                      selection: {
                            select(item)
                        })
                    }
                })
            }
        }
    }    
}



struct ReceivedTransferAPIItemsServiceAdapter: ItemService {
    
    let api: TransfersAPI // API dependency
//    let longDateStyle: Bool
//    let fromSentTransfersScreen: Bool
    let select: (Transfer) -> Void
    
    func loadItems(completion: @escaping (Result<[ItemViewModel], Error>) -> Void) {
        api.loadTransfers { result in
            DispatchQueue.mainAsyncIfNeeded {
                completion(result.map { items in
//                        var filteredItems = items
                    // filter the array of models
//                        if fromSentTransfersScreen {
//                            filteredItems = filteredItems.filter(\.isSender)
//                        } else {
//                            filteredItems = filteredItems.filter { !$0.isSender }
//                        }
                    
//                        return filteredItems
                    items
//                        .filter { fromSentTransfersScreen ? $0.isSender : !$0.isSender }
                        .filter { !$0.isSender }
                        .map { item in
                        ItemViewModel(transfer: item,
                                      longDateStyle: false ,
                                      selection: {
                            select(item)
                        })
                    }
                })
            }
        }
    }
}


struct FriendsCacheItemsServiceAdapter: ItemService {
    
    let cache: FriendsCache
    let select: (Friend) -> Void
    
    func loadItems(completion: @escaping (Result<[ItemViewModel], Error>) -> Void) {
        cache.loadFriends { result in
            DispatchQueue.mainAsyncIfNeeded {
                completion(result.map { items in
                    items.map { item in
                        ItemViewModel(friend: item, selection: {
                            select(item)
                        })
                    }
                })
            }
        }
    }
}

struct ItemServiceWithFallBack: ItemService {
    
    // two services that implement the same interface
    
    let primary: ItemService
    let fallBack: ItemService
    
    // this composite will compose two implementations of itemService that could be any implementation that could be an API
    
    func loadItems(completion: @escaping (Result<[ItemViewModel], Error>) -> Void) {
        primary.loadItems { result in
            switch result {
            case .success:
                completion(result)
                
            case .failure:
                fallBack.loadItems(completion: completion)
            }
        }
    }
}

extension ItemService {
    func fallBack(_ fallback: ItemService) -> ItemService {
        ItemServiceWithFallBack(primary: self, fallBack: fallback)
    }
    
    func retry(_ retryCount: UInt) -> ItemService {
        var service: ItemService = self
        for _ in 0..<retryCount {
            service = service.fallBack(self)
        }
        return service
    }
    
}
