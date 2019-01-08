//
//  Connection.swift
//  ConnectionKit
//
//  Created by Georges Boumis on 21/06/2016.
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

import Foundation

#if canImport(RepresentationKit)
import RepresentationKit

/// Represents generic Connection Errors.
public enum ConnectionError: Error {
    /// The connection failed. Usually happens upon `connect()`.
    /// - parameter error: Any underlying error that explains more the situation.
    case connectionFailed(_ error: Error?)
    /// Reception failed.
    /// - parameter error: Any underlying error that explains more the situation.
    case receptionFailed(_ error: Error?)
    /// Send failed.
    /// - parameter error: Any underlying error that explains more the situation.
    case sendFailed(_ error: Error?)
    /// Indicates that the connection disconnected due to the user requesting so.
    /// - parameter error: Any underlying error that explains more the situation.
    case disconnection(_ error: Error?)
    /// Error indicating an request for connection occured on an already
    /// established connection.
    /// - parameter error: Any underlying error that explains more the situation.
    case alreadyConnected(_ error: Error?)
}

/// What a connection should be
public protocol Connection {

    /// The delegate of the connection. It should be a `weak` instance.
    /* weak */ var delegate: ConnectionDelegate? { get set }
    /// The error delegate of the connection. It should be a `weak` instance.
    /* weak */ var errorDelegate: ConnectionErrorDelegate? { get set }

    /// Initiates the connection.
    ///
    /// Should any error occur during connection an error should be throw. Some
    /// generic (inevitable) errors are defined in `ConnectionError`.
    func connect() throws

    /// Should immediately break the connection, without flushing any pending
    /// data. The connection is "closed" after `didDisconnect()` is invoked on
    /// the delegate with error type `ConnectionError.disconnection`.
    func disconnect()

    /// Should break the connection after flushing any pending data. It should
    /// be expected that no delegate invokations should occured after `close()`
    /// returns.
    func close()

    /// Sends a `Representable` value through the receiver.
    func send(_ representable: Representable)
}
#endif
