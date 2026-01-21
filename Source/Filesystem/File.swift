//
//  File.swift
//  Swift Toolbox
//
//  Created by Stevo on 4/20/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: File
public class File : Equatable, Hashable, @unchecked Sendable {

	// MARK: Types
	public typealias SubPathProc = (_ file :File, _ subPath :String) -> Void

	// MARK: Properties
	public	private(set)	var	url :URL

	public					var	name :String { self.url.lastPathComponent }
	public					var	`extension` :String? { self.url.pathExtension }
	public					var	path :String { self.url.path }
	public					var	size :Int64? { self.url.fileSize }
	public					var	isHidden :Bool { self.name.hasPrefix(".") }
	public					var	folder :Folder { Folder(self.url.deletingLastPathComponent()) }
	public					var	creationDate :Date { self.url.creationDate! }
	public					var	modificationDate :Date { self.url.contentModificationDate! }
	public					var	localizedTypeDescription :String? { self.url.localizedTypeDescription }
	public					var	isAlias :Bool { (self.localizedTypeDescription ?? "") == "Alias" }

	// MARK: Class methods
	//------------------------------------------------------------------------------------------------------------------
	static public func from(_ url :URL?) -> File? { (url != nil) ? File(url!) : nil }

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(_ url :URL) {
		// Store
		self.url = url
	}

	// MARK: Equatable methods
	//------------------------------------------------------------------------------------------------------------------
	static public func ==(lhs :File, rhs :File) -> Bool { lhs.url == rhs.url }

	// MARK: Hashable methods
	//------------------------------------------------------------------------------------------------------------------
	public func hash(into hasher :inout Hasher) { hasher.combine(self.path) }

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func contentsAsData() throws -> Data? { try Data(contentsOf: self.url) }

	//------------------------------------------------------------------------------------------------------------------
	func set(creationDate :Date) throws { try self.url.set(creationDate: creationDate) }

	//------------------------------------------------------------------------------------------------------------------
	func set(modificationDate :Date) throws { try self.url.set(modificationDate: modificationDate) }
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - Sequence extension for File
extension Sequence where Element == File {

	// Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func sorted() -> [File] {
		return sorted(keyProc: { $0.name },
				keyCompareProc: { $0.compare($1, options: [.caseInsensitive, .numeric]) == .orderedAscending })
	}
}
