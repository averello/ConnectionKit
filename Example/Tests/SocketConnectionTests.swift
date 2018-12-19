//
//  SocketConnectionTests.swift
//  ConnectionKit_Tests
//
//  Created by Georges Boumis on 18/12/2018.
//
//  Licensed to the Apache Software Foundation (ASF) under one
//  or more contributor license agreements.  See the NOTICE file
//  distributed with this work for additional information
//  regarding copyright ownership.  The ASF licenses this file
//  to you under the Apache License, Version 2.0 (the
//  "License"); you may not use this file except in compliance
//  with the License.  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.
//

import XCTest
import Foundation
import ConnectionKit
import RepresentationKit

fileprivate struct IdentityDataRepresentation: DataRepresentation {
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

final class SocketConnectionTests: XCTestCase, ConnectionDelegate, ConnectionErrorDelegate {

    final private var server: Process!

    final override func setUp() {
        super.setUp()

        let ncURL = URL(fileURLWithPath: "/usr/bin/nc")
        let catURL = URL(fileURLWithPath: "/bin/cat")
        do {
            let input = Bundle(for: type(of: self)).path(forResource: "input", ofType: nil)!
            let cat = Process()
            cat.executableURL = catURL
            cat.arguments = [input]

            self.server = Process()
            self.server.executableURL = ncURL
            self.server.arguments = ["-l", "127.0.0.1", "42042"]

            let pipe = Pipe()
            cat.standardOutput = pipe.fileHandleForWriting
            self.server.standardInput = pipe.fileHandleForReading
            try cat.run()
            try self.server.run()

        } catch {
            assert(false)
        }
    }

    final override func tearDown() {
        super.tearDown()

        self.server.terminate()
    }

    final func connectionDidConnect(_ connection: Connection) {
        print("connected> ", connection)
        self.connectExpectation?.fulfill()
    }


    final func connection(_ connection: Connection, didDisconnectWithReason reason: Error?) {
        print("dis-connected> ", connection, " reason: ", String(describing: reason))
        self.disconnectExpectation?.fulfill()
    }


    final func connection(_ connection: Connection, didReceive representable: Representable) {
        let data = representable as! Data
        let result = String(data: data, encoding: String.Encoding.utf8)!.trimmingCharacters(in: CharacterSet.newlines)

        if let receptionExpectation = self.receptionExpectation {
            let input = Bundle(for: type(of: self)).path(forResource: "input", ofType: nil)!
            let expected = (try! String(contentsOfFile: input, encoding: String.Encoding.utf8)).split(separator: "\n")[0]
            if result == expected {
                receptionExpectation.fulfill()
            }
        }
        if !self.receptions.isEmpty {
            let input = Bundle(for: type(of: self)).path(forResource: "input", ofType: nil)!
            let expected = (try! String(contentsOfFile: input, encoding: String.Encoding.utf8)).split(separator: "\n")[self.receptionsIndex]
            if result == expected {
                self.receptions[self.receptionsIndex].fulfill()
            }
            self.receptionsIndex += 1
        }
    }

    final func connection(_ connection: Connection, didFailWith error: ConnectionError) {
        print("failed> ", error)
    }

    final private var connectExpectation: XCTestExpectation?
    final private var disconnectExpectation: XCTestExpectation?
    final private var receptionExpectation: XCTestExpectation?


    final private var receptions: [XCTestExpectation] = []
    final private var receptionsIndex = 0

    final func testConnection() {
        self.connectExpectation = XCTestExpectation(description: "connection")
        let connection = SocketConnection(host: Host("127.0.0.1"),
                                          port: Port(42042),
                                          delegate: self,
                                          errorDelegate: self,
                                          outboundRepresentation: IdentityDataRepresentation())
        connection.connect()
        self.wait(for: [self.connectExpectation!], timeout: 5.0)
    }

    final func testDisconnection() {
        self.connectExpectation = XCTestExpectation(description: "connection")
        self.disconnectExpectation = XCTestExpectation(description: "disconnection")
        let connection = SocketConnection(host: Host("127.0.0.1"),
                                          port: Port(42042),
                                          delegate: self,
                                          errorDelegate: self,
                                          outboundRepresentation: IdentityDataRepresentation())
        connection.connect()
        DispatchQueue.main.async {
            connection.disconnect()
        }
        self.wait(for: [self.connectExpectation!,
                        self.disconnectExpectation!], timeout: 5.0)
    }

    final func testReception() {
        self.connectExpectation = XCTestExpectation(description: "connection")
        self.receptionExpectation = XCTestExpectation(description: "reception")
        self.disconnectExpectation = XCTestExpectation(description: "disconnection")
        let connection = SocketConnection(host: Host("127.0.0.1"),
                                          port: Port(42042),
                                          delegate: self,
                                          errorDelegate: self,
                                          outboundRepresentation: IdentityDataRepresentation())
        connection.connect()
        let then = DispatchTime.now() + DispatchTimeInterval.seconds(3)
        DispatchQueue.main.asyncAfter(deadline: then) {
            connection.disconnect()
        }
        self.wait(for: [self.connectExpectation!,
                        self.disconnectExpectation!,
                        self.receptionExpectation!],
                  timeout: 5.0)
    }

    final func testReceptions() {
        self.connectExpectation = XCTestExpectation(description: "connection")
        self.disconnectExpectation = XCTestExpectation(description: "disconnection")
        self.receptionsIndex = 0
        self.receptions = (0..<3).map({ (index: Int) -> XCTestExpectation in
            return XCTestExpectation(description: "reception<\(index)>")
        })
        let connection = SocketConnection(host: Host("127.0.0.1"),
                                          port: Port(42042),
                                          delegate: self,
                                          errorDelegate: self,
                                          outboundRepresentation: IdentityDataRepresentation())
        connection.connect()
        let then = DispatchTime.now() + DispatchTimeInterval.seconds(3)
        DispatchQueue.main.asyncAfter(deadline: then) {
            connection.disconnect()
        }
        self.wait(for: [self.connectExpectation!,
                        self.disconnectExpectation!] + self.receptions,
                  timeout: 5.0)
    }
}
