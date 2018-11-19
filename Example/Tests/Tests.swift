import UIKit
import XCTest
import ConnectionKit
import RepresentationKit

class Tests: XCTestCase, ConnectionDelegate, ConnectionErrorDelegate {

    func didConnect(_ connection: Connection) {
        print("connected> ", connection)
        self.connectExpectation.fulfill()
    }

    func didDisconnect(_ connection: Connection, reason: Error?) {
        print("dis-connected> ", connection, " reason: ", String(describing: reason))
    }

    func didReceive(_ representable: Representable) {
        let data = representable as! Data
        let result = String(data: data, encoding: String.Encoding.utf8)
        print("received> ", representable, " result: ", result)
        guard self.receptionIndex < self.receptionExpectation.endIndex else { return }
        self.receptionExpectation[self.receptionIndex].fulfill()
        self.receptionIndex += 1
    }

    func didFail(with error: ConnectionError) {
        print("failed> ", error)
    }

    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    private var connectExpectation: XCTestExpectation!
    private var receptionExpectation: [XCTestExpectation] = []
    private var receptionIndex = 0
    
    func testExample() {
        // This is an example of a functional test case.
        self.connectExpectation = XCTestExpectation(description: "connection")
        self.receptionExpectation = [XCTestExpectation(description: "receive1"),
                                     XCTestExpectation(description: "receive2"),
                                     XCTestExpectation(description: "receive3")]
        let connection = SocketConnection(host: Host("localhost"),
                                          port: Port(1234),
                                          delegate: self,
                                          errorDelegate: self,
                                          outboundRepresentation: DataFromJSONRepresentation())
        connection.connect()
        self.wait(for: [self.connectExpectation] +
                        self.receptionExpectation,
                  timeout: 5.0)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure() {
            // Put the code you want to measure the time of here.
        }
    }
    
}

