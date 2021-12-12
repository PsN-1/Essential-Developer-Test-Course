//	
// Copyright © Essential Developer. All rights reserved.
//

import XCTest
@testable import CrashCourse


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

class FriendsServiceSpy: FriendsService {
    private(set) var loadFriendsCallCount = 0
    private var results: [Result<[Friend], Error>]
    
    init(result: [Friend] = []) {
        self.results = [.success(result)]
    }
    
    init(results: [Result<[Friend], Error>]) {
        self.results = results
    }
    
    func loadFriends(completion: @escaping (Result<[Friend], Error>) -> Void) {
        loadFriendsCallCount += 1
        completion(results.removeFirst())
    }
}


class FriendsTests: XCTestCase {
    
    func test_viewDidLoad_doesNotLoadFriendsFromAPI() {
        let service = FriendsServiceSpy()
        let sut = FriendsViewController(service: service)
        
        sut.loadViewIfNeeded()
        
        XCTAssertEqual(service.loadFriendsCallCount, 0)
        
    }
    
    func test_viewWillAppear_LoadsFriendsFromAPI() {
       
        let service = FriendsServiceSpy()
        let sut = FriendsViewController(service: service)
        
        sut.simulateViewWillAppear()
        
        XCTAssertEqual(service.loadFriendsCallCount, 1)
    }
    
    func test_viewWillAppear_successfulAPIResponse_showsFriends() {
        let friend1 = Friend(id: UUID(), name: "friend1", phone: "phone1")
        let friend2 = Friend(id: UUID(), name: "friend2", phone: "phone2")
        let service = FriendsServiceSpy(result: [friend1, friend2])
        let sut = FriendsViewController(service: service)
        
        sut.simulateViewWillAppear()
        
        sut.assert(isRendering: [friend1, friend2])
    }
    
    func test_viewWillAppear_failedAPIResponse_3times_showsError() {
        let service = FriendsServiceSpy(results: [
            .failure(AnyError(errorDescription: "1st error")),
            .failure(AnyError(errorDescription: "2nd error")),
            .failure(AnyError(errorDescription: "3rd error"))
        ])
        let sut = TestableFriendsViewController(service: service)
        
        sut.simulateViewWillAppear()
        
        XCTAssertEqual(sut.errorMessage(), "3rd error")
    }
    
    func test_viewWillAppear_successAfterFailedAPIResponse_1time_showsFriends() {
        let friend = Friend(id: UUID(), name: "a friend", phone: "a phone")
        let service = FriendsServiceSpy(results: [
            .failure(AnyError(errorDescription: "1st error")),
            .success([friend])
        ])
        let sut = TestableFriendsViewController(service: service)
        
        sut.simulateViewWillAppear()
        
        sut.assert(isRendering: [friend])
    }
    
    func test_viewWillAppear_successAfterFailedAPIResponse_2time_showsFriends() {
        let friend = Friend(id: UUID(), name: "a friend", phone: "a phone")
        let service = FriendsServiceSpy(results: [
            .failure(AnyError(errorDescription: "1st error")),
            .failure(AnyError(errorDescription: "2nd error")),
            .success([friend])
        ])
        let sut = TestableFriendsViewController(service: service)
        
        sut.simulateViewWillAppear()
        
        sut.assert(isRendering: [friend])
    }
    
    func test_friendSelection_showsFriendDetails() {
        let friend = Friend(id: UUID(), name: "a friend", phone: "a phone")
        let service = FriendsServiceSpy(results: [
            .success([friend])
        ])
        let sut = TestableFriendsViewController(service: service)
        let navigation = NonAnimatedUINavigationController(rootViewController: sut)
        
        sut.simulateViewWillAppear()
        sut.selectFriend(at: 0)
        
        let detail = navigation.topViewController as? FriendDetailsViewController
        
        XCTAssertEqual(detail?.friend, friend)
    }
}

private class NonAnimatedUINavigationController: UINavigationController {
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: false)
    }
}

private struct AnyError: LocalizedError {
    var errorDescription: String?
}

private class TestableFriendsViewController: FriendsViewController {
    var presentedVC: UIViewController?
    
    override func present(_ vc: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        presentedVC = vc
    }
    
    func errorMessage() -> String? {
        let alert = presentedVC as? UIAlertController
        return alert?.message
    }
}

private extension FriendsViewController {
    
    func simulateViewWillAppear() {
        loadViewIfNeeded()
        beginAppearanceTransition(true, animated: false)
    }
    
    func assert(isRendering friends: [Friend]) {
        XCTAssertEqual(numberOfFriends(), friends.count)
        
        for (index, friend) in friends.enumerated() {
            XCTAssertEqual(friendName(at: index), friend.name)
            XCTAssertEqual(friendPhone(at: index), friend.phone)
        }
    }
    
    func numberOfFriends() -> Int {
        tableView.numberOfRows(inSection: friendsSection)
    }
    
    func friendName(at row: Int) -> String? {
        friendCell(at: row)?.textLabel?.text
    }
    
    func friendPhone(at row: Int) -> String? {
        friendCell(at: row)?.detailTextLabel?.text
    }
    
    func selectFriend(at row: Int) {
        let indexPath = IndexPath(row: row, section: friendsSection)
        tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
    }
    
    private func friendCell(at row: Int) -> UITableViewCell? {
        let indexPath = IndexPath(row: row, section: friendsSection)
        return tableView.dataSource?.tableView(tableView, cellForRowAt: indexPath)
    }
    
    private var friendsSection: Int { 0 }
    
}
