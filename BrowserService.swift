//
//  BrowserService.swift
//  ODSNetworking
//
//  Created by Orjan De Smet on 30/04/16.
//  Copyright © 2016 Orjan De Smet. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

public class BrowserService : NSObject, NSNetServiceDelegate, NSNetServiceBrowserDelegate, GCDAsyncSocketDelegate {
    
    //var hostingDomain : HostingDomain
    var type : String
    var name : String
    var hostSocket: GCDAsyncSocket?
    var serviceBrowser : NSNetServiceBrowser?
    var services: [NSNetService] = []
    public var delegate : BrowserServiceDelegate?
    
    public init(type: String, name: String){//, hostingDomain: HostingDomain = .Local) {
        self.type = type
        self.name = name
        //self.hostingDomain = hostingDomain
    }
    
    public func beginBrowsing() {
        if (!services.isEmpty) {
            services.removeAll()
        }
        
        // Initialize Service Browser
        serviceBrowser = NSNetServiceBrowser()
        
        // Configure Service Browser
        serviceBrowser!.delegate = self
        serviceBrowser!.searchForServicesOfType(type, inDomain: "local.")
    }
    
    public func endBrowsing() {
        if let serviceBrowser = serviceBrowser {
            serviceBrowser.stop()
            serviceBrowser.delegate = nil
        }
        serviceBrowser = nil
        
        
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
    
    // MARK: - Browser
    public func netServiceBrowser(browser: NSNetServiceBrowser, didFindService service: NSNetService, moreComing: Bool) {
        services.append(service)
        
        if (!moreComing)
        {
            // Sort Services
            services.sortInPlace({ (lh: NSNetService, rh: NSNetService) -> Bool in
                return lh.name < rh.name
            })
            
            delegate?.updateServices(services)
        }
    }
    
    public func netServiceBrowser(browser: NSNetServiceBrowser, didRemoveService service: NSNetService, moreComing: Bool) {
        if let index = services.indexOf(service) {
            services.removeAtIndex(index)
        }
        
        if (!moreComing)
        {
            delegate?.updateServices(services)
        }
    }
    
    public func netServiceBrowserDidStopSearch(browser: NSNetServiceBrowser) {
        endBrowsing()
    }
    
    public func netServiceBrowser(browser: NSNetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        endBrowsing()
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
    
    func parseHeader(data: NSData) -> Int64 {
        var headerLength : Int64 = 0
        memcpy(&headerLength, data.bytes, sizeof(Int64))
        
        return headerLength
    }
    
    func parseBody(data: NSData) {
        /*let unarchiver = NSKeyedUnarchiver(forReadingWithData: data)
        let packetData = unarchiver.decodeObjectForKey("packet") as! NSData
        
        unarchiver.finishDecoding()*/
        
        delegate?.extractPacketData(data)
    }
}