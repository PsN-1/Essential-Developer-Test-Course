//	
// Copyright © Essential Developer. All rights reserved.
//

import UIKit

class FriendsViewController: UITableViewController {
    private let service: FriendsService
    private var friends: [Friend] = [] {
        didSet { tableView.reloadData() }
    }
    
    init(service: FriendsService) {
        self.service = service
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        load()
    }
    
    func load(retryCount: Int = 0) {
        let maxRetryCount = 2
        service.loadFriends { result in
            switch result {
            case let .success(friends):
                self.friends = friends
            case let .failure(error):
                if retryCount == maxRetryCount {
                    self.show(error)
                } else {
                    self.load(retryCount: retryCount+1)
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        friends.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        
        let friend = friends[indexPath.row]
        cell.textLabel?.text = friend.name
        cell.detailTextLabel?.text = friend.phone
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        show(friends[indexPath.row])
    }
}
