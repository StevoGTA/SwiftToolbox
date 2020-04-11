//
//  CGRect+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 3/20/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import CoreGraphics

//----------------------------------------------------------------------------------------------------------------------
// MARK: CGRect extensions
extension CGRect {

	// MARK: Properties
	var	center :CGPoint { CGPoint(x: self.midX, y: self.midY) }

	var	asString :String { "{{\(self.origin.x),\(self.origin.y)},{\(self.size.width),\(self.size.height)}}" }

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init?(_ string :String?) {
		// Preflight
		guard string != nil else { return nil }

		// Decompose components
		let	components =
					string!.replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "}", with: "")
							.components(separatedBy: ",")
		guard components.count == 4 else { return nil }

		// Init
		self.init(x: CGFloat(components[0])!, y: CGFloat(components[1])!, width: CGFloat(components[2])!,
				height: CGFloat(components[3])!)
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func offset(dx :CGFloat, dy :CGFloat) -> CGRect
		{ CGRect(origin: self.origin.offset(dx: dx, dy: dy), size: self.size) }
}
