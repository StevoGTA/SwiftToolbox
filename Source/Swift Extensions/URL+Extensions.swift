//
//  URL+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 1/4/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: URL extension
public extension URL {

	// MARK: Properties
	var	fileSize :Int64? {
				// Try to get file size
				if let fileSize = (try? resourceValues(forKeys: [.fileSizeKey]))?.fileSize {
					// Have size
					return Int64(fileSize)
				} else {
					// Can't get size
					return nil
				}
			}
	var	isDirectory :Bool { (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false }
	var	isFolder :Bool { self.isDirectory }
	var	isFile :Bool { (try? resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile ?? false }
	var	creationDate :Date? { (try? resourceValues(forKeys: [.creationDateKey]))?.creationDate }
	var	contentModificationDate :Date?
				{ (try? resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate }

	// MARK: Class methods
	//------------------------------------------------------------------------------------------------------------------
	static func from(path :String?) -> URL? { (path != nil) ? URL(fileURLWithPath: path!) : nil }

	//------------------------------------------------------------------------------------------------------------------
	static func from(string :String?) -> URL? { (string != nil) ? URL(string: string!) : nil }

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func subPath(relativeTo url :URL) -> String? {
		// Setup
		let	fullPath = self.path
		let	rootPath = url.path

		return fullPath.hasPrefix(rootPath) ? fullPath.substring(fromCharacterIndex: rootPath.count + 1) : nil
	}

	//------------------------------------------------------------------------------------------------------------------
	mutating func set(creationDate :Date) throws {
		// Set resource values
		var	resourceValues = URLResourceValues()
		resourceValues.creationDate = creationDate
		try setResourceValues(resourceValues)
	}

	//------------------------------------------------------------------------------------------------------------------
	mutating func set(modificationDate :Date) throws {
		// Set resource values
		var	resourceValues = URLResourceValues()
		resourceValues.contentModificationDate = modificationDate
		try setResourceValues(resourceValues)
	}
}
