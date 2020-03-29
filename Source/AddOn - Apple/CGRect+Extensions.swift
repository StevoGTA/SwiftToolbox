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

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func offset(dx :CGFloat, dy :CGFloat) -> CGRect
		{ CGRect(origin: self.origin.offset(dx: dx, dy: dy), size: self.size) }
}
