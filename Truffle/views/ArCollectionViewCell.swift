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

    func setImage(_ imageUrl: String) {
        guard let url = URL(string: imageUrl) else {
            return
        }

        let resource = ImageResource(downloadURL: url)

        KingfisherManager.shared.retrieveImage(with: resource) { result in
            switch result {
            case .success(let uiImage):
                guard let cgImage = uiImage.image.cgImage else { return }
                let scaledImage = UIImage(cgImage: cgImage, scale: 2, orientation: .up)
                self.linkButton.configuration?.image = scaledImage
            case .failure(_):
                break
            }
        }
    }

    func setColor(colorHexCode: String) {
        linkButton.configurationUpdateHandler = createLinkButtonHandler(colorHexCode)
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

    private func createLinkButtonHandler(_ colorHexCode: String) -> UIButton.ConfigurationUpdateHandler {
        let baseColor = UIColor(hex: colorHexCode)
        let handler: UIButton.ConfigurationUpdateHandler = { button in
            switch button.state {
            case .normal:
                button.configuration?.background.backgroundColor = baseColor
            case [.highlighted]:
                button.configuration?.background.backgroundColor = baseColor.withAlphaComponent(0.9)
            case .selected:
                button.configuration?.background.backgroundColor = baseColor.withAlphaComponent(0.9)
            case [.selected, .highlighted]:
                button.configuration?.background.backgroundColor = baseColor.withAlphaComponent(0.9)
            case .disabled:
                button.configuration?.background.backgroundColor = baseColor.withAlphaComponent(0.9)
            default:
                button.configuration?.background.backgroundColor = baseColor

            }
        }

        return handler
    }
}

extension UIColor {

    convenience init(hex: String, alpha: CGFloat = 1.0) {
        let hexString: String = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let scanner = Scanner(string: hexString)
        if (hexString.hasPrefix("#")) {
            scanner.currentIndex = hexString.index(after: hex.startIndex)
        }
        var color: UInt64 = 0
        scanner.scanHexInt64(&color)
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    func toHexString() -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        return String(format:"#%06x", rgb)
    }
}
