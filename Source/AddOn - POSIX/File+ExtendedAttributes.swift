//
//  File+ExtendedAttributes.swift
//  Media Player - Apple
//
//  Created by Stevo on 4/20/20.
//  Copyright © 2020 Sunset Magicwerks, LLC. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: File extended attribute extension
extension File {

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func extendedAttributeNames() throws -> [String] {
		// Query size
		let	size = listxattr(self.path, nil, 0, 0)
		guard size != -1 else { throw POSIXError.general(errno) }

		// Read data
		let	buffer = UnsafeMutablePointer<Int8>.allocate(capacity: size)
		if listxattr(self.path, buffer, size, 0) != -1 {
			// Success
			let	string = String(bytes: Data(bytes: buffer, count: size), encoding: .utf8)!

			return string.components(separatedBy: "\0").dropLast()
		} else {
			// Error
			throw POSIXError.general(errno)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func data(ForExtendedAttributeNamed name :String) throws -> Data? {
		// Query size
		let	size = getxattr(self.path, name, nil, 0, 0, 0)
		guard size != -1 else { throw POSIXError.general(errno) }

		// Read data
		let	buffer = malloc(size)!
		if getxattr(self.path, name, buffer, size, 0, 0) != -1 {
			// Success
			return Data(bytes: buffer, count: size)
		} else {
			// Error
			throw POSIXError.general(errno)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func string(ForExtendedAttributeNamed name :String) throws -> String? {
		// Retrieve data
		guard let data = try data(ForExtendedAttributeNamed: name) else { return nil }

		return String(data: data, encoding: .utf8)!
	}

	//------------------------------------------------------------------------------------------------------------------
	func timeInterval(ForExtendedAttributeNamed name :String) throws -> TimeInterval? {
		// Retrieve data
		guard let data = try data(ForExtendedAttributeNamed: name) else { return nil }

		return data.withUnsafeBytes {$0.load(as: TimeInterval.self) }
	}

	//------------------------------------------------------------------------------------------------------------------
	func setExtendedAttribute(_ data :Data, for name :String) throws {
		// Write data
		let	result :Int32 = data.withUnsafeBytes()
					{ setxattr(self.path, name, $0.bindMemory(to: UInt8.self).baseAddress!, data.count, 0, 0) }
		guard result != -1 else {  throw POSIXError.general(errno) }
	}

	//------------------------------------------------------------------------------------------------------------------
	func setExtendedAttribute(string :String, for name :String) throws {
		// Write string
		try setExtendedAttribute(string.data(using: .utf8)!, for: name)
	}

	//------------------------------------------------------------------------------------------------------------------
	func setExtendedAttribute(_ timeInterval :TimeInterval, for name :String) throws {
		// Write data
		try setExtendedAttribute(withUnsafeBytes(of: timeInterval, { Data($0) }), for: name)
	}

	//------------------------------------------------------------------------------------------------------------------
	func removeExtendedAttribute(name :String) throws {
		// Try to remove
		if removexattr(self.path, name, 0) == -1 {
			// Error
			throw POSIXError.general(errno)
		}
	}
}
