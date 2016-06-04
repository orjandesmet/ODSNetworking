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

public class HostingService : NSObject, NetworkService
{
    var allowMultipleClients: Bool
    var hostingDomain : HostingDomain
    var type: String
    var name: String
    var clientSockets: [GCDAsyncSocket : ODSConnection] = [:]
    var hostingSocket: GCDAsyncSocket?
    var service : NSNetService?
    public var delegate : NetworkingServiceDelegate?
    
    public init(type: String, name: String, hostingDomain: HostingDomain = .Local, allowMultipleClients: Bool = true) {
        self.type = type
        self.name = name
        self.hostingDomain = hostingDomain
        self.allowMultipleClients = allowMultipleClients
    }
    
    public func getSender(sock: GCDAsyncSocket) -> ODSConnection? {
        return clientSockets[sock] // TODO may have errors
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
        for clientSocket in clientSockets.keys
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
    
    // MARK - NSNetService delegate methods
    public func netServiceDidPublish(sender: NSNetService) {
        NSLog("Bonjour Service Published: domain(%@) type(%@) name(%@) port(%i)", sender.domain, sender.type, sender.name, sender.port);
    }
    
    public func netService(sender: NSNetService, didNotPublish errorDict: [String : NSNumber]) {
        NSLog("Failed to Publish Service: domain(%@) type(%@) name(%@) - %@", sender.domain, sender.type, sender.name, errorDict);
    }
    
    // MARK - GDAsyncSocket
    public func socket(sock: GCDAsyncSocket!, didAcceptNewSocket newSocket: GCDAsyncSocket!) {
        NSLog("Accepted New Socket from %@:%hu", newSocket.connectedHost, newSocket.connectedPort);
        
        // Socket
        if (!allowMultipleClients && clientSockets.count > 0)
        {
            clearSocket(clientSockets.keys.first!) // TODO may be wrong
            clientSockets.removeAll()
        }
        let newConnection = ODSConnection(name: newSocket.connectedHost, ip: newSocket.connectedHost)
        clientSockets[newSocket] = newConnection
        
        // Read Data from Socket
        newSocket.readDataToLength(UInt(sizeof(Int64)), withTimeout: -1.0, tag: 0)
        delegate?.socketDidConnect(newConnection)
    }
    
    public func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        if (tag == 0) {
            let bodyLength : Int64 = self.parseHeader(data)
            sock.readDataToLength(UInt(bodyLength), withTimeout: 30.0, tag: 1)
            
        } else if (tag == 1) {
            self.parseBody(data, sock: sock)
            sock.readDataToLength(UInt(sizeof(Int64)), withTimeout: -1.0, tag: 0)
        }
    }
    
    
    public func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        
        if let index = clientSockets.keys.indexOf(sock)
        {
            delegate?.socketDidDisconnect(clientSockets[sock], err: err)
            NSLog("Socket disconnected with Error %@ with User Info %@.", err, err.userInfo)
            clearSocket(clientSockets.keys[index])
            clientSockets.removeAtIndex(index)
        }
    }
    
    
    public func sendPacket(packet: Jsonable, ip: String) {
        if let index = clientSockets.indexOf({$0.1.ip == ip}) {
            let sock = clientSockets.keys[index]
            self.sendPacket(packet, sock: sock)
        }
    }
    
    public func sendPacketToAll(packet: Jsonable) {
        for sock in clientSockets.keys
        {
            self.sendPacket(packet, sock: sock)
        }
    }
    
    public func parseBody(data: NSData, sock: GCDAsyncSocket) {
        delegate?.extractPacketData(data, sender: getSender(sock)!)
    }
}