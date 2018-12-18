import UIKit
import XCTest
import ConnectionKit
import RepresentationKit

class Tests: XCTestCase, ConnectionDelegate, ConnectionErrorDelegate {

    func connectionDidConnect(_ connection: Connection) {
        print("connected> ", connection)
        self.connectExpectation.fulfill()
    }


    func connection(_ connection: Connection, didDisconnectWithReason reason: Error?) {
        print("dis-connected> ", connection, " reason: ", String(describing: reason))
    }


    func connection(_ connection: Connection, didReceive representable: Representable) {
        let data = representable as! Data
        let result = String(data: data, encoding: String.Encoding.utf8)
        print("received> ", representable, " result: ", result)
        guard self.receptionIndex < self.receptionExpectation.endIndex else { return }
        self.receptionExpectation[self.receptionIndex].fulfill()
        self.receptionIndex += 1
    }

    func connection(_ connection: Connection, didFailWith error: ConnectionError) {
        print("failed> ", error)
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
}

