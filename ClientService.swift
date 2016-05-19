//
//  ClientService.swift
//  ODSNetworking
//
//  Created by Orjan De Smet on 19/05/16.
//  Copyright © 2016 Orjan De Smet. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

public class ClientService : NSObject, NSNetServiceDelegate, BrowserServiceDelegate, NetworkService {
    
    var hostSocket: GCDAsyncSocket?
    var type : String
    var name : String
    public var browserService: BrowserService?
    public var delegate : ClientServiceDelegate?
    
    public init(type: String, name: String)
    {
        self.type = type
        self.name = name
        super.init()
    }
    
    public func browsingDidEnd() {
        
        if (hostSocket != nil && hostSocket!.isConnected)
        {
            hostSocket!.disconnect()
            hostSocket!.delegate = nil
            hostSocket = nil
        }
    }
    
    public func connectToService(service: NSNetService) {
        service.delegate = self
        service.resolveWithTimeout(30.0)
    }
    
    public func didUpdateServices(services: [NSNetService]) {
        delegate?.updateServices(services)
    }
    
    public func beginBrowsing() {
        browserService = BrowserService(type: type, name: name)
        if let browserService = browserService
        {
            browserService.delegate = self
            browserService.beginBrowsing()
        }
    }
    
    public func endBrowsing() {
        if let browserService = browserService
        {
            browserService.endBrowsing()
            browserService.delegate = nil
        }
        browserService = nil
    }
    
    
    // MARK: - Service
    public func netService(sender: NSNetService, didNotResolve errorDict: [String : NSNumber]) {
        sender.delegate = nil
    }
    
    public func netServiceDidResolveAddress(sender: NSNetService) {
        // Connect With Service
        if (attemptConnectionWithService(sender)) {
            NSLog("Connecting with Service: domain(%@) type(%@) name(%@) port(%i)", sender.domain, sender.type, sender.name, sender.port);
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
        
        return isConnecting
    }
    
    public func socket(sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
        NSLog("Socket Did Connect to Host: %@ Port: %hu", host, port);
        
        // Start Reading
        hostSocket!.readDataToLength(UInt(sizeof(Int64)), withTimeout: -1.0, tag: 0)
    }
    
    public func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        
        if (sock == hostSocket)
        {
            NSLog("Socket Did Disconnect with Error %@ with User Info %@.", err, err.userInfo);
            
            hostSocket!.delegate = nil
            hostSocket = nil
        }
        
    }
    
    public func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        if (tag == 0) {
            let bodyLength : Int64 = self.parseHeader(data)
            hostSocket!.readDataToLength(UInt(bodyLength), withTimeout: -1.0, tag: 1)
            
        } else if (tag == 1) {
            self.parseBody(data)
            hostSocket!.readDataToLength(UInt(sizeof(Int64)), withTimeout: 30.0, tag: 0)
        }
    }
    
    
    public func parseBody(data: NSData) {
        delegate?.extractPacketData(data)
    }
    
    public func sendPacket(packet: Jsonable)
    {
        if let hostSocket = hostSocket
        {
            self.sendPacket(packet, sock: hostSocket)
        }
    }
}
