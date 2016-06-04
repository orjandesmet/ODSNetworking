//
//  HostingController.swift
//  ODSNetworking
//
//  Created by Orjan De Smet on 31/05/16.
//  Copyright © 2016 Orjan De Smet. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

public class HostingController: NSObject {
    public static let sharedInstance = HostingController()
    private override init() {}

    private var hostingService : HostingService?
    
    public func beginHosting(type: String, name: String, hostingDomain: HostingDomain, allowMultipleClients: Bool, delegate: HostingServiceDelegate)
    {
        endHosting()
        hostingService = HostingService(type: type, name: name, hostingDomain: hostingDomain, allowMultipleClients: allowMultipleClients)
        setHostingDelegate(delegate)
        hostingService?.beginBroadcast()
    }
    
    public func endHosting()
    {
        if let hostingService = hostingService
        {
            hostingService.endBroadcast()
            hostingService.delegate = nil
        }
        hostingService = nil
    }
    
    public func setHostingDelegate(delegate: HostingServiceDelegate)
    {
        hostingService?.delegate = delegate
    }
    
    public func sendPacket(packet: Jsonable, ip: String)
    {
        hostingService?.sendPacket(packet, ip: ip);
    }
    
    public func sendPacketToAll(packet: Jsonable)
    {
        hostingService?.sendPacketToAll(packet)
    }
}
