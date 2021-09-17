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
public class FileReader {

	// MARK: Properties
	private	let	file :File

	// Class methods
	//------------------------------------------------------------------------------------------------------------------
	static public func contentsAsData(of file :File) throws -> Data {
		// Read as data
		try Data(contentsOf: file.url, options: [.mappedIfSafe])
	}

	//------------------------------------------------------------------------------------------------------------------
	static func contentsAsString(of file :File, encoding :String.Encoding = .utf8) throws -> String? {
		// Read as string
		return String(data: try Data(contentsOf: file.url, options: [.mappedIfSafe]), encoding: encoding)
	}

	//------------------------------------------------------------------------------------------------------------------
	static func contentsAsJSON<T>(of file :File) throws -> T? {
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
