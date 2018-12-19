//
//  NetworkConnection.swift
//  ConnectionKit
//
//  Created by Georges Boumis on 07/06/2018.
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

#if canImport(Network) && canImport(RepresentationKit)
import Network
import RepresentationKit

@available(iOS 12, OSX 10.14, *)
public final class NetworkConnection: Connection {
    
    final public var delegate: ConnectionDelegate?
    final public var errorDelegate: ConnectionErrorDelegate?
    final private let out: DataRepresentation
    final private var buffer: NetworkConnection.Extractor!
    final private let chunkSize: Int = 4096

    
    final private var connection: NWConnection!
    final public let host: Host
    final public let port: Port
    final public let delimiter: Delimiter

    public enum Delimiter {
        case lineFeed
        case carriageReturn
        case crlf
    }
    
    public init(host: Host,
                port: Port,
                delegate: ConnectionDelegate?,
                errorDelegate: ConnectionErrorDelegate?,
                delimiter: Delimiter = .lineFeed,
                outboundRepresentation: DataRepresentation) {
        self.host = host
        self.port = port
        self.delegate = delegate
        self.errorDelegate = errorDelegate
        self.delimiter = delimiter
        self.out = outboundRepresentation
        self.bootstrap()
        self.buffer = NetworkConnection.Extractor(capacity: self.chunkSize,
                                                  delimiter: delimiter)
    }
    
    deinit {
        self.disconnect()
    }

    final public func connect() {
        print("ConnectionKit.NetworkConnection.connect")
        if self.connection.state != NWConnection.State.setup {
            self.connection.forceCancel()
            self.bootstrap()
        }
        self.connection.start(queue: DispatchQueue.main)
    }

    // MARK: - Public
    
    final public func disconnect() {
        self.connection.forceCancel()
    }
    
    final public func close() {
        self.connection.cancel()
    }
    
    final public func send(_ representable: Representable) {
        let representation = representable.represent(using: self.out) as! DataRepresentation
        self.connection.send(content: representation.data,
                             completion: NWConnection.SendCompletion.contentProcessed({ (e: NWError?) in
                                guard let error = e else {
                                    print("ConnectionKit.NetworkConnection.send failed with unknown error.")
                                    return }
                                print("ConnectionKit.NetworkConnection.send failed with \(error).")
                             }))
    }
}

protocol NetworkBuffer {
    var capacity: Int { get }
    var contents: Data { get }

    func append(data: Data)
}

@available(iOS 12, OSX 10.14, *)
fileprivate extension NetworkConnection.Delimiter {

    fileprivate var data: Data {
        switch self {
        case .carriageReturn:
            return "\r".data(using: .ascii)!

        case .lineFeed:
            return "\n".data(using: .ascii)!

        case .crlf:
            return "\r\n".data(using: .ascii)!
        }
    }
}

@available(iOS 12, OSX 10.14, *)
extension NetworkConnection {

    final fileprivate func bootstrap() {

        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.connectionTimeout = 5
        tcpOptions.enableKeepalive = true
        let parameters = NWParameters(tls: nil, tcp: tcpOptions)
        parameters.expiredDNSBehavior = .allow
        parameters.serviceClass = .responsiveData
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host.name(self.host, nil),
                                           port: NWEndpoint.Port(rawValue: self.port)!)
        self.connection = NWConnection(to: endpoint,
                                       using: parameters)
        self.connection.stateUpdateHandler = { [weak self] (state: NWConnection.State) in
            guard let strelf = self else { return }
            strelf.stateUpdateHandler(state: state)
        }
    }


    final fileprivate func stateUpdateHandler(state: NWConnection.State) {
        switch state {
        case NWConnection.State.ready:
            print("ConnectionKit.NetworkConnection> read will receive")
            self.delegate?.connectionDidConnect(self)
            self.receive()

        case NWConnection.State.failed(let error):
            print("ConnectionKit.NetworkConnection>.stateUpdateHandler failed with \(error)")

            self.errorDelegate?.connection(self,
                                           didFailWith: ConnectionError.connectionFailed)
            self.bootstrap()

        case NWConnection.State.cancelled:
            print("ConnectionKit.NetworkConnection> cancelled")
            self.delegate?.connection(self,
                                      didDisconnectWithReason: ConnectionError.disconnection)
        default:
            break
        }
    }

    final fileprivate func receive() {
        let min = self.delimiter.data.count
        let max = self.chunkSize
        self.connection.receive(minimumIncompleteLength: min,
                                maximumLength: max,
                                completion: { [weak self] (d: Data?, context: NWConnection.ContentContext?, isComplete: Bool, e: NWError?) in
                                    guard let strelf = self else { return }

                                    if let error = e {
                                        print("ConnectionKit.NetworkConnection.received failed with \(error)")
                                        strelf.errorDelegate?.connection(strelf,
                                                                         didFailWith: ConnectionError.receptionFailed)
                                        return
                                    }
                                    guard let data = d else { return }
                                    let packets = strelf.buffer.append(data: data)
                                    packets.forEach({ (packet: Data)  in
                                        strelf.delegate?.connection(strelf, didReceive: packet)
                                    })
                                    strelf.receive()
        })
    }

}


@available(iOS 12, OSX 10.14, *)
fileprivate extension NetworkConnection {

    final fileprivate class Extractor {
        final private var store: Data
        final private let capacity: Int
        final private let delimiter: Delimiter

        init(capacity: Int, delimiter: Delimiter) {
            self.capacity = capacity
            self.delimiter = delimiter
            self.store = Data(capacity: capacity)
        }

        private init(capacity: Int, delimiter: Delimiter, data: Data) {
            self.store = data
            self.capacity = capacity
            self.delimiter = delimiter
        }

        final func append(data: Data) -> [Data] {
            var rest: Data = Data()
            let packets = self.extractPackets(self.store, new: data, out: &rest)
            self.store = rest
            return packets
        }

        final func extractPackets(_ data: Data, new: Data, out: inout Data) -> [Data] {
            var current = data
            guard let index = self.delimiterIndex(inData: new) else {
                out = new
                return []
            }

            // found delimiter, extract packet
            let range = new.startIndex..<index
            let rangeData = new.subdata(in: range)
            current.append(rangeData)
            let packet = current

            let restRange = new.index(after: index)..<new.endIndex
            let restData = new.subdata(in: restRange)

            return [packet] + self.extractPackets(Data(capacity: self.capacity),
                                                  new: restData,
                                                  out: &out)
        }

        final private func delimiterIndex(inData data: Data) -> Int? {
            return self.delimiter.data.withUnsafeBytes({ (pointer: UnsafePointer<UInt8>) -> Int? in
                let delimiter = pointer.pointee
                return data.firstIndex(where: { (byte: UInt8) -> Bool in
                    return delimiter == byte
                })
            })
        }
    }
}

#endif
