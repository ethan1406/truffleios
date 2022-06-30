//
//  Attachment.swift
//  ARKitImageDetection
//
//  Created by Ethan Chang on 5/4/22.
//  Copyright © 2022 Apple. All rights reserved.
//

struct Attachment {
    let title: String
    let image: String
    let link: String
    let colorCode: String
    let webUrl: String

    init(
        title: String,
        image: String,
        link: String,
        colorCode: String,
        webUrl: String
    ) {
        self.image = image
        self.title = title
        self.link = link
        self.colorCode = colorCode
        self.webUrl = webUrl
    }
}
