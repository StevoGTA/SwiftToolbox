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
	func extendedAttributeNames() throws -> Set<String> {
		// Query size
		let	size = listxattr(self.path, nil, 0, 0)
		guard size != -1 else { throw POSIXError.general(errno) }

		// Read data
		let	buffer = UnsafeMutablePointer<Int8>.allocate(capacity: size)
		if listxattr(self.path, buffer, size, 0) != -1 {
			// Success
			let	string = String(bytes: Data(bytes: buffer, count: size), encoding: .utf8)!

			return Set<String>(string.components(separatedBy: "\0").dropLast())
		} else {
			// Error
			throw POSIXError.general(errno)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func data(forExtendedAttributeNamed name :String) throws -> Data? {
		// Query size
		let	size = getxattr(self.path, name, nil, 0, 0, 0)
		guard size != -1 else { return nil }

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
	func string(forExtendedAttributeNamed name :String) throws -> String? {
		// Retrieve data
		guard let data = try data(forExtendedAttributeNamed: name) else { return nil }

		return String(data: data, encoding: .utf8)!
	}

	//------------------------------------------------------------------------------------------------------------------
	func timeInterval(forExtendedAttributeNamed name :String) throws -> TimeInterval? {
		// Retrieve data
		guard let data = try data(forExtendedAttributeNamed: name) else { return nil }

		return data.withUnsafeBytes {$0.load(as: TimeInterval.self) }
	}

	//------------------------------------------------------------------------------------------------------------------
	func set(_ data :Data, forExtendedAttributeNamed name :String) throws {
		// Write data
		let	result :Int32 = data.withUnsafeBytes()
					{ setxattr(self.path, name, $0.bindMemory(to: UInt8.self).baseAddress!, data.count, 0, 0) }
		guard result != -1 else {  throw POSIXError.general(errno) }
	}

	//------------------------------------------------------------------------------------------------------------------
	func set(_ string :String, forExtendedAttributeNamed name :String) throws {
		// Write string
		try set(string.data(using: .utf8)!, forExtendedAttributeNamed: name)
	}

	//------------------------------------------------------------------------------------------------------------------
	func set(_ timeInterval :TimeInterval, forExtendedAttributeNamed name :String) throws {
		// Write data
		try set(withUnsafeBytes(of: timeInterval, { Data($0) }), forExtendedAttributeNamed: name)
	}

	//------------------------------------------------------------------------------------------------------------------
	func remove(extendedAttributeNamed name :String) throws {
		// Try to remove
		if removexattr(self.path, name, 0) == -1 {
			// Error
			throw POSIXError.general(errno)
		}
	}
}
