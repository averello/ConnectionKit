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

#if canImport(CocoaAsyncSocket) && canImport(RepresentationKit)
import CocoaAsyncSocket
import RepresentationKit

/// A socket connection based on TCP. Uses `GCDAsyncSocket` for the heavy
/// lifting.
///
/// A `SocketConnection` always transfer `Data` through the wire. So the owner
/// of the connection should provide the `DataRepresentation` of the objects
/// to send throught the `SocketConnection`.
public final class SocketConnection: NSObject, Connection {

    // MARK: - Interface

    /// The host that the receiver connects to.
    final public let host: Host
    /// The port of the `host` the receiver connects to.
    final public let port: Port
    /// The time out to use for send/reception of data through the connection.
    final public var timeOut: TimeInterval = 5.0

    // MARK: - Private

    final fileprivate var socket: GCDAsyncSocket!
    final private let out: DataRepresentation

    // MARK: - Conformance to Connection

    /// The delegate of the connection.
    weak final public var delegate: ConnectionDelegate?
    /// The error delegate of the connection.
    weak final public var errorDelegate: ConnectionErrorDelegate?

    /// Creates a `SocketConnection`.
    /// - parameter host: The host to connect to.
    /// - parameter port: The port of the `host` to connect to.
    /// - parameter delegate: The delegate of the connection.
    /// - parameter errorDelegate: The error delegate to connect to.
    /// - parameter outboundRepresentation: The data representation to use
    /// on objects that are to be sent throught the receiver.
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

    convenience public init(endpoint: (host: Host, port: Port),
                            delegates: (delegate: ConnectionDelegate?, errorDelegate: ConnectionErrorDelegate?),
                            outboundRepresentation: DataRepresentation) {
        self.init(host: endpoint.host,
                  port: endpoint.port,
                  delegate: delegates.delegate,
                  errorDelegate: delegates.errorDelegate,
                  outboundRepresentation: outboundRepresentation)
    }

    deinit {
        self.disconnect()
        self.socket = nil
        self.delegate = nil
        self.errorDelegate = nil
    }

    // MARK: - Public methods

    final public func connect() {
        do {
            try self.socket.connect(toHost: self.host,
                                    onPort:self.port)
        }
        catch {
            let nserror: NSError = error as NSError
            if nserror.code == GCDAsyncSocketError.alreadyConnected.rawValue {
                self.errorDelegate?.connection(self, didFailWith: ConnectionError.alreadyConnected(error))
            }
            else {
                self.errorDelegate?.connection(self, didFailWith: ConnectionError.connectionFailed(error))
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

fileprivate extension SocketConnection {

    fileprivate enum Tag: Int {
        case inMessage = 42
        case outMessage = 84
    }
}

extension SocketConnection: GCDAsyncSocketDelegate {

    // MARK: -  GCDAsyncSocketDelegate

    @objc
    final public func socket(_ sock: GCDAsyncSocket,
                             didRead data: Data,
                             withTag tag: Int) {
        if let received = data as? Representable {
            self.delegate?.connection(self, didReceive: received)
        }
        else {
            self.errorDelegate?.connection(self,
                                           didFailWith: ConnectionError.receptionFailed(nil))
        }

        self.socket.readData(to: GCDAsyncSocket.lfData(),
                             withTimeout: self.timeOut,
                             tag: Tag.inMessage.rawValue)
    }

    @objc
    final public func socket(_ sock: GCDAsyncSocket,
                             didConnectToHost host: String,
                             port: UInt16) {
        self.delegate?.connectionDidConnect(self)

        // start reading
        self.socket.readData(to: GCDAsyncSocket.lfData(),
                             withTimeout: self.timeOut,
                             tag: Tag.inMessage.rawValue)
    }

    @objc
    final public func socketDidDisconnect(_ sock: GCDAsyncSocket,
                                          withError error: Error?) {
        self.delegate?.connection(self,
                                  didDisconnectWithReason: ConnectionError.disconnection(error))
    }
}


extension SocketConnection: StreamConnection {

    public func accessStreams(_ block: @escaping (InputStream, OutputStream) -> Void) {
        self.socket.perform { [unowned self] in
            guard let input = self.socket.readStream()?.takeUnretainedValue(),
                let output = self.socket.writeStream()?.takeUnretainedValue() else { return }
            block(input, output)
        }
    }
}
#endif
