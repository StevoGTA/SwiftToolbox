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
	var	center :CGPoint { CGPoint(x: self.midX, y: self.midY) }

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init?(_ string :String?) {
		// Preflight
		guard string != nil else { return nil }

		// Get info
		let	components = string!.components(separatedBy: CharacterSet(charactersIn: "{},"))
		guard components.count == 10 else { return nil }
		guard let x = components[2].toDouble() else { return nil }
		guard let y = components[3].toDouble() else { return nil }
		guard let width = components[6].toDouble() else { return nil }
		guard let height = components[7].toDouble() else { return nil }

		self.init(x: x, y: y, width: width, height: height)
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func offset(dx :CGFloat, dy :CGFloat) -> CGRect
		{ CGRect(origin: self.origin.offset(dx: dx, dy: dy), size: self.size) }
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
