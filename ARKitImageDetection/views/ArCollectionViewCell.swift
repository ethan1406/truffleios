//
//  ArButton.swift
//  ARKitImageDetection
//
//  Created by Ethan Chang on 5/1/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import UIKit

class ArCollectionViewCell: UICollectionViewCell {


    let linkButton: UIButton = {
        var configuration = UIButton.Configuration.filled()

        configuration.image = UIImage(named: "restart")
        configuration.titlePadding = 20
        configuration.imagePadding = 20
        configuration.cornerStyle = .capsule
        configuration.background.backgroundColor = UIColor(named: "PrimaryColor")

        let button = UIButton(configuration: configuration, primaryAction: UIAction(handler: { _ in 
            print("testing 123")
        }))

        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        //button.isUserInteractionEnabled = false
        return button
    }()


    func setTitle(_ title: String) {
        var container = AttributeContainer()
        container.font = UIFont.boldSystemFont(ofSize: 26)

        linkButton.configuration?.attributedTitle = AttributedString(title, attributes: container)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addViews()
    }

    private func addViews() {
        contentView.addSubview(linkButton)

        linkButton.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        linkButton.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        linkButton.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        linkButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
