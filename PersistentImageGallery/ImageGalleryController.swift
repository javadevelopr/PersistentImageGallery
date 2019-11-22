//
//  ImageGalleryController.swift
//  ImageGallery
//
//  Created by Sam Olof on 10/4/19.
//  Copyright © 2019 Sam Olof. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Image Cell"

class ImageGalleryController: UICollectionViewController {

	var document: GalleryDocument?
		
	var gallery: Gallery?{
		didSet{
			
			collectionView.reloadData()
		}
	}
	
	var pinchGesture: UIPinchGestureRecognizer?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		//navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
		
		
		collectionView.dropDelegate = self
		collectionView.dragDelegate = self
		collectionView.dragInteractionEnabled = true //for Iphone
		
		pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(adjustImageCellWidth(byHandlingGestureRecognizer:)))
		collectionView.addGestureRecognizer(pinchGesture!)
		
		document?.open{ success in
			self.title = self.document?.localizedName ?? "My Gallery"
			self.gallery = self.document?.gallery
			
		}
		
		
	}
	
	private func documentChanged(){
		document?.gallery = gallery
		if document?.gallery != nil{
			document?.updateChangeCount(.done)
		}
	}
	
	
	@IBAction func closeDocument(_ sender: UIBarButtonItem) {
		
		if document?.gallery != nil {
			//document?.thumbnail = self.view.snapshot
			if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: IndexPath(row: 0, section: 0)) as? ImageCell,
				let imgView = cell.imageView{
				print("YASSS: HAS THUMBNAIL")
				print(imgView.image == nil) ////DEBUG
				document?.thumbnail = imgView.snapshot
			}
			
		}
		dismiss(animated: true){
			self.document?.close()
		}
		
	}
	
	private let imageThumbnailWidth: CGFloat = 250
	var flowLayout: UICollectionViewFlowLayout? {
		
		return collectionView?.collectionViewLayout as? UICollectionViewFlowLayout
	}
	
	private let sectionInsets = UIEdgeInsets(top:50.0, left: 10.0, bottom: 50.0, right: 10.0)
	private var cellWidthScaleFactor: CGFloat = 1.0
	private var maxCellWidth: CGFloat{
		return collectionView.bounds.width - sectionInsets.left - sectionInsets.right
	}
	
	override func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}
	
	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return gallery?.images.count ?? 0
	}
	
	
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		
		
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
		
		
		if let imageCell = cell as? ImageCell, let g = gallery{
			let details = g.images[indexPath.item]
			imageCell.imageDetails = GalleryImage(url: details.url, aspectRatio: details.aspectRatio)
			imageCell.url = details.url
			
		}
		
		return cell
	}
	
	
	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

		let imageDetails = gallery?.images[indexPath.item]
		performSegue(withIdentifier: "Show Image", sender: imageDetails)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let identifier = segue.identifier, identifier == "Show Image"{
			
			if let details = sender as? GalleryImage{
				
				if let imageVC = segue.destination.contents as? ShowImageViewController{
					imageVC.title = details.url.shortString
					imageVC.imageURL = details.url
					
				}
			}
		}
	}
	
	
	
	@objc private func adjustImageCellWidth(byHandlingGestureRecognizer recognizer: UIPinchGestureRecognizer){
		switch recognizer.state{
		case .ended, .changed:
			if let gallery = gallery, gallery.images.count > 0 {
				cellWidthScaleFactor *= recognizer.scale
				flowLayout?.invalidateLayout()
				recognizer.scale = 1.0
		
			}
		default:
			break
		}
	}
	
	

	

	
	
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		flowLayout?.invalidateLayout()
	}

	
	
}

extension ImageGalleryController: UICollectionViewDragDelegate{
	private func dragItems(at indexPath: IndexPath) -> [UIDragItem]{
		if let itemToDrag = (collectionView.cellForItem(at: indexPath) as? ImageCell), let image = itemToDrag.imageView.image{
				let dragItem = UIDragItem(itemProvider: NSItemProvider(object: image))
				dragItem.localObject = itemToDrag.imageDetails
				return [dragItem]
			
		}else{
			return []
		}
	}
	
	
	func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
		session.localContext = collectionView
		return dragItems(at: indexPath)
	}
	
	func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
		return dragItems(at: indexPath)
	}
	
	
}





extension ImageGalleryController: UICollectionViewDropDelegate{
	func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
		//if gallery == nil {return false}
		
		//instantiate new Gallery if none
		if self.gallery == nil{
			self.gallery = Gallery(title: title!)
			print("FROM CAN HANDLE: CREATED NEW GALLERY")
		}else{
			print("DEBUG FROM CANHANDLE:\(self.gallery?.images.count)")
		}
		
		
		let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView
		if isSelf {
			return session.canLoadObjects(ofClass: UIImage.self)
		}
		return session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self)
	}
	
	func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
		let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView

		return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
	}
	
	
	func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {

		let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
	
		for item in coordinator.items {
			if let sourceIndexPath = item.sourceIndexPath {
				if let imageDetails = item.dragItem.localObject as? GalleryImage {
					collectionView.performBatchUpdates({
						gallery?.images.remove(at: sourceIndexPath.item)
						gallery?.images.insert(imageDetails, at: destinationIndexPath.item)
						collectionView.deleteItems(at: [sourceIndexPath])
						collectionView.insertItems(at: [destinationIndexPath])
					})
					coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
				}
			}else{
				let placeHolderContext = coordinator.drop(item.dragItem, to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: "PlaceholderCell"))
				
				
				
				
				var aspectRatio:CGFloat = 1.0
				
				item.dragItem.itemProvider.loadObject(ofClass: UIImage.self){ (provider, error) in
					if let tempImage = provider as? UIImage {
						aspectRatio = tempImage.size.width / tempImage.size.height
					}
				}
				
				
				item.dragItem.itemProvider.loadObject(ofClass: NSURL.self){ (provider, error) in
					DispatchQueue.main.async{
						if let  url = provider as? NSURL{
							placeHolderContext.commitInsertion(dataSourceUpdates: { insertionIndexPath in
								self.gallery!.images.insert( GalleryImage(url: url as URL, aspectRatio: aspectRatio), at: insertionIndexPath.item)
							})
						}else{
							placeHolderContext.deletePlaceholder()
						}
					}
					
				}
			}
			
		}
		documentChanged()
	}
	
	
	
}




extension ImageGalleryController: UICollectionViewDelegateFlowLayout{
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		
		if let gallery = gallery{
			let gi = gallery.images[indexPath.item]
			let aspectRatio  = gi.aspectRatio
			let widthPerItem = min(imageThumbnailWidth * cellWidthScaleFactor , maxCellWidth)
			
			return CGSize(width: widthPerItem, height: widthPerItem / aspectRatio)
		}
		return CGSize.zero
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
		return sectionInsets
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
		return sectionInsets.left
	}
	
	
}

