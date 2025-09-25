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
	var	isDirectory :Bool {
				// Check for symbolic link
				if (try? resourceValues(forKeys: [.isSymbolicLinkKey]))?.isSymbolicLink ?? false {
					// Symbolic links don't know, must resolve
					let	resolvedURL = self.urlByResolvingLinks

					return (try? resolvedURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
				} else {
					// Not symbolic link
					return (try? self.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
				}
			}
	var	isFolder :Bool { self.isDirectory }
	var	isFile :Bool {
				// Check for symbolic link
				if (try? resourceValues(forKeys: [.isSymbolicLinkKey]))?.isSymbolicLink ?? false {
					// Symbolic links don't know, must resolve
					let	resolvedURL = self.urlByResolvingLinks

					return (try? resolvedURL.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile ?? false
				} else {
					// Not symbolic link
					return (try? self.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile ?? false
				}
			}
	var	isSymbolicLink :Bool? { (try? resourceValues(forKeys: [.isSymbolicLinkKey]))?.isSymbolicLink }

	var	fileSize :Int64? { Int64((try? self.resourceValues(forKeys: [.fileSizeKey]))?.fileSize) }
	var	creationDate :Date? { (try? self.resourceValues(forKeys: [.creationDateKey]))?.creationDate }
	var	contentModificationDate :Date?
				{ (try? self.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate }
	var	localizedTypeDescription :String?
			{ (try? resourceValues(forKeys: [.localizedTypeDescriptionKey]))?.localizedTypeDescription }

	var	urlByResolvingLinks :URL {
				// Check path
				switch self.path {
#if os(macOS)
					case "/etc":	return URL(fileURLWithPath: "/private/etc")
					case "/tmp":	return URL(fileURLWithPath: "/private/tmp")
					case "/var":	return URL(fileURLWithPath: "/private/var")
#endif
					default:		return self.resolvingSymlinksInPath()
				}
			}

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

//----------------------------------------------------------------------------------------------------------------------
// MARK: - Sequence extension for URL
extension Sequence where Element == URL {

	// Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func sortedByLastPathComponent() -> [URL] {
		return sorted(keyProc: { $0.lastPathComponent },
				keyCompareProc: { $0.compare($1, options: [.caseInsensitive, .numeric]) == .orderedAscending })
	}
}
