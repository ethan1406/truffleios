//
//  FileManagerExt.swift
//  ARKitImageDetection
//
//  Created by Ethan Chang on 5/8/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation

extension FileManager {
    func clearTmpVideos() {
        do {
            let tmpDirURL = FileManager.default.temporaryDirectory
            let tmpDirectory = try contentsOfDirectory(atPath: tmpDirURL.path)
            try tmpDirectory.forEach { file in
                if (file.hasSuffix(".mov")) {
                    let fileUrl = tmpDirURL.appendingPathComponent(file)
                    try removeItem(atPath: fileUrl.path)
                }
            }
        } catch {
           //catch the error somehow
        }
    }
}
