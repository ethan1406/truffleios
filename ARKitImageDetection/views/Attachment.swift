//
//  City.swift
//  ARKitImageDetection
//
//  Created by Ethan Chang on 5/4/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation


struct Attachment {
    let title: String
    let image: String
    let link: String

    init(title: String, image: String, link: String){
        self.image = image
        self.title = title
        self.link = link
    }
}
