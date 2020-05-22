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
	func setExtendedAttributeValue(_ value :Data, for name :String) throws {
		// Write data
		let	result :Int32 = value.withUnsafeBytes()
					{ setxattr(self.url.path, name, $0.bindMemory(to: UInt8.self).baseAddress!, value.count, 0, 0) }
		if result == -1 { throw POSIXError.general(errno) }
	}

	//------------------------------------------------------------------------------------------------------------------
	func setExtendedAttributeValue(_ value :String, for name :String) throws {
		// Write data
		try setExtendedAttributeValue(value.data(using: .utf8)!, for: name)
	}

	//------------------------------------------------------------------------------------------------------------------
	func setExtendedAttributeValue(_ value :TimeInterval, for name :String) throws {
		// Write data
		try setExtendedAttributeValue(withUnsafeBytes(of: value) { Data($0) }, for: name)
	}

	//------------------------------------------------------------------------------------------------------------------
	func dataForExtendedAttribute(name :String) throws -> Data? {
		// Query size
		let	size = getxattr(self.url.path, name, nil, 0, 0, 0)
		guard size != -1 else { return nil }

		// Read data
		let	buffer = malloc(size)!
		if getxattr(self.url.path, name, buffer, size, 0, 0) != -1 {
			// Success
			return Data(bytes: buffer, count: size)
		} else {
			// Error
			throw POSIXError.general(errno)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func stringForExtendedAttributeName(name :String) throws -> String? {
		// Retrieve data
		guard let data = try dataForExtendedAttribute(name: name) else { return nil }

		return String(data: data, encoding: .utf8)!
	}

	//------------------------------------------------------------------------------------------------------------------
	func timeIntervalForExtendedAttributeName(name :String) throws -> TimeInterval? {
		// Retrieve data
		guard let data = try dataForExtendedAttribute(name: name) else { return nil }

		return data.withUnsafeBytes {$0.load(as: TimeInterval.self) }
	}

	//------------------------------------------------------------------------------------------------------------------
	func extendedAttributeNames() throws -> [String] {
		// Query size
		let	size = listxattr(self.url.path, nil, 0, 0)
		guard size != -1 else { throw POSIXError.general(errno) }

		// Read data
		let	buffer = UnsafeMutablePointer<Int8>.allocate(capacity: size)
		if listxattr(self.url.path, buffer, size, 0) != -1 {
			// Success
			let	string = String(bytes: Data(bytes: buffer, count: size), encoding: .utf8)!

			return string.components(separatedBy: "\0").dropLast()
		} else {
			// Error
			throw POSIXError.general(errno)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func removeExtendedAttribute(name :String) throws {
		// Try to remove
		if removexattr(self.url.path, name, 0) == -1 {
			// Error
			throw POSIXError.general(errno)
		}
	}
}
