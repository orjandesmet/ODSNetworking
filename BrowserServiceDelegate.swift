//
//  BrowserServiceDelegate.swift
//  ODSNetworking
//
//  Created by Orjan De Smet on 3/05/16.
//  Copyright © 2016 Orjan De Smet. All rights reserved.
//

import Foundation

@objc public protocol BrowserServiceDelegate {
    optional func browsingDidEnd()
    optional func browsingDidBegin()
    func didUpdateServices(services: [NSNetService])
}