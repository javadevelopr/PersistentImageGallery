//
//  ShowImageViewController.swift
//  ImageGallery
//
//  Created by Sam Olof on 10/15/19.
//  Copyright © 2019 Sam Olof. All rights reserved.
//

import UIKit

class ShowImageViewController: UIViewController, UIScrollViewDelegate {

	@IBOutlet weak var imageDetailSpinner: UIActivityIndicatorView!
	
	@IBOutlet weak var scrollView: UIScrollView!{
		didSet{
			scrollView.minimumZoomScale = 0.1
			scrollView.maximumZoomScale = 3.0
			scrollView.delegate = self
			scrollView.addSubview(imageView)
			
			
		}
	}
	
	@IBOutlet weak var scrollViewWidth: NSLayoutConstraint!
	@IBOutlet weak var scrollViewHeight: NSLayoutConstraint!
	
	var imageView = UIImageView()

	var imageURL: URL?
	
	private var imageFetcher: ImageFetcher?
	private var backUpImage: UIImage? {
		return UIImage(named: "question_mark_thumbnail")
	}
	
	
	func scrollViewDidZoom(_ scrollView: UIScrollView) {
		scrollViewWidth.constant = scrollView.contentSize.width
		scrollViewHeight.constant = scrollView.contentSize.height
	}
	
	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		return imageView
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		navigationItem.largeTitleDisplayMode = .always
		
		imageDetailSpinner.startAnimating()
		
		if let url = imageURL{
			imageFetcher = ImageFetcher(fetch: url){ [weak self] ( _, image) in
				DispatchQueue.main.async {
					self?.imageView.image = image
					let size = image.size
					self?.imageView.frame = CGRect(origin: CGPoint.zero, size: size)
					self?.scrollViewWidth?.constant = size.width
					self?.scrollViewHeight?.constant = size.height
					self?.scrollView?.contentSize = size
				}
			}
			imageFetcher!.backup = backUpImage
			
		}else{
			imageView.image = backUpImage
		}
		imageDetailSpinner?.stopAnimating()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		navigationController?.hidesBarsOnTap = true
	}
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		navigationController?.hidesBarsOnTap = false
	}
	

   

}
