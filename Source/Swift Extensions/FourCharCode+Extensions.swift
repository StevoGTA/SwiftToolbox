//
//  FourCharCode+Extension.swift
//  Swift Toolbox
//
//  Created by Stevo on 1/25/18.
//  Copyright © 2018 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: FourCharCode extension
extension FourCharCode {

	// MARK: Properties
	var	description :String {
				let utf16 = [
								UInt16((self >> 24) & 0xFF),
								UInt16((self >> 16) & 0xFF),
								UInt16((self >> 8) & 0xFF),
								UInt16((self & 0xFF)),
							]

				return String(utf16CodeUnits: utf16, count: 4)
			}

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(string :String) {
		// Integrity check
		assert(string.count == 4, "String length must be 4")

		// Iterate characters
		var fourCharCode : FourCharCode = 0
		for char in string.utf8 {
			// Shift and add
			fourCharCode = (fourCharCode << 8) + FourCharCode(char)
		}

		// Call default initializer
		self.init(fourCharCode)
	}

	// MARK: methods
	//------------------------------------------------------------------------------------------------------------------
	func toString() -> String { return self.description }
}
