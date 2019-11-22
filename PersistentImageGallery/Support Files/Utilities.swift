//
//  Utilities.swift
//  EmojiArtTester
//
//  Created by Sam Olof on 8/6/19.
//  Copyright © 2019 Sam Olof. All rights reserved.
//

import UIKit

let diskCacheCapacity = 125000000  //125MB
//let cachePolicy: NSURLRequest.CachePolicy = .reloadIgnoringLocalCacheData //.useProtocolCachePolicy
let cachePolicy: NSURLRequest.CachePolicy = .useProtocolCachePolicy

class ImageFetcher
{
	
	var backup: UIImage? {didSet {callHandlerIfNeeded()}}
	
	private lazy var session: URLSession = {
		let urlCache = URLCache.shared
		urlCache.diskCapacity = diskCacheCapacity
		let configuration = URLSessionConfiguration.default
		configuration.urlCache = urlCache
		configuration.requestCachePolicy = cachePolicy
		return URLSession(configuration: configuration)
	}()
	
	
	func cachedFetch(_ url: URL){
		
		let task = session.dataTask(with: url.imageURL){ [weak self] (data, response, error)  in
			if error != nil{
				self?.fetchFailed = true
			}else{
				let response = response as? HTTPURLResponse
				if let mimeType = response?.mimeType, mimeType.starts(with: "image/"), let imgData = data, let image = UIImage(data:imgData) {
					self?.handler(url, image)
				}else{
					self?.fetchFailed = true
				}
			}
		}
		task.resume()
		
	}
	
	
	func fetch(_ url: URL){
		DispatchQueue.global(qos: .userInitiated).async{ [weak self] in
			
			if let data = try? Data(contentsOf: url.imageURL){
				if self != nil {
					if let image = UIImage(data:data){
						self?.handler(url, image)
					}else{
						self?.fetchFailed = true
					}
				}else{
					print("ImageFetcher: fetch returned but I've left the heap -- ignoring result.")
				}
			}else{
				self?.fetchFailed = true
			}
			
		}
	}
	
	init(handler: @escaping (URL, UIImage)->Void){
		self.handler = handler
	}
	init(fetch url: URL, handler: @escaping (URL, UIImage) -> Void){
		self.handler = handler
		//fetch(url)
		cachedFetch(url)
	}
	private let handler: (URL, UIImage) -> Void
	private var fetchFailed = false {
		didSet { callHandlerIfNeeded()}
	}
	
	
	private func callHandlerIfNeeded(){
		if fetchFailed, let image = backup, let url = image.storeLocallyAsJPEG(named: String(Date().timeIntervalSinceReferenceDate)){
			handler(url, image)
		}
	}
}
extension URL{
	var imageURL: URL {
		if let url = UIImage.urlToStoreLocallyAsJPEG(named: self.path){
			return url
		}else{
			//check to see if there is an embedded imgurl reference
			for query in query?.components(separatedBy: "&") ?? [] {
				let queryComponents = query.components(separatedBy: "=")
				if queryComponents.count == 2 {
					if queryComponents[0] == "imgurl", let url = URL(string: queryComponents[1].removingPercentEncoding ?? ""){
						return url
					}
				}
			}
			return self.baseURL ?? self
			}
		}
	
	var shortString: String{
		return lastPathComponent
	}
}
extension UIImage{
	private static let localimagesDirectory =  "UIImage.storeLocallyAsJPEG"
	
	static func urlToStoreLocallyAsJPEG(named: String) -> URL? {
		var name = named
		let pathComponents = named.components(separatedBy: "/")
		if pathComponents.count > 1 {
			if pathComponents[pathComponents.count - 2] == localimagesDirectory {
				name = pathComponents.last!
			}else{
				return nil
			}
		}
		if var url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first{
			url = url.appendingPathComponent(localimagesDirectory)
			do{
				try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
				url = url.appendingPathComponent(name)
				if url.pathExtension != "jpg" {
					url = url.appendingPathExtension("jpg")
				}
				return url
			}catch let error {
				print("UIImage.urlToStoreLocallyAsJPEG \(error)")
			}
		}
		return nil
	}
	func storeLocallyAsJPEG(named name: String) -> URL? {
		if let imageData = self.jpegData(compressionQuality: 1.0) {
            if let url = UIImage.urlToStoreLocallyAsJPEG(named: name) {
                do {
                    try imageData.write(to: url)
                    return url
                } catch let error {
                    print("UIImage.storeLocallyAsJPEG \(error)")
                }
            }
        }
        return nil
    }
}

extension String {
    func madeUnique(withRespectTo otherStrings: [String]) -> String {
        var possiblyUnique = self
        var uniqueNumber = 1
        while otherStrings.contains(possiblyUnique) {
            possiblyUnique = self + "_\(uniqueNumber)"
            uniqueNumber += 1
        }
        return possiblyUnique
    }
	
	func madeUnique(withRespectTo galleryCollection: [Gallery]) -> String{
		
		let otherStrings: [String] = galleryCollection.map{ $0.title ?? ""}
		return madeUnique(withRespectTo: otherStrings)
	}
}


extension Array where Element: Equatable {
    var uniquified: [Element] {
        var elements = [Element]()
        forEach { if !elements.contains($0) { elements.append($0) } }
        return elements
    }
}

extension NSAttributedString {
    func withFontScaled(by factor: CGFloat) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: self)
        mutable.setFont(mutable.font?.scaled(by: factor))
        return mutable
    }
    var font: UIFont? {
        get { return attribute(.font, at: 0, effectiveRange: nil) as? UIFont }
    }
}

extension String {
	func attributedString(withTextStyle style: UIFont.TextStyle, ofSize size: CGFloat) -> NSAttributedString {
        let font = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(size))
        return NSAttributedString(string: self, attributes: [.font:font])
    }
}

extension NSMutableAttributedString {
    func setFont(_ newValue: UIFont?) {
        if newValue != nil { addAttributes([.font:newValue!], range: NSMakeRange(0, length)) }
    }
}

extension UIFont {
    func scaled(by factor: CGFloat) -> UIFont { return withSize(pointSize * factor) }
}

extension UILabel {
    func stretchToFit() {
        let oldCenter = center
        sizeToFit()
        center = oldCenter
    }
}

extension CGPoint {
    func offset(by delta: CGPoint) -> CGPoint {
        return CGPoint(x: x + delta.x, y: y + delta.y)
    }
}

extension UIViewController {
    var contents: UIViewController {
        if let navcon = self as? UINavigationController {
            return navcon.visibleViewController ?? navcon
        } else {
            return self
        }
    }
}

extension UIView {
    var snapshot: UIImage? {
        UIGraphicsBeginImageContext(bounds.size)
        drawHierarchy(in: bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension CGRect{
    
    func zoom(by scale:CGFloat) -> CGRect {
        
        let newWidth = width * scale
        let newHeight = height * scale
        
        return insetBy(dx: (width - newWidth) / 2, dy: (height - newHeight) / 2)
    }
}
