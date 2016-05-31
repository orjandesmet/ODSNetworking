//
//  ClientController.swift
//  ODSNetworking
//
//  Created by Orjan De Smet on 31/05/16.
//  Copyright © 2016 Orjan De Smet. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

public class ClientController: NSObject {
    public static let sharedInstance = ClientController()
    private override init() {}
    
    private var clientService = ClientService()
    private var browserService: BrowserService?
    
    // MARK: Browser
    public func beginBrowsing(type: String, name: String, delegate: BrowserServiceDelegate)
    {
        endBrowsing()
        browserService = BrowserService(type: type, name: name)
        setBrowserDelegate(delegate)
        browserService?.beginBrowsing()
    }
    
    public func endBrowsing() {
        if let browserService = browserService
        {
            browserService.endBrowsing()
            browserService.delegate = nil
        }
        browserService = nil
    }
    
    public func setBrowserDelegate(delegate: BrowserServiceDelegate)
    {
        browserService?.delegate = delegate
    }
    
    // MARK: Client
    public func connectToService(service: NSNetService, delegate: ClientServiceDelegate?) {
        setClientDelegate(delegate)
        clientService.connectToService(service)
        endBrowsing()
    }
    
    public func sendPacket(packet: Jsonable)
    {
        clientService.sendPacket(packet)
    }
    
    public func setClientDelegate(delegate: ClientServiceDelegate?)
    {
        if (delegate != nil)
        {
            clientService.delegate = delegate
        }
    }
}
