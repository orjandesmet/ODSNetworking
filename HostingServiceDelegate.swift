//
//  HostingServiceDelegate.swift
//  ODSNetworking
//
//  Created by Orjan De Smet on 3/05/16.
//  Copyright © 2016 Orjan De Smet. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

public protocol HostingServiceDelegate {
    func socketConnected(sock: GCDAsyncSocket)
    func socketDisconnected(sock: GCDAsyncSocket)
    func extractPacketData(data: NSData)
}