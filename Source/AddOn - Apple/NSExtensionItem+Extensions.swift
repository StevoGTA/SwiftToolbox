//
//  NSExtensionItem+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 12/1/21.
//  Copyright © 2021 Stevo Brock. All rights reserved.
//

import AVFoundation
import UniformTypeIdentifiers

#if os(iOS)
	import UIKit
#else
	import AppKit
#endif

//----------------------------------------------------------------------------------------------------------------------
// MARK: NSExtensionItemError
enum NSExtensionItemError : Error {
	case couldNotLoad
	case couldNotIdentifyPhoto
	case couldNotIdentifyVideoAttachment
}

extension NSExtensionItemError : CustomStringConvertible, LocalizedError {

	// MARK: Properties
	public 	var	description :String { self.localizedDescription }
	public	var	errorDescription :String? {
						// What are we
						switch self {
							case .couldNotLoad:						return "Could not load"
							case .couldNotIdentifyPhoto:			return "Could not identify Photo"
							case .couldNotIdentifyVideoAttachment:	return "Could not identify Video Attachment"
						}
					}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: NSExtensionItem extension
extension NSExtensionItem {

	// MARK: - MediaItem
	class MediaItem : Equatable {

		// MARK: Properties
		let	id = UUID().uuidString

		let	typeDisplayName :String
		let	filename :String
		let	image :Image?

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		init(typeDisplayName :String, filename :String, image :Image?) {
			// Store
			self.typeDisplayName = typeDisplayName
			self.filename = filename
			self.image = image
		}

		// MARK: Equatable methods
		//--------------------------------------------------------------------------------------------------------------
		static func == (lhs :MediaItem, rhs :MediaItem) -> Bool { lhs.id == rhs.id }
	}

	//------------------------------------------------------------------------------------------------------------------
	// MARK: - LivePhotoBundleMediaItem
	class LivePhotoBundleMediaItem : MediaItem {

		// MARK: Properties
		let	photoData :Data

		let	videoAttachmentFilename :String
		let	videoAttachmentData :Data

		let	creationDate :Date
		let	modificationDate :Date

		// MARK: Class methods
		//--------------------------------------------------------------------------------------------------------------
		static fileprivate func canLoad(itemProvider :NSItemProvider) -> Bool {
			// Check if can load
			return itemProvider.hasItemConforming(to: .livePhotoBundle)
		}

		//--------------------------------------------------------------------------------------------------------------
		static fileprivate func load(itemProvider :NSItemProvider) async throws -> LivePhotoBundleMediaItem {
			// Load
			let	url = try await itemProvider.loadURL()

			// Find files
			let	urlBasePath = url.deletingPathExtension()
			var	photoFile :File?
			var	videoAttachmentFile :File?
			try FileManager.default.files(in: Folder(url))
					.forEach() {
						// Check base path
						if $0.url.deletingPathExtension() == urlBasePath {
							// Check extension
							if ["heic", "jpeg", "jpg", "png", "tif"].contains($0.extension) {
								// URL is a photo
								photoFile = $0
							} else if ["m4v", "mov"].contains($0.extension) {
								// URL is a video
								videoAttachmentFile = $0
							}
						}
					}

			// Check results
			guard let photoFile = photoFile else { throw NSExtensionItemError.couldNotIdentifyPhoto }
			guard let videoAttachmentFile = videoAttachmentFile else
				{ throw NSExtensionItemError.couldNotIdentifyVideoAttachment }

			// Load
			let	photoData = try FileReader.contentsAsData(of: photoFile)
			let	videoAttachmentFilename =
						videoAttachmentFile
								.name
								.deletingPathExtension
								.appending(pathExtension: videoAttachmentFile.extension?.lowercased() ?? "")
			let	videoAttachmentData = try FileReader.contentsAsData(of: videoAttachmentFile)

			return LivePhotoBundleMediaItem(filename: photoFile.name, image: Image(photoData), photoData: photoData,
					videoAttachmentFilename: videoAttachmentFilename, videoAttachmentData: videoAttachmentData,
					creationDate: photoFile.creationDate, modificationDate: photoFile.modificationDate)
		}

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		init(filename :String, image :Image?, photoData :Data, videoAttachmentFilename :String,
				videoAttachmentData :Data, creationDate :Date, modificationDate :Date) {
			// Store
			self.photoData = photoData

			self.videoAttachmentFilename = videoAttachmentFilename
			self.videoAttachmentData = videoAttachmentData

			self.creationDate = creationDate
			self.modificationDate = modificationDate

			// Do super
			super.init(typeDisplayName: "Live Photo", filename: filename, image: image)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	// MARK: - PhotoMediaItem
	class PhotoMediaItem : MediaItem {

		// MARK: Properties
		let	data :Data

		let	creationDate :Date?
		let	modificationDate :Date?

		// MARK: Class methods
		//--------------------------------------------------------------------------------------------------------------
		static fileprivate func canLoad(itemProvider :NSItemProvider) -> Bool {
			// Check if can load
			return itemProvider.hasItemConforming(to: .image)
		}

		//--------------------------------------------------------------------------------------------------------------
		static fileprivate func load(itemProvider :NSItemProvider) async throws -> PhotoMediaItem {
			// Prefer the ORIGINAL file when the provider exposes one via its file URL.  Some sources (notably Finder
			//	on macOS 26+) hand share extensions a transcoded PNG as the image representation while still exposing
			//	the untouched original (HEIC, etc.) through "public.file-url" - loading that preserves the real bytes,
			//	the EXIF/XMP metadata, and the original filename.
			if itemProvider.hasItemConforming(to: .fileURL),
					let url = try? await itemProvider.loadURL() {
				// Load the untouched original file
				return try load(fromOriginalFile: File(url))
			}

			return try await loadImageRepresentation(itemProvider: itemProvider)
		}

		//--------------------------------------------------------------------------------------------------------------
		static private func load(fromOriginalFile file :File) throws -> PhotoMediaItem {
			// Access the original (may be security-scoped when delivered by a share)
			let	url = file.url
			let	didStartAccess = url.startAccessingSecurityScopedResource()
			defer { if didStartAccess { url.stopAccessingSecurityScopedResource() } }

			// The original file preserves its real bytes, metadata, and filename
			let	data = try FileReader.contentsAsData(of: file)

			return PhotoMediaItem(filename: file.name, image: Image(data), data: data, creationDate: file.creationDate,
					modificationDate: file.modificationDate)
		}

		//--------------------------------------------------------------------------------------------------------------
		static private func loadImageRepresentation(itemProvider :NSItemProvider) async throws -> PhotoMediaItem {
			// Determine the most specific concrete image type this provider holds - preserving EXIF/XMP metadata and
			//	the original filename - instead of transcoding to PNG.
			let	imageContentType = itemProvider.bestConcreteImageContentType ?? .image
			let	fileExtension = imageContentType.preferredFilenameExtension

			// Try to preserve the original filename
			let	suggestedFilename =
						(itemProvider.suggestedName != nil) ?
								((fileExtension != nil) ?
										itemProvider.suggestedName!.deletingPathExtension
												.appending(pathExtension: fileExtension!) :
										itemProvider.suggestedName!) :
								nil

			// Try as a file first - the file only exists for the duration of the proc, so read it there
			if let photoMediaItem =
					try? await itemProvider.loadFileRepresentation(for: imageContentType,
							proc: { file -> PhotoMediaItem in
								// Load data
								let	data = try FileReader.contentsAsData(of: file)

								// Create image
								var	image = Image(data)
#if os(macOS)
								// Check if succeeded
								if image.cgImage == nil,
										let nsImage = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as?
												NSImage {
									// Loaded as PLIST
									image = Image(nsImage)
								}
#endif

								return PhotoMediaItem(filename: suggestedFilename ?? file.name, image: image,
										data: data, creationDate: file.creationDate,
										modificationDate: file.modificationDate)
							}) {

				return photoMediaItem
			}

			// Could not load as file - load as data (no file to read dates from)
			let	data = try await itemProvider.loadDataRepresentation(for: imageContentType)

			return PhotoMediaItem(
					filename: suggestedFilename ?? "Untitled".appending(pathExtension: fileExtension ?? ""),
					image: Image(data), data: data, creationDate: nil, modificationDate: nil)
		}

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		init(filename :String, image :Image?, data :Data, creationDate :Date?, modificationDate :Date?) {
			// Store
			self.data = data

			self.creationDate = creationDate
			self.modificationDate = modificationDate

			// Do super
			super.init(typeDisplayName: "Photo", filename: filename, image: image)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	// MARK: - URLMediaItem
	class URLMediaItem : MediaItem {

		// MARK: Properties
		let	data :Data

		// MARK: Class methods
		//--------------------------------------------------------------------------------------------------------------
		static fileprivate func canLoad(itemProvider :NSItemProvider) -> Bool {
			// Check if can load
			return itemProvider.hasItemConforming(to: .url)
		}

		//--------------------------------------------------------------------------------------------------------------
		static fileprivate func load(itemProvider :NSItemProvider) async throws -> URLMediaItem {
			// Load
			let	url = try await itemProvider.loadURL()

			// Retrieve
			let	(data, _) = try await URLSession.shared.data(from: url)

			return URLMediaItem(filename: url.lastPathComponent, image: Image(data), data: data)
		}

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		init(filename :String, image :Image?, data :Data) {
			// Store
			self.data = data

			// Do super
			super.init(typeDisplayName: "Photo", filename: filename, image: image)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	// MARK: - VideoMediaItem
	class VideoMediaItem : MediaItem {

		// MARK: Properties
		let	file :File

		let	creationDate :Date?

		// MARK: Class methods
		//--------------------------------------------------------------------------------------------------------------
		static fileprivate func canLoad(itemProvider :NSItemProvider) -> Bool {
			// Check if can load
			return itemProvider.hasItemConforming(to: .video) || itemProvider.hasItemConforming(to: .quickTimeMovie) ||
					itemProvider.hasItemConforming(to: .mpeg4Movie) || itemProvider.hasItemConforming(to: .m4v)
		}

		//--------------------------------------------------------------------------------------------------------------
		static fileprivate func load(itemProvider :NSItemProvider) async throws -> VideoMediaItem {
			// Load
			let	url = try await itemProvider.loadURL()

			// Setup
			let	file = File(url)

			let	asset = AVURLAsset(url: url)
			let	duration = try await asset.load(.duration)

			var	creationDate :Date?
			if let creationDateMetadataItem = try? await asset.load(.creationDate) {
				// Have metadata item
				creationDate = try? await creationDateMetadataItem.load(.dateValue)
			}

			let	assetImageGenerator = AVAssetImageGenerator(asset: asset)
			assetImageGenerator.appliesPreferredTrackTransform = true

			let	cgImage =
						try? await assetImageGenerator.image(
								at: CMTime(value: duration.value / 2, timescale: duration.timescale)).image

			return VideoMediaItem(filename: file.name, image: cgImage.map({ Image($0) }), file: file,
					creationDate: creationDate)
		}

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		init(filename :String, image :Image?, file :File, creationDate :Date?) {
			// Store
			self.file = file
			self.creationDate = creationDate

			// Do super
			super.init(typeDisplayName: "Video", filename: filename, image: image)
		}
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func loadMediaItems() async -> (mediaItems :[MediaItem], errors :[Error]) {
		// Setup
		let	attachments = self.attachments ?? []

		return await withTaskGroup(of: (Int, Result<MediaItem, Error>?).self) { taskGroup in
			// Add a task per attachment
			attachments.enumerated().forEach() { index, itemProvider in
				// Add task
				taskGroup.addTask() {
					// Catch errors
					do {
						// Check what can be loaded
						if PhotoMediaItem.canLoad(itemProvider: itemProvider) {
							// Can load as PhotoMediaItem
							return (index, .success(try await PhotoMediaItem.load(itemProvider: itemProvider)))
						} else if VideoMediaItem.canLoad(itemProvider: itemProvider) {
							// Can load as VideoMediaItem
							return (index, .success(try await VideoMediaItem.load(itemProvider: itemProvider)))
						} else if LivePhotoBundleMediaItem.canLoad(itemProvider: itemProvider) {
							// Can load as LivePhotoBundleMediaItem
							return (index,
									.success(try await LivePhotoBundleMediaItem.load(itemProvider: itemProvider)))
						} else if URLMediaItem.canLoad(itemProvider: itemProvider) {
							// Can load as URLMediaItem
							return (index, .success(try await URLMediaItem.load(itemProvider: itemProvider)))
						} else {
							// Not something we load
							return (index, nil)
						}
					} catch {
						// Error
						return (index, .failure(error))
					}
				}
			}

			// Collect
			var	resultsByIndex = [Int : Result<MediaItem, Error>]()
			for await (index, result) in taskGroup {
				// Store
				resultsByIndex[index] = result
			}

			// Compose in attachment order
			var	mediaItems = [MediaItem]()
			var	errors = [Error]()
			for index in 0..<attachments.count {
				// Check result
				switch resultsByIndex[index] {
					case .success(let mediaItem)?:	mediaItems.append(mediaItem)
					case .failure(let error)?:		errors.append(error)
					case nil:						break
				}
			}

			return (mediaItems, errors)
		}
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - NSItemProvider extension
fileprivate extension NSItemProvider {

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func loadURL() async throws -> URL {
		// Warp to async world...
		try await withCheckedThrowingContinuation() { continuation in
			// Load
			_ = loadObject(ofClass: URL.self) { url, error in
				// Handle results
				if let url = url {
					// Success
					continuation.resume(returning: url)
				} else {
					// Error
					continuation.resume(throwing: error ?? NSExtensionItemError.couldNotLoad)
				}
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func loadFileRepresentation<T>(for contentType :UTType, proc :@escaping (_ file :File) throws -> T) async throws
			-> T {
		// Warp to async world...
		try await withCheckedThrowingContinuation() { continuation in
			// Load
			_ = loadFileRepresentation(forTypeIdentifier: contentType.identifier) { url, error in
				// Handle results
				if let url = url {
					// Success - process while the file exists
					continuation.resume(with: Result(catching: { try proc(File(url)) }))
				} else {
					// Error
					continuation.resume(throwing: error ?? NSExtensionItemError.couldNotLoad)
				}
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func loadDataRepresentation(for contentType :UTType) async throws -> Data {
		// Warp to async world...
		try await withCheckedThrowingContinuation() { continuation in
			// Load
			_ = loadDataRepresentation(forTypeIdentifier: contentType.identifier) { data, error in
				// Handle results
				if let data = data {
					// Success
					continuation.resume(returning: data)
				} else {
					// Error
					continuation.resume(throwing: error ?? NSExtensionItemError.couldNotLoad)
				}
			}
		}
	}
}
