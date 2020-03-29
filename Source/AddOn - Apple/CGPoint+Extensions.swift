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

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func offset(dx :CGFloat, dy :CGFloat) -> CGPoint { CGPoint(x: self.x + dx, y: self.y + dy) }
}
