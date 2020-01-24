//
//  FileManager+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 10/26/19.
//  Copyright © 2019 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: FileManager extension
extension FileManager {

	// Types
	typealias FolderProc = (_ url :URL, _ subPath :String) -> Void
	typealias FileProc = (_ url :URL, _ subPath :String) -> Void

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func enumerateFoldersFiles(in url :URL, includingPropertiesForKeys keys: [URLResourceKey]? = nil,
			options: FileManager.DirectoryEnumerationOptions = [], folderProc :FolderProc, fileProc :FileProc) {
		// Setup
		let	keysUse = (keys ?? []) + [.isRegularFileKey]

		// Iterate all urls
		let	urls = try! contentsOfDirectory(at: url, includingPropertiesForKeys: keysUse, options: options)
		urls.forEach() {
			// Check folder/file
			if !(try! $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile!) {
				// Folder
				folderProc($0, $0.subPath(relativeTo: url)!)
			} else {
				// File
				fileProc($0, $0.subPath(relativeTo: url)!)
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func enumerateFolders(in url :URL, includingPropertiesForKeys keys: [URLResourceKey]? = nil,
			options: FileManager.DirectoryEnumerationOptions = [], folderProc :FolderProc) {
		// Setup
		let	keysUse = (keys ?? []) + [.isRegularFileKey]

		// Iterate all urls
		let	urls = try! contentsOfDirectory(at: url, includingPropertiesForKeys: keysUse, options: options)
		urls.forEach() {
			// Check folder/file
			if !(try! $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile!) {
				// Folder
				folderProc($0, $0.subPath(relativeTo: url)!)
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func enumerateFiles(in url :URL, includingPropertiesForKeys keys: [URLResourceKey]? = nil,
			options: FileManager.DirectoryEnumerationOptions = [], fileProc :FileProc) {
		// Setup
		let	keysUse = (keys ?? []) + [.isRegularFileKey]

		// Iterate all urls
		let	urls = try! contentsOfDirectory(at: url, includingPropertiesForKeys: keysUse, options: options)
		urls.forEach() {
			// Check folder/file
			if try! $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile! {
				// File
				fileProc($0, $0.subPath(relativeTo: url)!)
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func enumerateFilesDeep(in url :URL, includingPropertiesForKeys keys: [URLResourceKey]? = nil,
			options: FileManager.DirectoryEnumerationOptions = [], fileProc :FileProc) {
		// Setup
		let	keysUse = (keys ?? []) + [.isRegularFileKey]

		// Enumerate all files
		let	directoryEnumerator =
					enumerator(at: url, includingPropertiesForKeys: keysUse, options: options, errorHandler: nil)!
		for element in directoryEnumerator {
			// Setup
			let	childURL = element as! URL

			// Is regular file
			if try! childURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile! {
				// Call proc
				fileProc(childURL, childURL.subPath(relativeTo: url)!)
			}
		}
	}
}
