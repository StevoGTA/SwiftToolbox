//
//  FileWriter.swift
//  Swift Toolbox
//
//  Created by Stevo on 11/3/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: FileWriter
public class FileWriter {

	// MARK: Properties
	private	let	file :File

	// Class methods
	//------------------------------------------------------------------------------------------------------------------
	static public func setContents(of file :File, to data :Data) throws { try data.write(to: file.url) }

	//------------------------------------------------------------------------------------------------------------------
	static func setJSONContents<T>(of file :File, to t :T) throws {
		// Set content
		try setContents(of: file, to: try JSONSerialization.data(withJSONObject: t, options: []))
	}

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(_ file :File) {
		// Store
		self.file = file
	}
}
