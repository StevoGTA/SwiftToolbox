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
	var	asOSType :OSType? {
				// Check count
				guard self.count == MemoryLayout<OSType>.size else { return nil }

				return OSType(bigEndian: self.withUnsafeBytes({ $0.load(as: OSType.self) }))
			}
	var	asUInt32BE :UInt32? {
				// Check count
				guard self.count == MemoryLayout<UInt32>.size else { return nil }

				return UInt32(bigEndian: self.withUnsafeBytes({ $0.load(as: UInt32.self) }))
			}
	var	asUInt32LE :UInt32? {
				// Check count
				guard self.count == MemoryLayout<UInt32>.size else { return nil }

				return UInt32(littleEndian: self.withUnsafeBytes({ $0.load(as: UInt32.self) }))
			}
	var	asUInt64BE :UInt64? {
				// Check count
				guard self.count == MemoryLayout<UInt64>.size else { return nil }

				return UInt64(bigEndian: self.withUnsafeBytes({ $0.load(as: UInt64.self) }))
			}
	var	asUInt64LE :UInt64? {
				// Check count
				guard self.count == MemoryLayout<UInt64>.size else { return nil }

				return UInt64(littleEndian: self.withUnsafeBytes({ $0.load(as: UInt64.self) }))
			}

	var	hexEncodedString :String { map({ String(format: "%02hhx", $0) }).joined() }

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init?(hexEncodedString string :String) {
		// Preflight
		guard string.count.isMultiple(of: 2) else { return nil }

		// Convert to bytes
		let bytes = string.map({ $0 }).chunked(by: 2).compactMap({ UInt8(String($0[0]) + String($0[1]), radix: 16) })
		guard string.count == (bytes.count * 2) else { return nil }

		// Have bytes
		self.init(bytes)
	}
}
