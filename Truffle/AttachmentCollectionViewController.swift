//
//  AttachmentCollectionViewController.swift
//  ARKitImageDetection
//
//  Created by Ethan Chang on 5/4/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import UIKit
import FirebaseAnalytics

private let reuseIdentifier = "cell"

private let itemsPerRow: CGFloat = 2

private let sectionInsets = UIEdgeInsets(
  top: 50.0,
  left: 10.0,
  bottom: 50.0,
  right: 10.0)


class AttachmentCollectionViewController: UICollectionViewController {

    var attachments = [Attachment]()
//        Attachment(title: "wedding pics", image: "ic_instagram", link: "https://www.trufflear.com/wedding-cards"),
//        Attachment(title: "Schedule", image: "ic_calendar", link: "https://www.zola.com/wedding/phoebeandethan2022"),
//        Attachment(title: "Registry", image: "ic_gallery", link: "https://www.zola.com/wedding/phoebeandethan2022"),


    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes

        self.collectionView.delegate = self
        self.collectionView.register(ArCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView.backgroundColor = .clear
        self.collectionView.showsHorizontalScrollIndicator = false
        self.collectionView.showsVerticalScrollIndicator = false
        // Do any additional setup after loading the view.
    }


    // MARK: UICollectionViewDataSource

    func reloadData() {
        collectionView.reloadData()
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return attachments.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ArCollectionViewCell

        let attachment = attachments[indexPath.row]
        cell.setTitle(attachment.title)
        cell.link = attachment.webUrl
        cell.setImage(attachment.imageUrl)
        cell.setColor(colorHexCode: attachment.colorCode)

        cell.setTouchHandler {link in
            if let url = URL(string: attachment.webUrl) {
                Analytics.logEvent("attachment_link_button_tapped", parameters: [
                    "url": url
                ])
                UIApplication.shared.open(url)
            }
        }
        return cell

    }

}


extension AttachmentCollectionViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // 2
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow

        return CGSize(width: widthPerItem, height: view.frame.height/2.5)
      }

      // 3
      func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
      }

      // 4
      func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
      }
}

