//
//  HostingService.swift
//  ODSNetworking
//
//  Created by Orjan De Smet on 27/04/16.
//  Copyright © 2016 Orjan De Smet. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

public enum HostingDomain : String {
    case Local = "local."
}

public protocol HostingService : NSNetServiceDelegate, GCDAsyncSocketDelegate
{
    var allowMultipleClients: Bool {get set}
    var hostingDomain : HostingDomain {get set}
    var type: String {get set}
    var name: String {get set}
    var clientSockets: [GCDAsyncSocket] {get set}
    var hostingSocket: GCDAsyncSocket? {get set}
    var service : NSNetService? {get set}
    init(type: String, name: String)
    func beginBroadcast()
    func endBroadcast()
}

public extension HostingService {
    
    // Broadcasting
    func beginBroadcast() {
        // Initialize GCDAsyncSocket
        hostingSocket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
        
        if let socket = hostingSocket {
            // Start Listening for Incoming Connections
            do {
                try hostingSocket!.acceptOnPort(0)
                
                service = NSNetService(domain: hostingDomain.rawValue, type: type, name: name, port: Int32(socket.localPort))
                
                if let service = service {
                    service.delegate = self
                    service.publish()
                }
            }
            catch let error as NSError
            {
                NSLog("Unable to create socket. Error %@ with user info %@.", error, error.userInfo)
            }
        }
    }
    
    func endBroadcast() {
        // Disconnect with all devices
        for clientSocket in clientSockets
        {
            clearSocket(clientSocket)
        }
        clientSockets.removeAll()
        
        // Cancel hosting
        if let sock = hostingSocket
        {
            clearSocket(sock)
        }
        hostingSocket = nil
    }
    
    func clearSocket(socket: GCDAsyncSocket)
    {
        NSLog("Cleared socket %@:%hu", socket.connectedHost, socket.connectedPort);
        if (socket.isConnected)
        {
            socket.disconnect()
        }
        socket.delegate = nil
    }
    
    // NSNetService delegate methods
    func netServiceDidPublish(sender: NSNetService) {
        NSLog("Bonjour Service Published: domain(%@) type(%@) name(%@) port(%i)", sender.domain, sender.type, sender.name, sender.port);
    }
    
    func netService(sender: NSNetService, didNotPublish errorDict: [String : NSNumber]) {
        NSLog("Failed to Publish Service: domain(%@) type(%@) name(%@) - %@", sender.domain, sender.type, sender.name, errorDict);
    }
    
    // GDAsyncSocket
    func socket(sock: GCDAsyncSocket!, didAcceptNewSocket newSocket: GCDAsyncSocket!) {
        NSLog("Accepted New Socket from %@:%hu", newSocket.connectedHost, newSocket.connectedPort);
        
        // Socket 
        if (!allowMultipleClients && clientSockets.count > 0)
        {
            clearSocket(clientSockets[0])
            clientSockets.removeAtIndex(0)
        }
        clientSockets.append(newSocket)
        
        // Read Data from Socket
        newSocket.readDataToLength(UInt(sizeof(Int64)), withTimeout: -1.0, tag: 0)
    }
    
    func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        
        if let index = clientSockets.indexOf(sock)
        {
            NSLog("Socket disconnected with Error %@ with User Info %@.", err, err.userInfo)
            clearSocket(clientSockets[index])
            clientSockets.removeAtIndex(index)
        }
    }
    
    func sendPacket(packet: Jsonable, index: Int) {
        // Encode Packet Data
        let packetData = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWithMutableData: packetData)
        
        archiver.encodeObject(packet.json(), forKey: "packet")
        archiver.finishEncoding()
        
        // Initialize Buffer
        let buffer = NSMutableData()
        
        // Fill Buffer
        var headerLength : Int64 = Int64(packetData.length)
        
        buffer.appendBytes(&headerLength, length: sizeof(Int64))
        buffer.appendBytes(packetData.bytes, length: packetData.length)
        
        // Write Buffer
        if index < clientSockets.count
        {
            let sock = clientSockets[index]
            sock.writeData(buffer, withTimeout: -1.0, tag: 0)
        }
    }
}