//
//  CGPoint+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 3/20/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import CoreGraphics

//----------------------------------------------------------------------------------------------------------------------
// MARK: CGPoint extensions
extension CGPoint {

	// MARK: Properties
	var	asString :String { "{\(self.x),\(self.y)}" }

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

		// Decompose components
		let	components = string!.components(separatedBy: ",")
		guard components.count == 2 else { return nil }

		// Init
		self.init(x: CGFloat(components[0])!, y: CGFloat(components[1])!)
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func offset(dx :CGFloat, dy :CGFloat) -> CGPoint { CGPoint(x: self.x + dx, y: self.y + dy) }

	//------------------------------------------------------------------------------------------------------------------
	func midpoint(to point :CGPoint) -> CGPoint { CGPoint(x: (self.x + point.x) / 2.0, y: (self.y + point.y) / 2.0) }
}
