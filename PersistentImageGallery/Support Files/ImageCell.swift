//
//  ImageCell.swift
//  ImageGallery
//
//  Created by Sam Olof on 10/4/19.
//  Copyright © 2019 Sam Olof. All rights reserved.
//

import UIKit

class ImageCell: UICollectionViewCell {
    
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var spinner: UIActivityIndicatorView!
	
	var imageDetails: GalleryImage?
	
	private var scale: CGFloat = 1.0
	private var backUpImage: UIImage? {
		return UIImage(named: "question_mark_thumbnail")
	}
	
	private var imageFetcher: ImageFetcher?
	
	var url: URL?{
		didSet{
			imageView.image = nil
			spinner?.startAnimating()
			
			imageFetcher = ImageFetcher(fetch: url!){ (_, image) in
				DispatchQueue.main.async{
					self.imageView.image = image
				}
			}
			imageFetcher!.backup = backUpImage
			spinner?.stopAnimating()
			

		
		}
	}
	
	
}


