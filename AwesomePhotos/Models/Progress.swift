//
//  Progress.swift
//  AwesomePhotos
//
//  Created by Rasmus Petersen on 14/05/2019.
//

import UIKit
class Progress {
    
    var image : UIImage
    var label : String
    var progress : Float
    
    init( image: UIImage, label : String, progress : Float) {
        self.image = image
        self.label = label
        self.progress = progress
    }
}
