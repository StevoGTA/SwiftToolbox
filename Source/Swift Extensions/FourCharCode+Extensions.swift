//
//  FourCharCode+Extension.swift
//  Swift Toolbox
//
//  Created by Stevo on 1/25/18.
//  Copyright © 2018 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: FourCharCode extension
public extension FourCharCode {

	// MARK: Properties
	var	description :String {
				// Setup
				let utf16 = [
								UInt16((self >> 24) & 0xFF),
								UInt16((self >> 16) & 0xFF),
								UInt16((self >> 8) & 0xFF),
								UInt16((self & 0xFF)),
							]

				return String(utf16CodeUnits: utf16, count: 4)
			}

	// MARK: methods
	//------------------------------------------------------------------------------------------------------------------
	func toString() -> String { self.description }
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: FourCharCode extension
extension UInt32: @retroactive ExpressibleByExtendedGraphemeClusterLiteral {}
extension UInt32: @retroactive ExpressibleByUnicodeScalarLiteral {}
extension FourCharCode : @retroactive ExpressibleByStringLiteral {

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(stringLiteral value :StringLiteralType) {
		// Check conditions
		if let data = value.data(using: .macOSRoman), data.count == 4 {
			// Have 4 character string literal
			self = data.reduce(0, { $0 << 8 + Self($1) })
		} else {
			// Do not have four character string literal
			self = 0
		}
	}
}
