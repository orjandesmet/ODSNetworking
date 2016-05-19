//
//  BrowserService.swift
//  ODSNetworking
//
//  Created by Orjan De Smet on 30/04/16.
//  Copyright © 2016 Orjan De Smet. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

public class BrowserService : NSObject, NSNetServiceBrowserDelegate, GCDAsyncSocketDelegate {
    
    //var hostingDomain : HostingDomain
    var type : String
    var name : String
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
            delegate?.didUpdateServices(services)
        }
        
        // Initialize Service Browser
        serviceBrowser = NSNetServiceBrowser()
        
        // Configure Service Browser
        serviceBrowser!.delegate = self
        serviceBrowser!.searchForServicesOfType(type, inDomain: "local.")
        delegate?.browsingDidBegin?()
    }
    
    public func endBrowsing() {
        if let serviceBrowser = serviceBrowser {
            serviceBrowser.stop()
            serviceBrowser.delegate = nil
        }
        serviceBrowser = nil
        delegate?.browsingDidEnd?();
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
            
            delegate?.didUpdateServices(services)
        }
    }
    
    public func netServiceBrowser(browser: NSNetServiceBrowser, didRemoveService service: NSNetService, moreComing: Bool) {
        if let index = services.indexOf(service) {
            services.removeAtIndex(index)
        }
        
        if (!moreComing)
        {
            delegate?.didUpdateServices(services)
        }
    }
    
    public func netServiceBrowserDidStopSearch(browser: NSNetServiceBrowser) {
        endBrowsing()
    }
    
    public func netServiceBrowser(browser: NSNetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        endBrowsing()
    }
    
    
}