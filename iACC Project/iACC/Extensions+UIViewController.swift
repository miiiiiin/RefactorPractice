//	
// Copyright © 2021 Essential Developer. All rights reserved.
//

import UIKit

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

