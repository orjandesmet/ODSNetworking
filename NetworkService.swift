//
//  NetworkService.swift
//  ODSNetworking
//
//  Created by Orjan De Smet on 19/05/16.
//  Copyright © 2016 Orjan De Smet. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

public protocol NetworkService {
    
    func parseHeader(data: NSData) -> Int64
    func parseBody(data: NSData)
    func sendPacket(packet: Jsonable, sock: GCDAsyncSocket)
}

public extension NetworkService {
    
    func parseHeader(data: NSData) -> Int64 {
        var headerLength : Int64 = 0
        memcpy(&headerLength, data.bytes, sizeof(Int64))
        
        return headerLength
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