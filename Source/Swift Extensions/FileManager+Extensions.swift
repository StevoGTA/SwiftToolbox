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

	// MARK: Types
	struct EnumerationOptions : OptionSet {

		// MARK: Properties
		static	public	let	sorted = EnumerationOptions(rawValue: 1 << 0)

				public	let	rawValue :Int

		// MARK: Lifecycle methods
		init(rawValue :Int) { self.rawValue = rawValue }
	}

	// MARK: Types
	typealias FolderProc = (_ url :URL, _ subPath :String) -> Void

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func fileExists(at url :URL) -> Bool { fileExists(atPath: url.path) }

	//------------------------------------------------------------------------------------------------------------------
	func createFolder(at url :URL, attributes: [FileAttributeKey : Any]? = nil) throws {
		// Check if already exists
		if !fileExists(at: url) {
			// Create
			try createDirectory(at: url, withIntermediateDirectories: true, attributes: attributes)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func enumerateFoldersFiles(in url :URL, includingPropertiesForKeys keys: [URLResourceKey]? = nil,
			options: EnumerationOptions = [], folderProc :FolderProc, fileProc :File.SubPathProc) {
		// Setup
		let	keysUse = (keys ?? []) + [.isRegularFileKey]

		// Iterate all urls
		var	urls = try! contentsOfDirectory(at: url, includingPropertiesForKeys: keysUse, options: [])
		if options.contains(.sorted) { urls = urls.sorted(by: { $0.path < $1.path }) }
		urls.forEach() {
			// Check folder/file
			if !(try! $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile!) {
				// Folder
				folderProc($0, $0.subPath(relativeTo: url)!)
			} else {
				// File
				fileProc(File($0), $0.subPath(relativeTo: url)!)
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func enumerateFolders(in url :URL, includingPropertiesForKeys keys: [URLResourceKey]? = nil,
			options: EnumerationOptions = [], folderProc :FolderProc) {
		// Setup
		let	keysUse = (keys ?? []) + [.isRegularFileKey]

		// Iterate all urls
		var	urls = try! contentsOfDirectory(at: url, includingPropertiesForKeys: keysUse, options: [])
		if options.contains(.sorted) { urls = urls.sorted(by: { $0.path < $1.path }) }
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
			options: EnumerationOptions = [], fileProc :File.SubPathProc) {
		// Setup
		let	keysUse = (keys ?? []) + [.isRegularFileKey]

		// Iterate all urls
		var	urls = try! contentsOfDirectory(at: url, includingPropertiesForKeys: keysUse, options: [])
		if options.contains(.sorted) { urls = urls.sorted(by: { $0.path < $1.path }) }
		urls.forEach() {
			// Check folder/file
			if try! $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile! {
				// File
				fileProc(File($0), $0.lastPathComponent)
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func enumerateFilesDeep(in url :URL, includingPropertiesForKeys keys: [URLResourceKey]? = nil,
			options: EnumerationOptions = [], fileProc :File.SubPathProc) {
		// Setup
		let	keysUse = (keys ?? []) + [.isRegularFileKey]

		// Check options
		if options.contains(.sorted) {
			// Perform sorted
			enumerateFilesDeep(rootURL: url, url: url, includingPropertiesForKeys: keysUse, options: options,
					fileProc: fileProc)
		} else {
			// Perform
			// Enumerate all files
			let	directoryEnumerator =
						enumerator(at: url, includingPropertiesForKeys: keysUse, options: [], errorHandler: nil)!
			for element in directoryEnumerator {
				// Setup
				let	childURL = element as! URL

				// Is regular file
				if try! childURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile! {
					// Call proc
					fileProc(File(childURL), childURL.subPath(relativeTo: url)!)
				}
			}
		}
	}

	// Private methods
	//------------------------------------------------------------------------------------------------------------------
	private func enumerateFilesDeep(rootURL :URL, url :URL, includingPropertiesForKeys keys: [URLResourceKey],
			options: EnumerationOptions, fileProc :File.SubPathProc) {
		// Iterate all urls
		var	urls = try! contentsOfDirectory(at: url, includingPropertiesForKeys: keys, options: [])
		if options.contains(.sorted) { urls = urls.sorted(by: { $0.path < $1.path }) }
		urls.forEach() {
			// Check folder/file
			if try! $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile! {
				// File
				fileProc(File($0), $0.subPath(relativeTo: rootURL)!)
			} else {
				// Folder
				enumerateFilesDeep(rootURL: rootURL, url: $0, includingPropertiesForKeys: keys, options: options,
						fileProc: fileProc)
			}
		}
	}
}
