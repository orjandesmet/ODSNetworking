//
//  ClientServiceDelegate.swift
//  ODSNetworking
//
//  Created by Orjan De Smet on 19/05/16.
//  Copyright © 2016 Orjan De Smet. All rights reserved.
//

import Foundation

@objc public protocol ClientServiceDelegate {
    func extractPacketData(data: NSData)
    optional func didConnectToHost(host: String)
    optional func didDisconnect(err: NSError)
}
