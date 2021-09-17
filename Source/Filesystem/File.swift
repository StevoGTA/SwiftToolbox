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
public class File {

	// MARK: Types
	typealias SubPathProc = (_ file :File, _ subPath :String) -> Void

	// MARK: Properties
	public	private(set)	var	url :URL

							var	name :String { self.url.lastPathComponent }
							var	`extension` :String? { self.url.pathExtension }
							var	folder :Folder { Folder(self.url.deletingLastPathComponent()) }

							var	path :String { self.url.path }
							var	size :Int64? { self.url.fileSize }
							var	creationDate :Date { self.url.creationDate! }
							var	modificationDate :Date { self.url.contentModificationDate! }

	// MARK: Class methods
	//------------------------------------------------------------------------------------------------------------------
	static func from(_ url :URL?) -> File? { (url != nil) ? File(url!) : nil }

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(_ url :URL) {
		// Store
		self.url = url
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func contentsAsData() throws -> Data? { try Data(contentsOf: self.url) }

	//------------------------------------------------------------------------------------------------------------------
	func set(creationDate :Date) throws { try self.url.set(creationDate: creationDate) }

	//------------------------------------------------------------------------------------------------------------------
	func set(modificationDate :Date) throws { try self.url.set(modificationDate: modificationDate) }
}
