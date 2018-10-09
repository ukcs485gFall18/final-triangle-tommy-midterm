//
//  Song+ImageLoad.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/2/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import UIKit

extension Song {
    
    func loadSongImage(completion: @escaping ((UIImage?) -> (Void))) {
        // Changed Image loading code
        if self.coverArtURL == nil {
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            let coverImageData = NSData(contentsOf: self.coverArtURL!)
            let coverImage = UIImage(data: coverImageData! as Data)
            DispatchQueue.main.async {
                completion(coverImage)
            }
        }
    }
}
