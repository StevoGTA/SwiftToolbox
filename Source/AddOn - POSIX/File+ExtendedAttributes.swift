//
//  File+ExtendedAttributes.swift
//  Swift Toolbox
//
//  Created by Stevo on 4/20/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

#if os(Linux)
	import System
#endif

//----------------------------------------------------------------------------------------------------------------------
// MARK: File extended attribute extension
public extension File {

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func extendedAttributeNames() throws -> Set<String> {
		// Query size
#if os(macOS) || os(tvOS)
		var	size = listxattr(self.path, nil, 0, 0)
#elseif os(Linux)
		var	size = listxattr(self.path, nil, 0)
#endif
		guard size != -1 else { throw POSIXError.general(errno) }

		// Read data
		let	buffer = UnsafeMutablePointer<Int8>.allocate(capacity: size)
#if os(macOS) || os(tvOS)
		size = listxattr(self.path, buffer, size, 0)
#elseif os(Linux)
		size = listxattr(self.path, buffer, size)
#endif
		if size != -1 {
			// Success
			let	string = String(bytes: Data(bytes: buffer, count: size), encoding: .utf8)!

			return Set<String>(string.components(separatedBy: "\0").dropLast())
		} else {
			// Error
			throw POSIXError.general(errno)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func extendedAttributeDataByName() throws -> [String : Data] {
		// Compose the map
		var	dataByExtendedAttributeName = [String : Data]()
		try extendedAttributeNames().forEach() {
			// Store
			dataByExtendedAttributeName[$0] = try data(forExtendedAttributeNamed: $0)
		}

		return dataByExtendedAttributeName
	}

	//------------------------------------------------------------------------------------------------------------------
	func data(forExtendedAttributeNamed name :String) throws -> Data? {
		// Query size
#if os(macOS) || os(tvOS)
		var	size = getxattr(self.path, name, nil, 0, 0, 0)
#elseif os(Linux)
		var	size = getxattr(self.path, name, nil, 0)
#endif
		guard size != -1 else { return nil }

		// Read data
		let	buffer = malloc(size)!
#if os(macOS) || os(tvOS)
		size = getxattr(self.path, name, buffer, size, 0, 0)
#elseif os(Linux)
		size = getxattr(self.path, name, buffer, size)
#endif
		if size != -1 {
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
	func set(extendedAttributeData :[String : Data]) throws {
		// Iterate
		try extendedAttributeData.forEach() { try set($0.value, forExtendedAttributeNamed: $0.key) }
	}

	//------------------------------------------------------------------------------------------------------------------
	func set(_ data :Data, forExtendedAttributeNamed name :String) throws {
		// Write data
		let	result :Int32 = data.withUnsafeBytes()
					{
#if os(macOS) || os(tvOS)
						setxattr(self.path, name, $0.bindMemory(to: UInt8.self).baseAddress!, data.count, 0, 0)
#elseif os(Linux)
						setxattr(self.path, name, $0.bindMemory(to: UInt8.self).baseAddress!, data.count, 0)
#endif
					}
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
#if os(macOS) || os(tvOS)
	let	result = removexattr(self.path, name, 0)
#elseif os(Linux)
	let	result = removexattr(self.path, name)
#endif
		if result == -1 {
			// Error
			throw POSIXError.general(errno)
		}
	}
}
