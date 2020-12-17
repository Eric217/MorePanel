//
//  Coding.swift
//  iOS-FastTest
//
//  Created by Eric on 2020/1/9.
//  Copyright © 2020 Eric. All rights reserved.
//

import Foundation
 

class MyOBJ: NSObject  {
    weak var vs: NSString?
    
    final var name: String!
    final func t() {
        
        
    }
    
    @objc internal func test() {
        print("ok")
    }
    
}

@objc protocol Prot: AnyObject {
    var v3: NSString? {get }
    @objc optional func test()
}

class MyOBJ2 : MyOBJ, Prot {
    var v3: NSString? {
        
        return ""
    }
    
    
}
