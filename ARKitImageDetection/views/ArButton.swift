//
//  ArButton.swift
//  ARKitImageDetection
//
//  Created by Ethan Chang on 5/1/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import UIKit

class ArButton: UIButton{

    override init(frame: CGRect) {

        super.init(frame: frame)

        self.addTarget(self, action:  #selector(objectTapped(_:)), for: .touchUpInside)

        self.backgroundColor = .red

    }


    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Detects Which Object Was Tapped
    ///
    /// - Parameter sender: UIButton
    @objc func objectTapped(_ sender: UIButton){

        print("Object With Tag \(tag)")

    }

}
