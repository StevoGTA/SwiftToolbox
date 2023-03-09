//
//  CGRect+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 3/20/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import CoreGraphics
import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: CGRect extensions
extension CGRect {

	// MARK: Properties
	var	upperLeft :CGPoint { self.origin }
	var	middleLeft :CGPoint { CGPoint(x: self.minX, y: self.midY) }
	var	lowerLeft :CGPoint { CGPoint(x: self.minX, y: self.maxY) }

	var	upperCenter :CGPoint { CGPoint(x: self.midX, y: self.minY) }
	var	center :CGPoint { CGPoint(x: self.midX, y: self.midY) }
	var	lowerCenter :CGPoint { CGPoint(x: self.midX, y: self.maxY) }

	var	upperRight :CGPoint { CGPoint(x: self.maxX, y: self.minY) }
	var	middleRight :CGPoint { CGPoint(x: self.maxX, y: self.midY) }
	var	lowerRight :CGPoint { CGPoint(x: self.maxX, y: self.maxY) }

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(center :CGPoint, size :CGSize) {
		// Init
		self.init(origin: center.offsetBy(dx: -size.width * 0.5, dy: -size.height * 0.5), size: size)
	}

	//------------------------------------------------------------------------------------------------------------------
	init(point1 :CGPoint, point2 :CGPoint) {
		// Init
		self.init(x: min(point1.x, point2.x), y: min(point1.y, point2.y),
				width: abs(point2.x - point1.x), height: abs(point2.y - point1.y))
	}

	//------------------------------------------------------------------------------------------------------------------
	init?(_ string :String?) {
		// Preflight
		guard string != nil else { return nil }

		// Get info
		let	components = string!.components(separatedBy: CharacterSet(charactersIn: "{},"))
		guard components.count == 10 else { return nil }
		guard let x = components[2].asDouble else { return nil }
		guard let y = components[3].asDouble else { return nil }
		guard let width = components[6].asDouble else { return nil }
		guard let height = components[7].asDouble else { return nil }

		self.init(x: x, y: y, width: width, height: height)
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func offsetBy(dx :CGFloat, dy :CGFloat) -> CGRect {
		// Return rect
		return CGRect(origin: self.origin.offsetBy(dx: dx, dy: dy), size: self.size)
	}

	//------------------------------------------------------------------------------------------------------------------
	func bounded(to rect :CGRect) -> CGRect {
		// Return rect
		return offsetBy(dx: min(max(rect.minX - self.minX, 0.0), rect.maxX - self.maxX),
				dy: min(max(rect.minY - self.minY, 0.0), rect.maxY - self.maxY))
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: String CoreGraphics Extension
extension String {

	// MARK: Lifecycle methoeds
	//------------------------------------------------------------------------------------------------------------------
	public init(_ rect :CGRect) {
		self.init("{{\(rect.origin.x),\(rect.origin.y)},{\(rect.size.width),\(rect.size.height)}}")
	}
}
