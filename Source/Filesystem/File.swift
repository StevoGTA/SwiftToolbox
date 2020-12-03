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
class File {

	// MARK: Types
	typealias SubPathProc = (_ file :File, _ subPath :String) -> Void

	// MARK: Properties
	let	url :URL

	var	name :String { self.url.lastPathComponent }
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
	init(_ url :URL) {
		// Store
		self.url = url
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func contentsAsData() throws -> Data? { try Data(contentsOf: self.url) }

	//------------------------------------------------------------------------------------------------------------------
	func setContents(_ data :Data) throws { try data.write(to: self.url) }
}
