//
//  ArButton.swift
//  ARKitImageDetection
//
//  Created by Ethan Chang on 5/1/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import Kingfisher
import UIKit

class ArCollectionViewCell: UICollectionViewCell {


    var touchHandler: (String) -> Void = {_ in }

    var link: String? = nil

    private let linkButton: UIButton = {

        let button = UIButton(configuration: createLinkButtonConfiguration(), primaryAction: nil)
        button.configurationUpdateHandler = createLinkButtonHandler()

        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        //button.isUserInteractionEnabled = true
        return button
    }()


    func setTitle(_ title: String) {
        var container = AttributeContainer()
        container.font = UIFont.boldSystemFont(ofSize: 11)

        linkButton.configuration?.attributedTitle = AttributedString(title, attributes: container)
    }

    func setTouchHandler(_ handler: @escaping (String) -> Void) {
        touchHandler = handler

        linkButton.addTarget(self, action: #selector(onButtonTap), for: .touchUpInside)

    }

    func setImage(_ imageName: String) {
        let url = URL(string: "https://truffle.s3.us-west-1.amazonaws.com/staging/linkButtonIcons/ic_gallery.png")

        linkButton.kf.setImage(with: url, for: .normal)

        //linkButton.configuration?.image
        //linkButton.configuration?.image = UIImage(named: imageName)
    }


    @objc private func onButtonTap() {
        if let webLink = link {
            touchHandler(webLink)
        }
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

    private static func createLinkButtonConfiguration() -> UIButton.Configuration {
        var configuration = UIButton.Configuration.filled()
        configuration.titlePadding = 5
        configuration.imagePadding = 5
        configuration.cornerStyle = .capsule

        return configuration
    }

    private static func createLinkButtonHandler() -> UIButton.ConfigurationUpdateHandler {
        let baseColor = UIColor(named: "PrimaryColor")
        let handler: UIButton.ConfigurationUpdateHandler = { button in
            switch button.state {
            case .normal:
                button.configuration?.background.backgroundColor = baseColor
            case [.highlighted]:
                button.configuration?.background.backgroundColor = baseColor?.withAlphaComponent(0.9)
            case .selected:
                button.configuration?.background.backgroundColor = baseColor?.withAlphaComponent(0.9)
            case [.selected, .highlighted]:
                button.configuration?.background.backgroundColor = baseColor?.withAlphaComponent(0.9)
            case .disabled:
                button.configuration?.background.backgroundColor = baseColor?.withAlphaComponent(0.9)
            default:
                button.configuration?.background.backgroundColor = baseColor

            }
        }

        return handler
    }
}
