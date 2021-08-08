//
// Copyright © 2021 Essential Developer. All rights reserved.
//

import UIKit

// any kind of abstraction that hides implementation details
// the common solution is to use a protocol

//protocol APIService {
    
    // instead of accessing the dependencies directly through singletons we could inject this dependency into the ListVC

    // instead of the ListVC depending on the concrete friendsAPI, Cache and so on we can use a protocol which is an abstraction to invert the dependency
    
//    func loadFriends(completion: @escaping (Result<[Friend], Error>) -> Void)
//    func loadCards(completion: @escaping (Result<[Card], Error>) -> Void)
//    func loadTransfers(completion: @escaping (Result<[Transfer], Error>) -> Void)
    
     
    // This protocol violates the Interface segregation principle which means "clients shouldn't depend on methods they do not need"
//}

// The Interface segregation principle
// you should separate unrelated methods into separate interfaces(separate abstractions)

//protocol FriendsService {
//    func loadFriends(completion: @escaping (Result<[Friend], Error>) -> Void)
//}
//
//protocol CardsService {
//    func loadCards(completion: @escaping (Result<[Card], Error>) -> Void)
//}
//
//protocol TransfersService {
//    func loadTransfers(completion: @escaping (Result<[Transfer], Error>) -> Void)
//}

protocol ItemService {
    // This is just an abstraction. not an implementation.
    // This ListVC  needs a single sevice that can provide itemViewModels. regardless of from which API they come from. regardless of the data source(if it's coming from cache or network)
    // this is the key and deciding which API to use as an implementation details. so the vc shouldn't know about
    // this is the strategy pattern when you have single interface  in many different implementations or context
    func loadItems(completion: @escaping (Result<[ItemViewModel], Error>) -> Void)
}



class ListViewController: UITableViewController {
	var items = [ItemViewModel]()
	
//    var service: APIService? // use dependency instead of accessing the singletons directly
    // vc would talk indirectly to the dependencies through the protocol(abstraction)
    // which is allows to us to replace the implementation without having to change the vc
    // we can easily replace this during tests instead of trying to globally mock all network requests.
    // can simply inject here an implementation a testable mock or a stub (makes testing easier without issues with global dependencies. so we can run tests faster and parallel concurrently)
    
//    var friendsService: FriendsService?
//    var cardService: CardsService?
//    var transfereService: TransfersService?
    
    var service: ItemService? // single service with the exact interface with precisely what the listVC needs
    
	var retryCount = 0
	var maxRetryCount = 0
	var shouldRetry = false
	
	var longDateStyle = false
	
	var fromReceivedTransfersScreen = false
	var fromSentTransfersScreen = false
	var fromCardsScreen = false
	var fromFriendsScreen = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		refreshControl = UIRefreshControl()
		refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
		
        if fromSentTransfersScreen {
			shouldRetry = true
			maxRetryCount = 1
			longDateStyle = true

			navigationItem.title = "Sent"
			navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(sendMoney))

		} else if fromReceivedTransfersScreen {
			shouldRetry = true
			maxRetryCount = 1
			longDateStyle = false
			
			navigationItem.title = "Received"
			navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Request", style: .done, target: self, action: #selector(requestMoney))
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if tableView.numberOfRows(inSection: 0) == 0 {
			refresh()
		}
	}
	
	@objc private func refresh() {
		refreshControl?.beginRefreshing()
		if fromFriendsScreen {
            
            // we don't need to access API directly
//            service = FriendsAPIItemsServiceAdapter(api: FriendsAPI.shared, cache: (UIApplication.shared.connectedScenes.first?.delegate as! SceneDelegate).cache, isPremium: User.shared?.isPremium == true, select: { [weak self] item in
//                self?.select(friend: item)
//            })
//            
            service?.loadItems(completion: handleAPIResult)
            
            // Dependency inversion principle states that high-level components should not depend on low-level details. both high-level components and low-level components should depend on abstractions.
            
            // with the dependencies pointing from low-level to high-level -> need an abstraction to separate the concrete types
            
            // common abstraction -> can use protocol, class, closure
            
            
//			FriendsAPI.shared.loadFriends { [weak self] result in
//				DispatchQueue.mainAsyncIfNeeded {
//                    self?.handleAPIResult(result.map { items in
//
//                        if User.shared?.isPremium == true {
//                            (UIApplication.shared.connectedScenes.first?.delegate as! SceneDelegate).cache.save(items)
//                        }
//
//                        return items.map { item in
//                            ItemViewModel(friend: item, selection: {
//                                // in this context, we know the concrete type. doesn't need to convert it to Any
//                                self?.select(friend: item)
//                            })
//                        }
//                    })
//				}
//			}
            
            
		} else if fromCardsScreen {
//			CardAPI.shared.loadCards { [weak self] result in
//				DispatchQueue.mainAsyncIfNeeded {
//                    self?.handleAPIResult(result.map { items in
//                        items.map { item in
//                            ItemViewModel(card: item, selection: {
//                                self?.select(card: item)
//                            })
//                        }
//                    })
//				}
//			}
            service?.loadItems(completion: handleAPIResult)
            
		} else if fromSentTransfersScreen || fromReceivedTransfersScreen {
            // to need to know the context, capture the boolean context in the closure([weak self, ...])
			TransfersAPI.shared.loadTransfers { [weak self, longDateStyle, fromSentTransfersScreen] result in
				DispatchQueue.mainAsyncIfNeeded {
                    self?.handleAPIResult(result.map { items in
//                        var filteredItems = items
                        // filter the array of models
//                        if fromSentTransfersScreen {
//                            filteredItems = filteredItems.filter(\.isSender)
//                        } else {
//                            filteredItems = filteredItems.filter { !$0.isSender }
//                        }
                        
//                        return filteredItems
                        items
                            .filter { fromSentTransfersScreen ? $0.isSender : !$0.isSender }
                            .map { item in
                            ItemViewModel(transfer: item,
                                          longDateStyle: longDateStyle,
                                          selection: {
                                self?.select(transfer: item)
                            })
                        }
                    })
				}
			}
		} else {
			fatalError("unknown context")
		}
	}
	
	private func handleAPIResult(_ result: Result<[ItemViewModel], Error>) {
		switch result {
		case let .success(items):
			self.retryCount = 0
            
            // don't need to map here anymore cause we're mapping where we have context
//            self.items = filteredItems.map { item in // map will iterate to the list of filteredItems
//                return ItemViewModel(item, longDateStyle: longDateStyle, selection: { [weak self] in // hold a reference to self
//                   if let friend = item as? Friend {
//                    self?.select(friend: friend)
//                   } else if let card = item as? Card {
//                    self?.select(card: card)
//                   } else if let transfer = item as? Transfer {
//                    self?.select(transfer: transfer  )
//                   } else {
//                       fatalError("unknown item: \(item)")
//                   }
//                })
//            }
            
            self.items = items
			self.refreshControl?.endRefreshing()
			self.tableView.reloadData()
			
		case let .failure(error):
			if shouldRetry && retryCount < maxRetryCount {
				retryCount += 1
				
				refresh()
				return
			}
			
			retryCount = 0
			
			if fromFriendsScreen && User.shared?.isPremium == true {
				(UIApplication.shared.connectedScenes.first?.delegate as! SceneDelegate).cache.loadFriends { [weak self] result in
					DispatchQueue.mainAsyncIfNeeded {
						switch result {
						case let .success(items):
                            self?.items = items.map { item in
                                ItemViewModel(friend: item, selection: { [weak self] in // hold a reference to self
                                    self?.select(friend: item)
                                })
                            }
							self?.tableView.reloadData()
							
						case let .failure(error):
                            self?.showError(error: error)
						}
						self?.refreshControl?.endRefreshing()
					}
				}
			} else {
                self.showError(error: error)
                self.refreshControl?.endRefreshing()
			}
		}
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		items.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let item = items[indexPath.row]
		let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "ItemCell")
		cell.configure(item)
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let item = items[indexPath.row]
        item.select()
	}
}

struct ItemViewModel {
    var title: String
    var subtitle: String
    let select: () -> Void
    
//    init(_ item: Any, longDateStyle: Bool, selection: @escaping () -> Void) { // needs to be escaping because it's holding a reference (escapes the context)
//        if let friend = item as? Friend {
//            self.init(friend: friend, selection: selection)
//        } else if let card = item as? Card {
//            self.init(card: card, selection: selection)
//        } else if let transfer = item as? Transfer {
//            self.init(transfer, longDateStyle: longDateStyle, selection: selection )
//        } else {
//            fatalError("unknown item: \(item)")
//        }
//    }
}

extension ItemViewModel {
    init(friend: Friend, selection: @escaping () -> Void) {
        title = friend.name
        subtitle = friend.phone
        select = selection
    }
}

extension ItemViewModel {
    init(card: Card, selection: @escaping () -> Void) {
        title = card.number
        subtitle = card.holder
        select = selection
    }
}

extension ItemViewModel {
    
    init(transfer: Transfer, longDateStyle: Bool, selection: @escaping () -> Void) {
        let numberFormatter = Formatters.number
        numberFormatter.numberStyle = .currency
        numberFormatter.currencyCode = transfer.currencyCode
        
        let amount = numberFormatter.string(from: transfer.amount as NSNumber)!
        title = "\(amount) • \(transfer.description)"
        
        let dateFormatter = Formatters.date
        if longDateStyle {
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short
            subtitle = "Sent to: \(transfer.recipient) on \(dateFormatter.string(from: transfer.date))"
        } else {
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            subtitle = "Received from: \(transfer.sender) on \(dateFormatter.string(from: transfer.date))"
        }
        
        select = selection
    }
}


extension UITableViewCell {
	func configure(_ vm: ItemViewModel) {
        textLabel?.text = vm.title
        detailTextLabel?.text = vm.subtitle
	}
}

extension UIViewController {
    
    func select(friend: Friend) {
        let vc = FriendDetailsViewController()
        vc.friend = friend
//        navigationController?.pushViewController(vc, animated: true)
        show(vc, sender: self) // (decoupled from navigation controller)
        // show is for presenting or pushing in a navigation controller/splitViewController
    }
    
    func select(card: Card) {
        let vc = CardDetailsViewController()
        vc.card = card
        show(vc, sender: self)
    }
    
    func select(transfer: Transfer) {
        let vc = TransferDetailsViewController()
        vc.transfer = transfer
        show(vc, sender: self)
    }
    
    @objc func addCard() {
//        navigationController?.pushViewController(AddCardViewController(), animated: true)
        show(AddCardViewController(), sender: self)
    }
    
    @objc func addFriend() {
//        navigationController?.pushViewController(AddFriendViewController(), animated: true)
        show(AddFriendViewController(), sender: self)
    }
    
    @objc func sendMoney() {
//        navigationController?.pushViewController(SendMoneyViewController(), animated: true)
        show(SendMoneyViewController(), sender: self)
    }
    
    @objc func requestMoney() {
//        navigationController?.pushViewController(RequestMoneyViewController(), animated: true)
        show(RequestMoneyViewController(), sender: self )
    }
    
    func showError(error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
//                self.presenterVC.present(alert, animated: true)
        showDetailViewController(alert, sender: self)
    }
}


// Null Object Pattern

class NullFriendsCache: FriendsCache {
    
    override func save(_ newFriends: [Friend]) {
//        super.save(newFriends ) // usually when you override the methods. you call super to keep the behavior
    }
    
    // in this case we're not going to do anything. which means you will just ignore. that's the null object pattern. an instance sharing the same interface but that does nothing
    
}
