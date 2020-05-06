//
//  ImageCache.swift
//  Swift Toolbox
//
//  Created by Stevo on 4/20/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: ImageCache
protocol ImageCache {

	// MARK: Instance methods
	func store(_ data :Data, for identifier :String) throws
	func retrieveData(for identifier :String) throws -> Data?
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - MemoryImageCache
class MemoryImageCache :ImageCache {

	// MARK: Types
	class ImageInfo {

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

	private	var	map = LockingDictionary<String, ImageInfo>()
	private	var	mapSetLock = Lock()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(sizeLimit :Int64? = nil) {
		// Store
		self.sizeLimit = sizeLimit
	}

	// MARK: ImageCache methods
	//------------------------------------------------------------------------------------------------------------------
	func store(_ data :Data, for identifier :String) throws {
		// Update map
		self.mapSetLock.perform() {
			// Store new image info
			self.map.set(ImageInfo(data: data, identifier: identifier), for: identifier)

			// Check if pruning
			if let sizeLimit = self.sizeLimit {
				// Collect info
				let	imageInfos = self.map.values
				var	totalSize = imageInfos.reduce(0, { $0 + $1.data.count })
				if totalSize > sizeLimit {
					// Need to prune
					var	imageInfosSorted = imageInfos.sorted() { $0.lastAccessedDate < $1.lastAccessedDate }
					while totalSize > sizeLimit {
						// Remove the last
						let	imageInfo = imageInfosSorted.removeFirst()
						totalSize -= imageInfo.data.count
						self.map.remove(imageInfo.identifier)
					}
				}
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func retrieveData(for identifier :String) throws -> Data? {
		// Retrieve image info
		let	imageInfo = self.map.value(for: identifier)
		imageInfo?.noteAccessed()

		return imageInfo?.data
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - FilesystemImageCache
class FilesystemImageCache :ImageCache {

	// MARK: Types
	class ImageInfo {

		// MARK: Properties
						let	file :File
						let	identifier :String
						let	size :Int64

		private(set)	var	lastAccessedDate :Date

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		init(file :File, identifier :String, data :Data) throws {
			// Store
			self.file = file
			self.identifier = identifier
			self.size = Int64(data.count)
			self.lastAccessedDate = Date()

			// Write
			try self.file.setContents(data)
			try self.file.setExtendedAttribute(name: "lastAccessedDate", value: self.lastAccessedDate.rfc3339Extended)
		}

		//--------------------------------------------------------------------------------------------------------------
		init(url :URL, identifier :String) {
			// Setup
			self.file = File(url)
			self.identifier = identifier
			self.size = url.fileSize ?? 0

			if let lastAccessedDateString = try? file.stringForExtendedAttributeName(name: "lastAccessedDate") {
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
			try self.file.setExtendedAttribute(name: "lastAccessedDate", value: self.lastAccessedDate.rfc3339Extended)
		}
	}

	// MARK: Properties
	private	let	folderURL :URL
	private	let	sizeLimit :Int64?

	private	var	map = LockingDictionary<String, ImageInfo>()
	private	var	mapSetLock = Lock()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(folderURL :URL, sizeLimit :Int64? = nil) throws {
		// Store
		self.folderURL = folderURL
		self.sizeLimit = sizeLimit

		// Setup
		try FileManager.default.createDirectory(at: self.folderURL, withIntermediateDirectories: true, attributes: nil)

		// Load existing files
		FileManager.default.enumerateFiles(in: self.folderURL, includingPropertiesForKeys: [.fileSizeKey]) {
			// Update map
			self.map.set(ImageInfo(url: $0, identifier: $1), for: $1)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	init(folderName :String, sizeLimit :Int64? = nil) throws {
		// Setup
		let	path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
		let	url = URL(fileURLWithPath: path)

		// Store
		self.sizeLimit = sizeLimit
		self.folderURL = url.appendingPathComponent(folderName)

		// Setup
		try FileManager.default.createDirectory(at: self.folderURL, withIntermediateDirectories: true, attributes: nil)

		// Load existing files
		FileManager.default.enumerateFiles(in: self.folderURL, includingPropertiesForKeys: [.fileSizeKey]) {
			// Update map
			self.map.set(ImageInfo(url: $0, identifier: $1), for: $1)
		}
	}

	// MARK: ImageCache methods
	//------------------------------------------------------------------------------------------------------------------
	func store(_ data :Data, for identifier :String) throws {
		// Setup
		let	file = File(self.folderURL.appendingPathComponent(identifier))
		let	imageInfo = try ImageInfo(file: file, identifier: identifier, data: data)

		// Update map
		try self.mapSetLock.perform() {
			// Store new image info
			self.map.set(imageInfo, for: identifier)

			// Check if pruning
			if let sizeLimit = self.sizeLimit {
				// Collect info
				let	imageInfos = self.map.values
				var	totalSize = imageInfos.reduce(0, { $0 + $1.size })
				if totalSize > sizeLimit {
					// Need to prune
					var	imageInfosSorted = imageInfos.sorted() { $0.lastAccessedDate < $1.lastAccessedDate }
					while totalSize > sizeLimit {
						// Remove the last
						let	imageInfo = imageInfosSorted.removeFirst()
						try imageInfo.file.remove()
						totalSize -= imageInfo.size
						self.map.remove(imageInfo.identifier)
					}
				}
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func retrieveData(for identifier :String) throws -> Data? {
		// Retrieve image info
		let	imageInfo = self.map.value(for: identifier)
		try imageInfo?.noteAccessed()

		return try imageInfo?.file.contentsAsData()
	}
}
