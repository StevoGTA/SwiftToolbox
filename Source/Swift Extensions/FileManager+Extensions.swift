//
//  FileManager+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 10/26/19.
//  Copyright © 2019 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: Local procs
#if os(Linux)
	func autoreleasepool<Result>(invoking body: () throws -> Result) rethrows -> Result { try body() }
#endif

//----------------------------------------------------------------------------------------------------------------------
// MARK: - FileManager extension
extension FileManager {

	// MARK: Types
	public struct EnumerationOptions : OptionSet {

		// MARK: Properties
		static	public	let	sort = EnumerationOptions(rawValue: 1 << 0)
		static	public	let	skipHidden = EnumerationOptions(rawValue: 1 << 1)
		static	public	let	skipPackageContents = EnumerationOptions(rawValue: 1 << 2)
		static	public	let	followSymlinks = EnumerationOptions(rawValue: 1 << 3)

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
			try enumerateFoldersFilesDeep(folder: folder, includingPropertiesForKeys: keys ?? [],
					enumerationOptions: enumerationOptions, isCancelledProc: { false },
					folderProc: { folders.append($0); _ = $1; return .process }, fileProc: { _,_ in })
		} else {
			// Shallow
			try enumerateFolders(in: folder, includingPropertiesForKeys: keys, enumerationOptions: enumerationOptions)
				{ folders.append($0); _ = $1 }
			if enumerationOptions.contains(.sort) { folders = folders.sorted() }
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
			try enumerateFoldersFilesDeep(folder: folder, includingPropertiesForKeys: keys ?? [],
					enumerationOptions: enumerationOptions, isCancelledProc: { false }, folderProc: { _,_ in .process },
					fileProc: { files.append($0); _ = $1 })
		} else {
			// Shallow
			try enumerateFiles(in: folder, includingPropertiesForKeys: keys, enumerationOptions: enumerationOptions)
				{ files.append($0); _ = $1 }
			if enumerationOptions.contains(.sort) { files = files.sorted() }
		}

		return files
	}

	//------------------------------------------------------------------------------------------------------------------
	public func enumerateFoldersFilesDeep(in folder :Folder, includingPropertiesForKeys keys: [URLResourceKey]? = nil,
			enumerationOptions: EnumerationOptions = [], isCancelledProc :IsCancelledProc = { false },
			folderProc :Folder.SubPathDeepProc = { _,_ in .process }, fileProc :File.SubPathProc = { _,_ in }) throws {
		// Enumerate
		try enumerateFoldersFilesDeep(folder: folder, includingPropertiesForKeys: keys ?? [],
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
		let	keysUse = (keys ?? []) + [.isRegularFileKey, .isSymbolicLinkKey]

		// Collect URLs
		var	urls =
					try contentsOfDirectory(at: folder.url, includingPropertiesForKeys: keysUse,
							options: enumerationOptions.contains(.skipHidden) ? [.skipsHiddenFiles] : [])

		// Filter out files
		urls = urls.filter({ $0.isDirectory })

		// Check if sorting
		if enumerationOptions.contains(.sort) { urls = urls.sortedByLastPathComponent() }

		// Process each URL
		for url in urls {
			// Check for cancelled
			if isCancelledProc() { return }

			// Call proc
			autoreleasepool() { folderProc(Folder(url), url.lastPathComponent) }
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func enumerateFiles(in folder :Folder, includingPropertiesForKeys keys: [URLResourceKey]? = nil,
			enumerationOptions: EnumerationOptions = [], isCancelledProc :IsCancelledProc = { false },
			fileProc :File.SubPathProc) throws {
		// Setup
		let	keysUse = (keys ?? []) + [.isRegularFileKey, .isSymbolicLinkKey]

		// Collect URLs
		var	urls =
					try contentsOfDirectory(at: folder.url, includingPropertiesForKeys: keysUse,
							options: enumerationOptions.contains(.skipHidden) ? [.skipsHiddenFiles] : [])

		// Filter out folders
		urls = urls.filter({ $0.isFile })

		// Check if sorting
		if enumerationOptions.contains(.sort) { urls = urls.sortedByLastPathComponent() }

		// Process each URL
		for url in urls {
			// Check for cancelled
			if isCancelledProc() { return }

			// Call proc
			autoreleasepool() { fileProc(File(url), url.lastPathComponent) }
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func enumerateFoldersFiles(in folder :Folder, includingPropertiesForKeys keys: [URLResourceKey]? = nil,
			enumerationOptions: EnumerationOptions = [], isCancelledProc :IsCancelledProc = { false },
			folderProc :Folder.SubPathProc, fileProc :File.SubPathProc) throws {
		// Setup
		let	keysUse = (keys ?? []) + [.isRegularFileKey, .isSymbolicLinkKey]

		// Collect URLs
		var	urls =
					try contentsOfDirectory(at: folder.url, includingPropertiesForKeys: keysUse,
							options: enumerationOptions.contains(.skipHidden) ? [.skipsHiddenFiles] : [])

		// Check if sorting
		if enumerationOptions.contains(.sort) { urls = urls.sortedByLastPathComponent() }

		// Process each URL
		for url in urls {
			// Check for cancelled
			if isCancelledProc() { return }

			// Check folder/file
			if url.isFolder {
				// Folder
				autoreleasepool() { folderProc(Folder(url), url.lastPathComponent) }
			} else {
				// File
				autoreleasepool() { fileProc(File(url), url.lastPathComponent) }
			}
		}
	}

	// Private methods
	//------------------------------------------------------------------------------------------------------------------
	private func enumerateFoldersFilesDeep(level :Int = 0, subPathPrefix :String = "", folder :Folder,
			includingPropertiesForKeys keys: [URLResourceKey], enumerationOptions: EnumerationOptions,
			isCancelledProc :IsCancelledProc, folderProc :Folder.SubPathDeepProc, fileProc :File.SubPathProc) throws {
		// Setup
		let	keysUse = keys + [.isRegularFileKey, .isSymbolicLinkKey]

		var	directoryEnumerationOptions :FileManager.DirectoryEnumerationOptions = []
		if enumerationOptions.contains(.skipHidden) { directoryEnumerationOptions.formUnion(.skipsHiddenFiles) }
		if enumerationOptions.contains(.skipPackageContents)
				{ directoryEnumerationOptions.formUnion(.skipsPackageDescendants) }

		// Collect URLs
		let	url = (folder.url.isSymbolicLink ?? false) ? folder.url.urlByResolvingLinks : folder.url
		var	urls =
					try contentsOfDirectory(at: url, includingPropertiesForKeys: keysUse,
							options: directoryEnumerationOptions)

		// Check if sorting
		if enumerationOptions.contains(.sort) { urls = urls.sortedByLastPathComponent() }

		// Process each URL, collect folders, and process files
		var	folderURLs = [URL]()
		for url in urls {
			// Check for cancelled
			if isCancelledProc() { return }

			// Check folder/file
			if url.isFolder {
				// Folder
				folderURLs.append(url)
			} else {
				// File
				autoreleasepool() {
					// Process file
					let	isSymbolicLink = url.isSymbolicLink ?? false
					if isSymbolicLink && enumerationOptions.contains(.followSymlinks) {
						// Is symlink and following
						fileProc(File(url.urlByResolvingLinks),
								subPathPrefix.appending(pathComponent: url.path.lastPathComponentsSubPath(level + 1)))
					} else {
						// Is not symlink or not following
						fileProc(File(url), subPathPrefix.appending(url.path.lastPathComponentsSubPath(level + 1)))
					}
				}
			}
		}

		// Process folders
		for url in folderURLs {
			// Check for cancelled
			if isCancelledProc() { return }

			// Call proc
			let	urlSubPathPrefix = subPathPrefix.appending(pathComponent: url.path.lastPathComponentsSubPath(level + 1))
			if autoreleasepool(invoking: { folderProc(Folder(url), urlSubPathPrefix) }) == .process {
				// Process folder
				let	isSymbolicLink = url.isSymbolicLink ?? false
				if isSymbolicLink && enumerationOptions.contains(.followSymlinks) {
					// Is symlink and following
					try enumerateFoldersFilesDeep(subPathPrefix: urlSubPathPrefix,
							folder: Folder(url.urlByResolvingLinks), includingPropertiesForKeys: keys,
							enumerationOptions: enumerationOptions, isCancelledProc: isCancelledProc,
							folderProc: folderProc, fileProc: fileProc)
				} else if !isSymbolicLink {
					// Continue
					try enumerateFoldersFilesDeep(level: level + 1, subPathPrefix: subPathPrefix, folder: Folder(url),
							includingPropertiesForKeys: keys, enumerationOptions: enumerationOptions,
							isCancelledProc: isCancelledProc, folderProc: folderProc, fileProc: fileProc)
				}
			}
		}
	}
}
