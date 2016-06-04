//
//  ClientService.swift
//  ODSNetworking
//
//  Created by Orjan De Smet on 19/05/16.
//  Copyright © 2016 Orjan De Smet. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

public class ClientService : NSObject, NSNetServiceDelegate, NetworkService {
    var hostSocket: GCDAsyncSocket?
    var hostConnection: ODSConnection?
    public var delegate : NetworkingServiceDelegate?
    var attempts = 0
    
    public func getSender(sock: GCDAsyncSocket) -> ODSConnection? {
        return hostConnection
    }
    
    public func connectToService(service: NSNetService) {
        attempts += 1
        if (attempts >= 100)
        {
            NSLog("Too many connection attempts")
            attempts = 0
        }
        else
        {
            hostConnection = ODSConnection(name: service.name, ip: "")
            service.delegate = self
            service.resolveWithTimeout(30.0) // It's impossible to connect during this timeout, because it's still resolving. Use NSNetService.stop() to stop resolving when attempting a connection
        }
    }
    
    public func disConnect(err: NSError?)
    {
        if (hostSocket != nil && hostSocket!.isConnected)
        {
            hostSocket!.disconnect()
            hostSocket!.delegate = nil
            hostSocket = nil
        }
        delegate?.socketDidDisconnect(hostConnection, err: err)
        hostConnection = nil
    }
    
    // MARK: - Service
    public func netService(sender: NSNetService, didNotResolve errorDict: [String : NSNumber]) {
        sender.delegate = nil
        
        // retry
        connectToService(sender)
    }
    
    public func netServiceDidResolveAddress(sender: NSNetService) {
        // Connect With Service
        if (attemptConnectionWithService(sender)) {
            NSLog("Connecting with Service: domain(%@) type(%@) name(%@) port(%i)", sender.domain, sender.type, sender.name, sender.port);
            sender.stop()
        } else {
            NSLog("Unable to Connect with Service: domain(%@) type(%@) name(%@) port(%i)", sender.domain, sender.type, sender.name, sender.port);
        }
    }
    
    private func attemptConnectionWithService(service: NSNetService) -> Bool {
        var isConnecting = false
        
        // Copy Service Addresses
        if let addresses = service.addresses {
            if (hostSocket != nil && hostSocket!.isConnected
                && !addresses.contains(hostSocket!.connectedAddress)) {
                hostSocket!.disconnect()
                hostSocket!.delegate = nil
                hostSocket = nil
            }
            
            if (hostSocket == nil || !hostSocket!.isConnected) {
                // Initialize Socket
                hostSocket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
                
                // Connect
                for address in addresses {
                    do {
                        try hostSocket!.connectToAddress(address)
                        isConnecting = true
                        break
                    } catch let error as NSError {
                        NSLog("Unable to connect to address. Error %@ with user info %@.", error, error.userInfo)
                    }
                }
                
            } else {
                isConnecting = hostSocket!.isConnected
            }
        }
        
        attempts = 0
        return isConnecting
    }
    
    // MARK - GCDAsyncSocket
    
    public func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        if (tag == 0) {
            let bodyLength : Int64 = self.parseHeader(data)
            sock.readDataToLength(UInt(bodyLength), withTimeout: 30.0, tag: 1)
            
        } else if (tag == 1) {
            self.parseBody(data, sock: sock)
            sock.readDataToLength(UInt(sizeof(Int64)), withTimeout: -1.0, tag: 0)
        }
    }
    
    public func socket(sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
        NSLog("Socket Did Connect to Host: %@ Port: %hu", host, port);
        if (hostConnection != nil)
        {
            hostConnection!.ip = sock.connectedHost
        }
        
        // Start Reading
        hostSocket!.readDataToLength(UInt(sizeof(Int64)), withTimeout: -1.0, tag: 0)
        
        delegate?.socketDidConnect(hostConnection!)
    }
    
    public func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        
        if (sock == hostSocket)
        {
            NSLog("Socket Did Disconnect with Error %@ with User Info %@.", err, err.userInfo);
            
            disConnect(err)
        }
        
    }
    
    public func sendPacket(packet: Jsonable)
    {
        if let hostSocket = hostSocket
        {
            self.sendPacket(packet, sock: hostSocket)
        }
    }
    
    public func sendPacket(packet: Jsonable, ip: String) {
        sendPacket(packet)
    }
}
