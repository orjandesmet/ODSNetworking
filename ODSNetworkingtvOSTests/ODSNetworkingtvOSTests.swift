//
//  ODSNetworkingtvOSTests.swift
//  ODSNetworkingtvOSTests
//
//  Created by Orjan De Smet on 27/04/16.
//  Copyright © 2016 Orjan De Smet. All rights reserved.
//

import XCTest
@testable import ODSNetworkingtvOS

class ODSNetworkingtvOSTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPacketPacking() {
        let a = ExamplePacket(data: "A test")
        XCTAssertEqual(a.type, "ExamplePacket")
        XCTAssertEqual(a.version, 1)
        XCTAssertEqual(a.data, "A test")
        
        let b = ExamplePacket(dictionary: a.dictionary)
        
        XCTAssertEqual(a.type, b.type)
        XCTAssertEqual(a.version, b.version)
        XCTAssertEqual(a.data, b.data)
        
        let c = ExamplePacket(jsonData: a.json())
        
        XCTAssertEqual(a.type, c.type)
        XCTAssertEqual(a.version, c.version)
        XCTAssertEqual(a.data, c.data)
    }
    
    /*func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }*/
    
}
