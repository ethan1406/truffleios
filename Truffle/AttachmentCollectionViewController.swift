//
//  AttachmentCollectionViewController.swift
//  ARKitImageDetection
//
//  Created by Ethan Chang on 5/4/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import UIKit

private let reuseIdentifier = "cell"

private let itemsPerRow: CGFloat = 2

private let sectionInsets = UIEdgeInsets(
  top: 50.0,
  left: 20.0,
  bottom: 50.0,
  right: 20.0)

private let attachments = [
    Attachment(title: "wedding pics", image: "ic_calendar", link: "https://www.trufflear.com/"),
    Attachment(title: "Schedule", image: "ic_gallery", link: "https://www.trufflear.com/"),
    Attachment(title: "Registry", image: "ic_instagram", link: "https://www.trufflear.com/"),
    Attachment(title: "testing 3", image: "", link: "https://www.trufflear.com/wedding-cards"),
    Attachment(title: "testing 4", image: "", link: "https://www.trufflear.com/wedding-cards"),
//    Attachment(title: "testing 5", image: "", link: "https://www.trufflear.com/wedding-cards"),
//    Attachment(title: "testing 6", image: "", link: "https://www.trufflear.com/wedding-cards"),
//    Attachment(title: "testing 7", image: "", link: "https://www.trufflear.com/wedding-cards"),
//    Attachment(title: "testing 8", image: "", link: "https://www.trufflear.com/wedding-cards"),
]

class AttachmentCollectionViewController: UICollectionViewController {


    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes

        self.collectionView.delegate = self
        self.collectionView!.register(ArCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView.backgroundColor = .clear
        self.collectionView.showsHorizontalScrollIndicator = false
        // Do any additional setup after loading the view.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

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
        cell.link = attachment.link
        cell.setImage(attachment.image)
        
        cell.setTouchHandler {link in
            print("selected")
            print(indexPath)
            if let url = URL(string: attachment.link) {
                UIApplication.shared.open(url)
            }
        }
        return cell

    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}


extension AttachmentCollectionViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // 2
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow

          return CGSize(width: widthPerItem, height: view.frame.height)
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
