//
//  ImageDetails.swift
//  ImageGallery
//
//  Created by Sam Olof on 10/10/19.
//  Copyright © 2019 Sam Olof. All rights reserved.
//

import UIKit



struct GalleryImage: Codable{
	var url: URL
	var aspectRatio: CGFloat
}

struct Gallery: Codable{
	var title: String?
	var images = [GalleryImage]()
	
	
	var json: Data? {
		return try? JSONEncoder().encode(self)
	}
	
	init?(json: Data){
		if let newValue = try? JSONDecoder().decode(Gallery.self, from: json){
			self = newValue
		}else{
			return nil
		}
	}
	
	init(title: String, images: [GalleryImage]){
		self.title = title
		self.images = images
	}
	
	init(title: String){
		self.title = title
	}
	
	
}



