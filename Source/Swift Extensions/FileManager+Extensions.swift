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
	public func exists(_ folder :Folder) -> Bool { fileExists(atPath: folder.path) }

	//------------------------------------------------------------------------------------------------------------------
	public func exists(_ file :File) -> Bool { fileExists(atPath: file.path) }

	//------------------------------------------------------------------------------------------------------------------
	public func folder(for directory :SearchPathDirectory, in domain :SearchPathDomainMask = .userDomainMask) ->
			Folder {
		// Return folder
		return Folder(urls(for: directory, in: domain).first!)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func create(_ folder :Folder, withIntermediateDirectories :Bool = true,
			attributes: [FileAttributeKey : Any]? = nil) throws {
		// Check if already exists
		if !exists(folder) {
			// Create
			try createDirectory(at: folder.url, withIntermediateDirectories: withIntermediateDirectories,
					attributes: attributes)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func enumerateFolders(in folder :Folder, includingPropertiesForKeys keys: [URLResourceKey]? = nil,
			options: EnumerationOptions = [], isCancelledProc :IsCancelledProc = { false },
			folderProc :Folder.SubPathProc) {
		// Setup
		let	keysUse = (keys ?? []) + [.isRegularFileKey]

		// Iterate all urls
		var	urls = try! contentsOfDirectory(at: folder.url, includingPropertiesForKeys: keysUse, options: [])
		if options.contains(.sorted) { urls = urls.sorted(by: { $0.path < $1.path }) }
		for url in urls {
			// Check for cancelled
			if isCancelledProc() { return }

			// Check folder/file
			if !(try! url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile!) {
				// Folder
				autoreleasepool() { folderProc(Folder(url), url.lastPathComponent) }
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func enumerateFiles(in folder :Folder, includingPropertiesForKeys keys: [URLResourceKey]? = nil,
			options: EnumerationOptions = [], isCancelledProc :IsCancelledProc = { false },
			fileProc :File.SubPathProc) {
		// Setup
		let	keysUse = (keys ?? []) + [.isRegularFileKey]

		// Iterate all urls
		var	urls = try! contentsOfDirectory(at: folder.url, includingPropertiesForKeys: keysUse, options: [])
		if options.contains(.sorted) { urls = urls.sorted(by: { $0.path < $1.path }) }
		for url in urls {
			// Check for cancelled
			if isCancelledProc() { return }

			// Check folder/file
			if try! url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile! {
				// File
				autoreleasepool() { fileProc(File(url), url.lastPathComponent) }
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func enumerateFoldersFiles(in folder :Folder, includingPropertiesForKeys keys: [URLResourceKey]? = nil,
			options: EnumerationOptions = [], isCancelledProc :IsCancelledProc = { false },
			folderProc :Folder.SubPathProc, fileProc :File.SubPathProc) {
		// Setup
		let	keysUse = (keys ?? []) + [.isRegularFileKey]

		// Iterate all urls
		var	urls = try! contentsOfDirectory(at: folder.url, includingPropertiesForKeys: keysUse, options: [])
		if options.contains(.sorted) { urls = urls.sorted(by: { $0.path < $1.path }) }
		for url in urls {
			// Check for cancelled
			if isCancelledProc() { return }

			// Check folder/file
			if !(try! url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile!) {
				// Folder
				autoreleasepool() { folderProc(Folder(url), url.lastPathComponent) }
			} else {
				// File
				autoreleasepool() { fileProc(File(url), url.lastPathComponent) }
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func enumerateFoldersFilesDeep(in folder :Folder, includingPropertiesForKeys keys: [URLResourceKey]? = nil,
			options: EnumerationOptions = [], isCancelledProc :IsCancelledProc = { false },
			folderProc :Folder.SubPathDeepProc = { _,_ in .process }, fileProc :File.SubPathProc) {
		// Setup
		let	keysUse = (keys ?? []) + [.isRegularFileKey]

		// Enumerate
		enumerateFoldersFilesDeep(levels: 0, folder: folder, includingPropertiesForKeys: keysUse, options: options,
				isCancelledProc: isCancelledProc, folderProc: folderProc, fileProc: fileProc)
	}

	//------------------------------------------------------------------------------------------------------------------
	func remove(_ file :File) throws { try removeItem(at: file.url) }

	//------------------------------------------------------------------------------------------------------------------
	func remove(_ folder :Folder) throws { try removeItem(at: folder.url) }

	// Private methods
	//------------------------------------------------------------------------------------------------------------------
	private func enumerateFoldersFilesDeep(levels :Int, folder :Folder,
			includingPropertiesForKeys keys: [URLResourceKey], options: EnumerationOptions,
			isCancelledProc :IsCancelledProc, folderProc :Folder.SubPathDeepProc, fileProc :File.SubPathProc) {
		// Setup
		var	urls = try! contentsOfDirectory(at: folder.url, includingPropertiesForKeys: keys, options: [])
		if options.contains(.sorted) { urls.sort(by: { $0.path < $1.path }) }

		// Iterate URLs and process files
		var	folderURLs = [URL]()
		for url in urls {
			// Check for cancelled
			if isCancelledProc() { return }

			// Check folder/file
			if try! url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile! {
				// File
				autoreleasepool() { fileProc(File(url), url.path.lastPathComponentsSubPath(levels + 1)) }
			} else {
				// Folder
				folderURLs.append(url)
			}
		}

		// Process folders
		for url in folderURLs {
			// Check for cancelled
			if isCancelledProc() { return }

			// Call proc
			if autoreleasepool(
					invoking: { folderProc(Folder(url), url.path.lastPathComponentsSubPath(levels + 1)) }) == .process {
				// Process folder
				enumerateFoldersFilesDeep(levels: levels + 1, folder: Folder(url), includingPropertiesForKeys: keys,
						options: options, isCancelledProc: isCancelledProc, folderProc: folderProc, fileProc: fileProc)
			}
		}
	}
}
