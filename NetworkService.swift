//
//  NetworkService.swift
//  ODSNetworking
//
//  Created by Orjan De Smet on 19/05/16.
//  Copyright © 2016 Orjan De Smet. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

public protocol NetworkService : NSNetServiceDelegate, GCDAsyncSocketDelegate {
    var delegate : NetworkingServiceDelegate? {get set}
    
    func parseHeader(data: NSData) -> Int64
    func parseBody(data: NSData, sock: GCDAsyncSocket)
    func sendPacket(packet: Jsonable, ip: String)
    func sendPacket(packet: Jsonable, sock: GCDAsyncSocket)
    func getSender(sock: GCDAsyncSocket) -> ODSConnection?
}

public extension NetworkService {
    
    func parseHeader(data: NSData) -> Int64 {
        var headerLength : Int64 = 0
        memcpy(&headerLength, data.bytes, sizeof(Int64))
        
        return headerLength
    }
    
    
    public func parseBody(data: NSData, sock: GCDAsyncSocket) {
        if let sender = getSender(sock)
        {
            delegate?.extractPacketData(data, sender: sender)
        }
    }
    
    public func sendPacket(packet: Jsonable, sock: GCDAsyncSocket) {
        let packetData = packet.json()
        
        // Initialize Buffer
        let buffer = NSMutableData()
        
        // Fill Buffer
        var headerLength : Int64 = Int64(packetData.length)
        
        buffer.appendBytes(&headerLength, length: sizeof(Int64))
        buffer.appendBytes(packetData.bytes, length: packetData.length)
        
        // Write Buffer
        sock.writeData(buffer, withTimeout: -1.0, tag: 0)
    }
}