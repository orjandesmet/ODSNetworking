//
//  ExamplePacket.swift
//  ODSNetworking
//
//  Created by Orjan De Smet on 27/04/16.
//  Copyright © 2016 Orjan De Smet. All rights reserved.
//

import Foundation

class ExamplePacket : Jsonable {
 
    var type = "ExamplePacket"
    var version = 1
    var data = ""
    
    var dict: [String : String] {
        var ret = [String: String]()
        ret["data"] = data
        return ret
    }
    
    required init() {}
    
    convenience init(data: String)
    {
        self.init()
        self.data = data
    }
    
    internal func buildFromDict(dict: [String : String]) {
        if let data = dict["data"] {
            self.data = data
        }
    }
}