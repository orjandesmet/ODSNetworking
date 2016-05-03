//
//  Jsonable.swift
//  ODSNetworking
//
//  Created by Orjan De Smet on 27/04/16.
//  Copyright © 2016 Orjan De Smet. All rights reserved.
//

import Foundation

public protocol Jsonable
{
    var type : String {get set}
    var version : Int {get set}
    var dict : [String : String] { get }
    mutating func buildFromDict(dict: [String: String])
    func json() -> NSData
    init(jsonData: NSData)
    init()
}

public extension Jsonable
{
    final var dictionary : [String: String] {
        var ret = self.dict
        ret["type"] = type
        ret["version"] = "\(version)"
        return ret
    }
    
    public func json() -> NSData {
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(self.dictionary, options: NSJSONWritingOptions.PrettyPrinted)
            return jsonData
        } catch let error as NSError {
            print(error)
        }
        
        return NSData();
    }
    
    public init(jsonData: NSData) {
        var dict = [String: String]()
        do {
            let decoded = try NSJSONSerialization.JSONObjectWithData(jsonData, options: [])
            dict = decoded as! [String: String]
        } catch let error as NSError {
            print(error)
        }
        self.init(dictionary: dict)
    }
    
    init(dictionary: [String: String]) {
        
        self.init()
        
        if let type = dictionary["type"] {
            self.type = type
        }
        
        guard let version = dictionary["version"] else {
            self.version = -1
            return
        }
        guard let versionNum = Int(version) else {
            self.version = -1
            return
        }
        
        self.version = versionNum
        self.buildFromDict(dictionary)
    }
}