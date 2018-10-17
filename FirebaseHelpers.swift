//
//  FirebaseHelpers.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/16/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import UIKit

extension Song {
    
    func toDict() -> [String: Any?] {
        let anyDict = ["Title": self.title,
                       "Artist": self.artist]
        return anyDict
    }
}

