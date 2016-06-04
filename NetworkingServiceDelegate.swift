//
//  NetworkingServiceDelegate.swift
//  ODSNetworking
//
//  Created by Orjan De Smet on 4/06/16.
//  Copyright © 2016 Orjan De Smet. All rights reserved.
//

import Foundation

public protocol NetworkingServiceDelegate {
    func extractPacketData(data: NSData, sender: ODSConnection)
    func socketDidConnect(sender: ODSConnection)
    func socketDidDisconnect(sender: ODSConnection?, err: NSError?)
}