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

	typealias IsCancelledProc = () -> Bool

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
			options: EnumerationOptions = [], isCancelledProc :IsCancelledProc = { false },
			folderProc :Folder.SubPathProc, fileProc :File.SubPathProc) {
		// Setup
		let	keysUse = (keys ?? []) + [.isRegularFileKey]

		// Iterate all urls
		var	urls = try! contentsOfDirectory(at: url, includingPropertiesForKeys: keysUse, options: [])
		if options.contains(.sorted) { urls = urls.sorted(by: { $0.path < $1.path }) }
		for url in urls {
			// Check for cancelled
			if isCancelledProc() { return }

			// Check folder/file
			if !(try! url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile!) {
				// Folder
				folderProc(Folder(url), url.lastPathComponent)
			} else {
				// File
				fileProc(File(url), url.lastPathComponent)
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func enumerateFolders(in url :URL, includingPropertiesForKeys keys: [URLResourceKey]? = nil,
			options: EnumerationOptions = [], isCancelledProc :IsCancelledProc = { false },
			folderProc :Folder.SubPathProc) {
		// Setup
		let	keysUse = (keys ?? []) + [.isRegularFileKey]

		// Iterate all urls
		var	urls = try! contentsOfDirectory(at: url, includingPropertiesForKeys: keysUse, options: [])
		if options.contains(.sorted) { urls = urls.sorted(by: { $0.path < $1.path }) }
		for url in urls {
			// Check for cancelled
			if isCancelledProc() { return }

			// Check folder/file
			if !(try! url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile!) {
				// Folder
				folderProc(Folder(url), url.lastPathComponent)
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func enumerateFiles(in url :URL, includingPropertiesForKeys keys: [URLResourceKey]? = nil,
			options: EnumerationOptions = [], isCancelledProc :IsCancelledProc = { false },
			fileProc :File.SubPathProc) {
		// Setup
		let	keysUse = (keys ?? []) + [.isRegularFileKey]

		// Iterate all urls
		var	urls = try! contentsOfDirectory(at: url, includingPropertiesForKeys: keysUse, options: [])
		if options.contains(.sorted) { urls = urls.sorted(by: { $0.path < $1.path }) }
		for url in urls {
			// Check for cancelled
			if isCancelledProc() { return }

			// Check folder/file
			if try! url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile! {
				// File
				fileProc(File(url), url.lastPathComponent)
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func enumerateFilesDeep(in url :URL, includingPropertiesForKeys keys: [URLResourceKey]? = nil,
			options: EnumerationOptions = [], isCancelledProc :IsCancelledProc = { false },
			fileProc :File.SubPathProc) {
		// Setup
		let	keysUse = (keys ?? []) + [.isRegularFileKey]

		// Check options
		if options.contains(.sorted) {
			// Perform sorted
			enumerateFilesDeep(levels: 0, url: url, includingPropertiesForKeys: keysUse, options: options,
					isCancelledProc: isCancelledProc, fileProc: fileProc)
		} else {
			// Perform
			let	directoryEnumerator =
						enumerator(at: url, includingPropertiesForKeys: keysUse, options: [], errorHandler: nil)!
			for element in directoryEnumerator {
				// Check for cancelled
				if isCancelledProc() { return }

				// Is regular file
				let	childURL = element as! URL
				if try! childURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile! {
					// Call proc
					fileProc(File(childURL), childURL.path.lastPathComponentsSubPath(directoryEnumerator.level))
				}
			}
		}
	}

	// Private methods
	//------------------------------------------------------------------------------------------------------------------
	private func enumerateFilesDeep(levels :Int, url :URL, includingPropertiesForKeys keys: [URLResourceKey],
			options: EnumerationOptions, isCancelledProc :IsCancelledProc, fileProc :File.SubPathProc) {
		// Iterate all urls
		var	urls = try! contentsOfDirectory(at: url, includingPropertiesForKeys: keys, options: [])
		if options.contains(.sorted) { urls = urls.sorted(by: { $0.path < $1.path }) }
		for url in urls {
			// Check for cancelled
			if isCancelledProc() { return }

			// Check folder/file
			if try! url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile! {
				// File
				fileProc(File(url), url.path.lastPathComponentsSubPath(levels + 1))
			} else {
				// Folder
				enumerateFilesDeep(levels: levels + 1, url: url, includingPropertiesForKeys: keys, options: options,
						isCancelledProc: isCancelledProc, fileProc: fileProc)
			}
		}
	}
}
