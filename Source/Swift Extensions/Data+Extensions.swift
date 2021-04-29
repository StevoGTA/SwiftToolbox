//
//  Data+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 4/22/21.
//  Copyright © 2021 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: Data extension
public extension Data {

	// MARK: Properties
	var	hexEncodedString :String { map({ String(format: "%02hhx", $0) }).joined() }

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init?(hexEncodedString string :String) {
		// Preflight
		guard string.count.isMultiple(of: 2) else { return nil }

		// Convert to bytes
		let bytes = string.map({ $0 }).chunk(by: 2).compactMap({ UInt8(String($0[0]) + String($0[1]), radix: 16) })
		guard string.count == (bytes.count * 2) else { return nil }

		// Have bytes
		self.init(bytes)
	}
}
