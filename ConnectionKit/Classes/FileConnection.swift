//
//  FileConnection.swift
//  ConnectionKit
//
//  Created by Georges Boumis on 07/10/2016.
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

//import Foundation
//import RepresentationKit
//import ContentKit
//
//final public class TextFileConnection<R>: Connection where R: TextRepresentation {
//    public private(set) weak var delegate : ConnectionDelegate?
//    public private(set) weak var errorDelegate : ConnectionErrorDelegate?
//    private let path: String
//    private let representation: R
//    private var output: OutputStream!
//    private var input: InputStream!
//
//    public init(path: String,
//                representation: R,
//                delegate: ConnectionDelegate,
//                errorDelegate: ConnectionErrorDelegate?) {
//        self.path = path
//        self.representation = representation
//        self.delegate = delegate
//        self.errorDelegate = errorDelegate
//    }
//
//    final public func connect() throws {
//        // open file
//        guard let input = InputStream(fileAtPath: path) else { throw ConnectionError.connectionFailed }
//        guard let output = OutputStream(toFileAtPath: path, append: true) else { throw ConnectionError.connectionFailed }
//        self.input = input
//        self.output = output
//    }
//
//    final public func disconnect() {
//        self.close()
//    }
//    final public func close() {
//        // close file
//        self.input.close()
//        self.output.close()
//
//        self.input = nil
//        self.output = nil
//    }
//
//    final public func send(_ representable : Representable) throws {
//        self.output.write(<#T##buffer: UnsafePointer<UInt8>##UnsafePointer<UInt8>#>, maxLength: <#T##Int#>)
//        representable.represent(using: self.representation)
//    }
//}
