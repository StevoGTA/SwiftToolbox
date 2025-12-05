//
//  DataCache.swift
//  Swift Toolbox
//
//  Created by Stevo on 4/20/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: DataCache
protocol DataCache {

	// MARK: Instance methods
	func store(_ data :Data, for identifier :String) throws
	func data(for identifier :String) throws -> Data?
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - MemoryDataCache
class MemoryDataCache : DataCache {

	// MARK: Types
	class ItemInfo {

		// MARK: Properties
						let	data :Data
						let	identifier :String

		private(set)	var	lastAccessedDate = Date()

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		init(data :Data, identifier :String) {
			// Store
			self.data = data
			self.identifier = identifier
		}

		// MARK: Instance methods
		//--------------------------------------------------------------------------------------------------------------
		func noteAccessed() { self.lastAccessedDate = Date() }
	}

	// MARK: Properties
	private	let	sizeLimit :Int64?
	private	let	mapLock = ReadPreferringReadWriteLock()

	private	var	map = [String : ItemInfo]()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(sizeLimit :Int64? = nil) {
		// Store
		self.sizeLimit = sizeLimit
	}

	// MARK: DataCache methods
	//------------------------------------------------------------------------------------------------------------------
	func store(_ data :Data, for identifier :String) throws {
		// Update map
		self.mapLock.write() {
			// Store new item info
			self.map[identifier] = ItemInfo(data: data, identifier: identifier)

			// Check if pruning
			if let sizeLimit = self.sizeLimit {
				// Collect info
				let	itemInfos = self.map.values
				var	totalSize = itemInfos.reduce(0, { $0 + $1.data.count })
				if totalSize > sizeLimit {
					// Need to prune
					var	itemInfosSorted = itemInfos.sorted() { $0.lastAccessedDate < $1.lastAccessedDate }
					while totalSize > sizeLimit {
						// Remove the first
						let	itemInfo = itemInfosSorted.removeFirst()
						totalSize -= itemInfo.data.count
						self.map[itemInfo.identifier] = nil
					}
				}
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func data(for identifier :String) throws -> Data? {
		// Retrieve item info
		let	itemInfo = self.mapLock.read() { self.map[identifier] }

		// Note accessed
		itemInfo?.noteAccessed()

		return itemInfo?.data
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - FilesystemDataCache
class FilesystemDataCache : DataCache {

	// MARK: Types
	class ItemInfo {

		// MARK: Properties
						let	file :File
						let	size :Int64

		private(set)	var	lastAccessedDate :Date

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		init(file :File, data :Data) throws {
			// Store
			self.file = file
			self.size = Int64(data.count)
			self.lastAccessedDate = Date()

			// Write
			try FileWriter.setContents(of: self.file, to: data)
			try self.file.set(self.lastAccessedDate.rfc3339ExtendedString, forExtendedAttributeNamed: "lastAccessedDate")
		}

		//--------------------------------------------------------------------------------------------------------------
		init(file :File) {
			// Setup
			self.file = file
			self.size = file.size ?? 0

			// Retrieve last accessed date from filesystem
			if let lastAccessedDateString =
					try? file.string(forExtendedAttributeNamed: "lastAccessedDate", maxByteCountIfPresent: 1024) {
				// Have last accessed date string
				self.lastAccessedDate = Date(fromRFC3339Extended: lastAccessedDateString)!
			} else {
				// Assume is now
				self.lastAccessedDate = Date()
			}
		}

		// MARK: Instance methods
		//--------------------------------------------------------------------------------------------------------------
		func noteAccessed() throws {
			// Update internals
			self.lastAccessedDate = Date()

			// Update filesystem
			try self.file.set(self.lastAccessedDate.rfc3339ExtendedString, forExtendedAttributeNamed: "lastAccessedDate")
		}
	}

	// MARK: Properties
	private	let	folder :Folder
	private	let	sizeLimit :Int64?
	private	let	mapLock = ReadPreferringReadWriteLock()

	private	var	map = [String : ItemInfo]()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(folder :Folder, sizeLimit :Int64? = nil) throws {
		// Store
		self.folder = folder
		self.sizeLimit = sizeLimit

		// Setup
		try FileManager.default.createDirectory(at: self.folder.url, withIntermediateDirectories: true, attributes: nil)

		// Note existing files
		try FileManager.default.enumerateFiles(in: self.folder, includingPropertiesForKeys: [.fileSizeKey]) {
			// Update map
			self.map[$1] = ItemInfo(file: $0)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	init(folderName :String, sizeLimit :Int64? = nil) throws {
		// Setup
		let	cachesFolder = FileManager.default.folder(for: .cachesDirectory)
		self.folder = !folderName.isEmpty ? cachesFolder.folder(withSubPath: folderName) : cachesFolder

		// Store
		self.sizeLimit = sizeLimit

		// Setup
		try FileManager.default.createDirectory(at: self.folder.url, withIntermediateDirectories: true, attributes: nil)

		// Note existing files
		try FileManager.default.enumerateFiles(in: self.folder, includingPropertiesForKeys: [.fileSizeKey]) {
			// Update map
			self.map[$1] = ItemInfo(file: $0)
		}
	}

	// MARK: DataCache methods
	//------------------------------------------------------------------------------------------------------------------
	func store(_ data :Data, for identifier :String) throws {
		// Setup
		let	file = self.folder.file(withSubPath: identifier)

		// Create folder if needed
		try FileManager.default.create(file.folder)

		// Create ItemInfo which will write the data
		let	itemInfo = try ItemInfo(file: file, data: data)

		// Update map
		try self.mapLock.write() {
			// Store new item info
			self.map[identifier] = itemInfo

			// Check if pruning
			if let sizeLimit = self.sizeLimit {
				// Collect info
				let	itemInfos = self.map.values
				var	totalSize = itemInfos.reduce(0, { $0 + $1.size })
				if totalSize > sizeLimit {
					// Need to prune
					var	itemInfosSorted = itemInfos.sorted() { $0.lastAccessedDate < $1.lastAccessedDate }
					while totalSize > sizeLimit {
						// Remove the first
						let	itemInfo = itemInfosSorted.removeFirst()
						try FileManager.default.remove(itemInfo.file)
						totalSize -= itemInfo.size
						self.map[itemInfo.file.name] = nil
					}
				}
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func data(for identifier :String) throws -> Data? {
		// Retrieve item info
		let	itemInfo = self.mapLock.read() { self.map[identifier] }

		// Note accessed
		try itemInfo?.noteAccessed()

		return try itemInfo?.file.contentsAsData()
	}
}
