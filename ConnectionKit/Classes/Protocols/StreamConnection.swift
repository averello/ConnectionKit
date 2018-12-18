//
//  StreamConnection.swift
//  ConnectionKit
//
//  Created by Georges Boumis on 19/11/2018.
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

/// A Stream Connection based on `Stream`s.
///
/// A `StreamConnection` gives access to each underlying input & output streams.
public protocol StreamConnection: Connection {
    /// Gives access to the receiver's input/output streams.
    ///
    /// The streams **must** not escape the block's lifetime.
    /// - parameter block: A closure giving access to the receivers Streams.
    func accessStreams(_ block: @escaping (_ input: InputStream, _ output: OutputStream) -> Void)
}

