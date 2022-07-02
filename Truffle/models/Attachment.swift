//
//  Attachment.swift
//  ARKitImageDetection
//
//  Created by Ethan Chang on 5/4/22.
//  Copyright © 2022 Apple. All rights reserved.
//

struct Attachment {
    let title: String
    let imageUrl: String
    let colorCode: String
    let webUrl: String

    init(
        title: String,
        imageUrl: String,
        colorCode: String,
        webUrl: String
    ) {
        self.imageUrl = imageUrl
        self.title = title
        self.colorCode = colorCode
        self.webUrl = webUrl
    }
}
