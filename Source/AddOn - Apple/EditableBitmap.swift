//
//  EditableBitmap.swift
//  Swift Toolbox
//
//  Created by Stevo on 7/7/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import CoreGraphics
import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: EditableBitmap
class EditableBitmap {

	// MARK: Properties
				let	context :CGContext

				var	cgImage :CGImage { self.context.makeImage()! }

	internal	let	size :CGSize

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(size :CGSize, colorSpace :CGColorSpace = CGColorSpaceCreateDeviceRGB(), bitsPerComponent :Int = 8,
			bytesPerPixel :Int = 4, alphaInfo :CGImageAlphaInfo = .premultipliedLast) {
		// Setup
		self.context =
				CGContext(data: nil, width: Int(size.width), height: Int(size.height),
						bitsPerComponent: bitsPerComponent, bytesPerRow: Int(size.width) * bytesPerPixel,
						space: colorSpace, bitmapInfo: alphaInfo.rawValue)!

		self.size = size
	}

	//------------------------------------------------------------------------------------------------------------------
	func draw(image :CGImage?, in rect :CGRect? = nil) {
		// Ensure we have an image
		guard image != nil else { return }

		// Draw
		self.context.draw(image!, in: rect ?? CGRect(origin: CGPoint.zero, size: self.size))
	}

	//------------------------------------------------------------------------------------------------------------------
	func clear() { self.context.clear(CGRect(origin: CGPoint.zero, size: self.size)) }
}
