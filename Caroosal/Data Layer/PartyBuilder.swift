//
//  PartyBuilder.swift
//  Caroosal
//
//  Created by Tommy Deeter on 12/10/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import Foundation
import FirebaseDatabase

// This is a referenced from the SongBuilder class, but for Party properties
// an abstracted way of constructing Party objects: checks to make sure values are not nil safely
class PartyBuilder: NSObject {
    
    private var name: String?
    private var password: String?
    private var host: String?
    private var ref: DatabaseReference?
    
    func build() -> Party? {
        guard let name = name,
            let password = password,
            let host = host else {
                return nil
        }
        
        return Party(name: name, password: password, host: host, ref: ref)
    }
    
    func with(name: String?) -> Self {
        self.name = name
        return self
    }
    
    func with(password: String?) -> Self {
        self.password = password
        return self
    }
    
    func with(host: String?) -> Self {
        self.host = host
        return self
    }
    
    func with(databaseRef: DatabaseReference?) -> Self {
        guard let _ = databaseRef else {
            return self
        }
        self.ref = databaseRef
        return self
    }
}
