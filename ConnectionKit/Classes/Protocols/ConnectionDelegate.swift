//
//  ConnectionDelegate.swift
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

/// A Connection delegate.
public protocol ConnectionDelegate: class {
    /// Indicates that the given `Connection` was successfully established.
    /// - parameter connection: The connection that did successfully connect.
    func connectionDidConnect(_ connection: Connection)

    /// Indicates that the given `Connection` broke for given reason.
    /// - parameter connection: The connection that did disconnect.
    /// - parameter error: The reason, if any, why the connection disconnected.
    func connection(_ connection: Connection, didDisconnectWithReason reason: Error?)

    /// Some `Representable` value was received through the given collection
    /// - parameter representable: The `Representable` value received through
    /// the connection.
    /// - parameter connection: The connection.
    func connection(_ connection: Connection, didReceive representable: Representable)
}
#endif
