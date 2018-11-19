//
//  SocketConnection.swift
//  ConnectionKit
//
//  Created by Georges Boumis on 16/06/16.
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
import ContentKit
import RepresentationKit
import CocoaAsyncSocket

public final class SocketConnection: NSObject, GCDAsyncSocketDelegate, Connection {

    // MARK: Interface
    final public let host: Host
    final public let port: Port
    final public var timeOut: TimeInterval = 5.0

    // MARK: Private
    final fileprivate var socket: GCDAsyncSocket!
    final private let out: DataRepresentation

    // MARK: Conformance to Connection
    weak final public var delegate: ConnectionDelegate?
    weak final public var errorDelegate: ConnectionErrorDelegate?

    public init(host: Host,
                port: Port,
                delegate: ConnectionDelegate?,
                errorDelegate: ConnectionErrorDelegate?,
                outboundRepresentation: DataRepresentation) {

        self.host = host
        self.port = port
        self.delegate = delegate
        self.errorDelegate = errorDelegate
        self.out = outboundRepresentation

        super.init()

        self.socket = GCDAsyncSocket(delegate: self,
                                     delegateQueue: DispatchQueue.main)
        self.socket.isIPv4PreferredOverIPv6 = false
    }

    deinit {
        self.disconnect()
        self.socket = nil
        self.delegate = nil
        self.errorDelegate = nil
    }

    final public func connect() {
        do {
            try self.socket.connect(toHost: self.host,
                                    onPort:self.port)
        }
        catch {
            let nserror: NSError = error as NSError
            if nserror.code == GCDAsyncSocketError.alreadyConnected.rawValue {
                self.errorDelegate?.didFail(with: ConnectionError.alreadyConnected)
            }
            else {
                self.errorDelegate?.didFail(with: ConnectionError.connectionFailed)
            }
        }
    }

    final public func disconnect() {
        self.socket.disconnect()
    }
    
    final public func close() {
        self.delegate = nil
        self.socket.disconnectAfterWriting()
    }

    // never throws
    final public func send(_ representable: Representable) {
        let representation = representable.represent(using: self.out) as! DataRepresentation
        self.socket.write(representation.data,
                          withTimeout: self.timeOut,
                          tag: Tag.outMessage.rawValue)
    }
}

extension SocketConnection {
    fileprivate enum Tag: Int {
        case inMessage = 42
        case outMessage = 84
    }
}

extension SocketConnection {
    // MARK: GCDAsyncSocketDelegate
    final public func socket(_ sock: GCDAsyncSocket,
                             didRead data: Data,
                             withTag tag: Int) {
        self.delegate?.didReceive(data)
        self.socket.readData(to: GCDAsyncSocket.lfData(),
                             withTimeout: self.timeOut,
                             tag: Tag.inMessage.rawValue)
    }

    final public func socket(_ sock: GCDAsyncSocket,
                             didConnectToHost host: String,
                             port: UInt16) {
        self.delegate?.didConnect(self)

        // start reading
        self.socket.readData(to: GCDAsyncSocket.lfData(),
                             withTimeout: self.timeOut,
                             tag: Tag.inMessage.rawValue)
    }

    final public func socketDidDisconnect(_ sock: GCDAsyncSocket,
                                          withError err: Error?) {
        if let error = err {
            self.delegate?.didDisconnect(self, reason: error)
        } else {
            self.delegate?.didDisconnect(self, reason: ConnectionError.disconnection)
        }
    }
}


extension SocketConnection: StreamConnection {

    public var input: InputStream {
        assert(false) // do not use cf func accessStreams()
        return self.socket.readStream()!.takeUnretainedValue()
    }

    public var output: OutputStream {
        assert(false) // do not use cf func accessStreams()
        return self.socket.writeStream()!.takeUnretainedValue()
    }

    public func accessStreams(_ block: @escaping (InputStream, OutputStream) -> Void) {
        self.socket.perform { [unowned self] in
            guard let input = self.socket.readStream()?.takeUnretainedValue(),
                let output = self.socket.writeStream()?.takeUnretainedValue() else { return }
            block(input, output)
        }
    }
}
