//
//  CGVector+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 7/7/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import CoreGraphics
import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: CGVector extension
extension CGVector {

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(from :CGPoint, to :CGPoint) { self.init(dx: to.x - from.x, dy: to.y - from.y) }
}
