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
	var	asInt8 :Int8? {
				// Check count
				guard self.count == MemoryLayout<Int8>.size else { return nil }

				return Int8(bigEndian: self.withUnsafeBytes({ $0.load(as: Int8.self) }))
			}
	var	asUInt8 :UInt8? {
				// Check count
				guard self.count == MemoryLayout<UInt8>.size else { return nil }

				return UInt8(bigEndian: self.withUnsafeBytes({ $0.load(as: UInt8.self) }))
			}
	var	asInt16BE :Int16? {
				// Check count
				guard self.count == MemoryLayout<Int16>.size else { return nil }

				return Int16(bigEndian: self.withUnsafeBytes({ $0.load(as: Int16.self) }))
			}
	var	asInt16LE :Int16? {
				// Check count
				guard self.count == MemoryLayout<Int16>.size else { return nil }

				return Int16(littleEndian: self.withUnsafeBytes({ $0.load(as: Int16.self) }))
			}
	var	asUInt16BE :UInt16? {
				// Check count
				guard self.count == MemoryLayout<UInt16>.size else { return nil }

				return UInt16(bigEndian: self.withUnsafeBytes({ $0.load(as: UInt16.self) }))
			}
	var	asUInt16LE :UInt16? {
				// Check count
				guard self.count == MemoryLayout<UInt16>.size else { return nil }

				return UInt16(littleEndian: self.withUnsafeBytes({ $0.load(as: UInt16.self) }))
			}
	var	asOSType :OSType? {
				// Check count
				guard self.count == MemoryLayout<OSType>.size else { return nil }

				return OSType(bigEndian: self.withUnsafeBytes({ $0.load(as: OSType.self) }))
			}
	var	asInt32BE :Int32? {
				// Check count
				guard self.count == MemoryLayout<Int32>.size else { return nil }

				return Int32(bigEndian: self.withUnsafeBytes({ $0.load(as: Int32.self) }))
			}
	var	asInt32LE :Int32? {
				// Check count
				guard self.count == MemoryLayout<Int32>.size else { return nil }

				return Int32(littleEndian: self.withUnsafeBytes({ $0.load(as: Int32.self) }))
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
	var	asInt64BE :Int64? {
				// Check count
				guard self.count == MemoryLayout<Int64>.size else { return nil }

				return Int64(bigEndian: self.withUnsafeBytes({ $0.load(as: Int64.self) }))
			}
	var	asInt64LE :Int64? {
				// Check count
				guard self.count == MemoryLayout<Int64>.size else { return nil }

				return Int64(littleEndian: self.withUnsafeBytes({ $0.load(as: Int64.self) }))
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

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func subdata(fromIndex :Int, length :Int) -> Data? {
		// Preflight
		guard (fromIndex + length) <= self.count else { return nil }

		// Setup
		let	startIndex = self.index(self.startIndex, offsetBy: fromIndex)
		let	endIndex = self.index(startIndex, offsetBy: length)

		return subdata(in: startIndex..<endIndex)
	}
}
