//
//  FileManager+Extensions.swift
//  Media Tools macOS Server
//
//  Created by Stevo on 10/26/19.
//  Copyright © 2019 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: FileManager extension
extension FileManager {

	// Types
	typealias FileProc = (_ url :URL) -> Void

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func enumerateFilesDeep(in url :URL, includingPropertiesForKeys keys: [URLResourceKey]? = nil,
			options: FileManager.DirectoryEnumerationOptions = [], fileProc :FileProc) {
		// Enumerate all files
		let	directoryEnumerator =
					FileManager.default.enumerator(at: url, includingPropertiesForKeys: keys, options: options,
							errorHandler: nil)!
		for element in directoryEnumerator {
			// Setup
			let	url = element as! URL

			// Is regular file
			if try! url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile! {
				// Call proc
				fileProc(url)
			}
		}
	}
}
