//
//  CGFloat+Extension.swift
//  Swift Toolbox
//
//  Created by Stevo on 4/9/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import CoreGraphics
import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: CGFloat extension
extension CGFloat {

	// MARK: Properties
	static	private	let	numberFormatter = NumberFormatter()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init?(_ value :Any?) {
		// Check value
		if value == nil {
			// No value
			return nil
		} else if let string = value as? String,
				let cgFloat = CGFloat.numberFormatter.number(from: string) as? CGFloat {
			// String
			self.init(cgFloat)
		} else {
			// Unknown
			return nil
		}
	}

	// MARK: Class methods
	//------------------------------------------------------------------------------------------------------------------
	static func interpolated(initial :CGFloat, final :CGFloat, percentage :CGFloat) -> CGFloat {
		// Return interpolated value
		return initial + (final - initial) * percentage
	}
}
