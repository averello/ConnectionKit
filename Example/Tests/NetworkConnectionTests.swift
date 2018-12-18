//
//  NetworkConnectionTests.swift
//  ConnectionKit_Tests
//
//  Created by Georges Boumis on 18/12/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
import ConnectionKit
import RepresentationKit

struct IdentityDataRepresentation: DataRepresentation {
    let data: Data

    private init(data: Data) {
        self.data = data
    }

    init() {
        self.init(data: Data())
    }

    func with<Key, Value>(key: Key, value: Value) -> Representation where Key : Hashable, Key : LosslessStringConvertible {
        return IdentityDataRepresentation(data: value as! Data)
    }
}

class NetworkConnectionTests: XCTestCase, ConnectionDelegate, ConnectionErrorDelegate {

    func connectionDidConnect(_ connection: Connection) {
        print("connected> ", connection)
        self.connectExpectation?.fulfill()
    }


    func connection(_ connection: Connection, didDisconnectWithReason reason: Error?) {
        print("dis-connected> ", connection, " reason: ", String(describing: reason))
        self.disconnectExpectation?.fulfill()
    }


    func connection(_ connection: Connection, didReceive representable: Representable) {
//        let data = representable as! Data
//        let result = String(data: data, encoding: String.Encoding.utf8)
//        print("received> ", representable, " result: ", result)
//        guard self.receptionIndex < self.receptionExpectation.endIndex else { return }
//        self.receptionExpectation[self.receptionIndex].fulfill()
//        self.receptionIndex += 1
    }

    func connection(_ connection: Connection, didFailWith error: ConnectionError) {
        print("failed> ", error)
    }

    private var connectExpectation: XCTestExpectation?
    private var disconnectExpectation: XCTestExpectation?
    private var receptionExpectation: [XCTestExpectation] = []
    private var receptionIndex = 0

    func testConnection() {
        // This is an example of a functional test case.
        self.connectExpectation = XCTestExpectation(description: "connection")
        let connection = SocketConnection(host: Host("127.0.0.1"),
                                          port: Port(42042),
                                          delegate: self,
                                          errorDelegate: self,
                                          outboundRepresentation: IdentityDataRepresentation())
        connection.connect()
        self.wait(for: [self.connectExpectation!], timeout: 5.0)
    }

    func testDisconnection() {
        // This is an example of a functional test case.
        self.connectExpectation = XCTestExpectation(description: "connection")
        self.disconnectExpectation = XCTestExpectation(description: "disconnection")
        let connection = SocketConnection(host: Host("127.0.0.1"),
                                          port: Port(42042),
                                          delegate: self,
                                          errorDelegate: self,
                                          outboundRepresentation: IdentityDataRepresentation())
        connection.connect()
        connection.disconnect()
        self.wait(for: [self.disconnectExpectation!], timeout: 5.0)
    }
}
