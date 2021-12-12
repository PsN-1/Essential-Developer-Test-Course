//	
// Copyright © Essential Developer. All rights reserved.
//

import XCTest
@testable import CrashCourse


class FriendsViewController: UIViewController {
    private let service: FriendsService
    
    init(service: FriendsService) {
        self.service = service
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class FriendsServiceSpy: FriendsService {
    private(set) var loadFriendsCallCount = 0
    func loadFriends(completion: @escaping (Result<[Friend], Error>) -> Void) {
        loadFriendsCallCount += 1
    }
}


class FriendsTests: XCTestCase {
    func test_viewDidLoad_doesNotLoadFriendsFromAPI() {
        let service = FriendsServiceSpy()
        let sut = FriendsViewController(service: service)
        
        
        sut.loadViewIfNeeded()
        
        
        XCTAssertEqual(service.loadFriendsCallCount, 0)
        
    }
}
