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

public class HostingService : NSObject, NSNetServiceDelegate, GCDAsyncSocketDelegate, NetworkService
{
    var allowMultipleClients: Bool
    var hostingDomain : HostingDomain
    var type: String
    var name: String
    var clientSockets: [GCDAsyncSocket] = []
    var hostingSocket: GCDAsyncSocket?
    var service : NSNetService?
    public var delegate : HostingServiceDelegate?
    
    public init(type: String, name: String, hostingDomain: HostingDomain = .Local, allowMultipleClients: Bool = true) {
        self.type = type
        self.name = name
        self.hostingDomain = hostingDomain
        self.allowMultipleClients = allowMultipleClients
    }
    
    // Broadcasting
    public func beginBroadcast() {
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
    
    public func endBroadcast() {
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
        if (socket.isConnected)
        {
            NSLog("Cleared socket %@:%hu", socket.connectedHost, socket.connectedPort);            
            socket.disconnect()
        }
        socket.delegate = nil
    }
    
    // NSNetService delegate methods
    public func netServiceDidPublish(sender: NSNetService) {
        NSLog("Bonjour Service Published: domain(%@) type(%@) name(%@) port(%i)", sender.domain, sender.type, sender.name, sender.port);
    }
    
    public func netService(sender: NSNetService, didNotPublish errorDict: [String : NSNumber]) {
        NSLog("Failed to Publish Service: domain(%@) type(%@) name(%@) - %@", sender.domain, sender.type, sender.name, errorDict);
    }
    
    // GDAsyncSocket
    public func socket(sock: GCDAsyncSocket!, didAcceptNewSocket newSocket: GCDAsyncSocket!) {
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
        delegate?.socketConnected(newSocket)
    }
    
    public func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        
        if let index = clientSockets.indexOf(sock)
        {
            delegate?.socketDisconnected(sock)
            NSLog("Socket disconnected with Error %@ with User Info %@.", err, err.userInfo)
            clearSocket(clientSockets[index])
            clientSockets.removeAtIndex(index)
        }
    }
    
    public func sendPacket(packet: Jsonable, index: Int) {
        if index < clientSockets.count
        {
            let sock = clientSockets[index]
            self.sendPacket(packet, sock: sock)
        }
    }
    
    public func parseBody(data: NSData) {
        delegate?.extractPacketData(data)
    }
}