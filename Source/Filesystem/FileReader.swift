//
//  FileReader.swift
//  Swift Toolbox
//
//  Created by Stevo on 11/3/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: FileReader
class FileReader {

	// MARK: Properties
	private	let	file :File

	// Class methods
	//------------------------------------------------------------------------------------------------------------------
	static func contents(of file :File) throws -> Data { try Data(contentsOf: file.url, options: [.mappedIfSafe]) }

	//------------------------------------------------------------------------------------------------------------------
	static func jsonContents<T>(of file :File) throws -> T? {
		// Return contents
		return try JSONSerialization.jsonObject(with: try Data(contentsOf: file.url), options: []) as? T
	}

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(_ file :File) {
		// Store
		self.file = file
	}
}
