//
//  File+ExtendedAttributes.swift
//  Media Player - Apple
//
//  Created by Stevo on 4/20/20.
//  Copyright © 2020 Sunset Magicwerks, LLC. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: File extension
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
	func dataForExtendedAttribute(name :String) throws -> Data {
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
	func stringForExtendedAttributeName(name :String) throws -> String {
		// Retrieve string
		String(data: try dataForExtendedAttribute(name: name), encoding: .utf8)!
	}

	//------------------------------------------------------------------------------------------------------------------
	func setExtendedAttribute(name :String, data :Data) throws {
		// Write data
		let	result :Int32 = data.withUnsafeBytes()
					{ setxattr(self.path, name, $0.bindMemory(to: UInt8.self).baseAddress!, data.count, 0, 0) }
		guard result != -1 else {  throw POSIXError.general(errno) }
	}

	//------------------------------------------------------------------------------------------------------------------
	func setExtendedAttribute(name :String, value :String) throws {
		// Write string
		try setExtendedAttribute(name: name, data: value.data(using: .utf8)!)
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
