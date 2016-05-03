//
//  BrowserServiceDelegate.swift
//  ODSNetworking
//
//  Created by Orjan De Smet on 3/05/16.
//  Copyright © 2016 Orjan De Smet. All rights reserved.
//

import Foundation

public protocol BrowserServiceDelegate {
    func updateServices(services: [NSNetService])
    func extractPacketData(data: NSData)
}