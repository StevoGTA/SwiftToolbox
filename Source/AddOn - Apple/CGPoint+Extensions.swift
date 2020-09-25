//
//  CGPoint+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 3/20/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import CoreGraphics
import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: CGPoint extensions
extension CGPoint {

	// MARK: Class methods
	//------------------------------------------------------------------------------------------------------------------
	static func interpolated(initial :CGPoint, final :CGPoint, percentage :CGFloat) -> CGPoint {
		// Return interpolated point
		return CGPoint(x: CGFloat.interpolated(initial: initial.x, final: final.x, percentage: percentage),
				y: CGFloat.interpolated(initial: initial.y, final: final.y, percentage: percentage))
	}

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init?(_ string :String?) {
		// Preflight
		guard string != nil else { return nil }

		// Get info
		let	components = string!.components(separatedBy: CharacterSet(charactersIn: "{},"))
		guard components.count == 4 else { return nil }
		guard let x = components[1].asDouble else { return nil }
		guard let y = components[2].asDouble else { return nil }

		self.init(x: x, y: y)
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func offsetBy(dx :CGFloat, dy :CGFloat) -> CGPoint { CGPoint(x: self.x + dx, y: self.y + dy) }

	//------------------------------------------------------------------------------------------------------------------
	func offset(to point :CGPoint) -> (dx :CGFloat, dy :CGFloat) { (point.x - self.x, point.y - self.y) }

	//------------------------------------------------------------------------------------------------------------------
	func midpoint(to point :CGPoint) -> CGPoint { CGPoint(x: (self.x + point.x) / 2.0, y: (self.y + point.y) / 2.0) }

	//------------------------------------------------------------------------------------------------------------------
	func distance(to point :CGPoint) -> CGFloat {
		// Get offset
		let	(dx, dy) = offset(to: point)

		return sqrt(dx * dx + dy * dy)
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: String CoreGraphics Extension
extension String {

	// MARK: Lifecycle methoeds
	//------------------------------------------------------------------------------------------------------------------
	public init(_ point :CGPoint) { self.init("{\(point.x),\(point.y)}") }
}
