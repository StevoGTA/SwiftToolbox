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
	public struct EnumerationOptions : OptionSet {

		// MARK: Properties
		static	public	let	sorted = EnumerationOptions(rawValue: 1 << 0)
		static	public	let	skipHiddenFiles = EnumerationOptions(rawValue: 1 << 1)

				public	let	rawValue :Int

		// MARK: Lifecycle methods
		public init(rawValue :Int) { self.rawValue = rawValue }
	}

	public typealias IsCancelledProc = () -> Bool

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
	public func folders(in folder :Folder, includingPropertiesForKeys keys: [URLResourceKey]? = nil,
			enumerationOptions: EnumerationOptions = [], deep :Bool = false) throws -> [Folder] {
		// Setup
		var	folders = [Folder]()

		// Check deep
		if deep {
			// Deep
			try enumerateFoldersFilesDeep(in: folder, includingPropertiesForKeys: keys,
					enumerationOptions: enumerationOptions, folderProc: { folders.append($0); _ = $1; return .process })
		} else {
			// Shallow
			try enumerateFolders(in: folder, includingPropertiesForKeys: keys, enumerationOptions: enumerationOptions)
				{ folders.append($0); _ = $1 }
		}

		return folders
	}

	//------------------------------------------------------------------------------------------------------------------
	public func files(in folder :Folder, includingPropertiesForKeys keys: [URLResourceKey]? = nil,
			enumerationOptions: EnumerationOptions = [], deep :Bool = false) throws -> [File] {
		// Setup
		var	files = [File]()

		// Check deep
		if deep {
			// Deep
			try enumerateFoldersFilesDeep(in: folder, includingPropertiesForKeys: keys,
					enumerationOptions: enumerationOptions, fileProc: { files.append($0); _ = $1 })
		} else {
			// Shallow
			try enumerateFiles(in: folder, includingPropertiesForKeys: keys, enumerationOptions: enumerationOptions)
				{ files.append($0); _ = $1 }
		}

		return files
	}

	//------------------------------------------------------------------------------------------------------------------
	public func enumerateFoldersFilesDeep(in folder :Folder, includingPropertiesForKeys keys: [URLResourceKey]? = nil,
			enumerationOptions: EnumerationOptions = [], isCancelledProc :IsCancelledProc = { false },
			folderProc :Folder.SubPathDeepProc = { _,_ in .process }, fileProc :File.SubPathProc = { _,_ in }) throws {
		// Setup
		let	keysUse = (keys ?? []) + [.isRegularFileKey]

		// Enumerate
		try enumerateFoldersFilesDeep(levels: 0, folder: folder, includingPropertiesForKeys: keysUse,
				enumerationOptions: enumerationOptions, isCancelledProc: isCancelledProc, folderProc: folderProc,
				fileProc: fileProc)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func remove(_ file :File) throws { try removeItem(at: file.url) }

	//------------------------------------------------------------------------------------------------------------------
	public func remove(_ folder :Folder) throws { try removeItem(at: folder.url) }

	//------------------------------------------------------------------------------------------------------------------
	func enumerateFolders(in folder :Folder, includingPropertiesForKeys keys: [URLResourceKey]? = nil,
			enumerationOptions: EnumerationOptions = [], isCancelledProc :IsCancelledProc = { false },
			folderProc :Folder.SubPathProc) throws {
		// Setup
		let	keysUse = (keys ?? []) + [.isRegularFileKey]

		// Iterate all urls
		var	urls = try contentsOfDirectory(at: folder.url, includingPropertiesForKeys: keysUse, options: [])
		if enumerationOptions.contains(.sorted) { urls = urls.sorted(by: { $0.path < $1.path }) }
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
			enumerationOptions: EnumerationOptions = [], isCancelledProc :IsCancelledProc = { false },
			fileProc :File.SubPathProc) throws {
		// Setup
		var	keysUse = (keys ?? []) + [.isRegularFileKey]
		if enumerationOptions.contains(.skipHiddenFiles) { keysUse.append(.isHiddenKey) }

		// Iterate all urls
		var	urls = try contentsOfDirectory(at: folder.url, includingPropertiesForKeys: keysUse, options: [])
		if enumerationOptions.contains(.sorted) { urls = urls.sorted(by: { $0.path < $1.path }) }
		for url in urls {
			// Check for cancelled
			if isCancelledProc() { return }

			// Check folder/file
			if try! url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile! &&
					(!enumerationOptions.contains(.skipHiddenFiles) ||
							!(try! url.resourceValues(forKeys: [.isHiddenKey]).isHidden!)) {
				// File
				autoreleasepool() { fileProc(File(url), url.lastPathComponent) }
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func enumerateFoldersFiles(in folder :Folder, includingPropertiesForKeys keys: [URLResourceKey]? = nil,
			enumerationOptions: EnumerationOptions = [], isCancelledProc :IsCancelledProc = { false },
			folderProc :Folder.SubPathProc, fileProc :File.SubPathProc) throws {
		// Setup
		var	keysUse = (keys ?? []) + [.isRegularFileKey]
		if enumerationOptions.contains(.skipHiddenFiles) { keysUse.append(.isHiddenKey) }

		// Iterate all urls
		var	urls = try contentsOfDirectory(at: folder.url, includingPropertiesForKeys: keysUse, options: [])
		if enumerationOptions.contains(.sorted) { urls = urls.sorted(by: { $0.path < $1.path }) }
		for url in urls {
			// Check for cancelled
			if isCancelledProc() { return }

			// Check folder/file
			if !(try! url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile!) {
				// Folder
				autoreleasepool() { folderProc(Folder(url), url.lastPathComponent) }
			} else if !enumerationOptions.contains(.skipHiddenFiles) ||
					!(try! url.resourceValues(forKeys: [.isHiddenKey]).isHidden!) {
				// File
				autoreleasepool() { fileProc(File(url), url.lastPathComponent) }
			}
		}
	}

	// Private methods
	//------------------------------------------------------------------------------------------------------------------
	private func enumerateFoldersFilesDeep(levels :Int, folder :Folder,
			includingPropertiesForKeys keys: [URLResourceKey], enumerationOptions: EnumerationOptions,
			isCancelledProc :IsCancelledProc, folderProc :Folder.SubPathDeepProc, fileProc :File.SubPathProc) throws {
		// Setup
		var	keysUse = keys + [.isRegularFileKey]
		if enumerationOptions.contains(.skipHiddenFiles) { keysUse.append(.isHiddenKey) }

		var	urls = try contentsOfDirectory(at: folder.url, includingPropertiesForKeys: keysUse, options: [])
		if enumerationOptions.contains(.sorted) { urls.sort(by: { $0.path < $1.path }) }

		// Iterate URLs and process files
		var	folderURLs = [URL]()
		for url in urls {
			// Check for cancelled
			if isCancelledProc() { return }

			// Check folder/file
			if !(try! url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile!) {
				// Folder
				folderURLs.append(url)
			} else if !enumerationOptions.contains(.skipHiddenFiles) ||
					!(try! url.resourceValues(forKeys: [.isHiddenKey]).isHidden!) {
				// File
				autoreleasepool() { fileProc(File(url), url.path.lastPathComponentsSubPath(levels + 1)) }
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
				try enumerateFoldersFilesDeep(levels: levels + 1, folder: Folder(url), includingPropertiesForKeys: keys,
						enumerationOptions: enumerationOptions, isCancelledProc: isCancelledProc,
						folderProc: folderProc, fileProc: fileProc)
			}
		}
	}
}
