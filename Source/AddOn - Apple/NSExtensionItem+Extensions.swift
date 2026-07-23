//
//  NSExtensionItem+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 12/1/21.
//  Copyright © 2021 Stevo Brock. All rights reserved.
//

import AVFoundation
import CoreServices
import UniformTypeIdentifiers

#if os(iOS)
	import UIKit
#else
	import AppKit
#endif

//----------------------------------------------------------------------------------------------------------------------
// MARK: NSExtensionItemError
enum NSExtensionItemError : Error {
	case couldNotIdentifyPhoto
	case couldNotIdentifyVideoAttachment
}

extension NSExtensionItemError : CustomStringConvertible, LocalizedError {

	// MARK: Properties
	public 	var	description :String { self.localizedDescription }
	public	var	errorDescription :String? {
						// What are we
						switch self {
							case .couldNotIdentifyPhoto: return "Could not identify Photo"
							case .couldNotIdentifyVideoAttachment: return "Could not identify Video Attachment"
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
					
					var	filename :String?
					var	image :Image?
					var	error :Error?
					var	typeDisplayName :String { self.typeDisplayNameInternal! }

					var	filenameDidChangeProc :(_ filename :String) -> Void = { _ in }

		fileprivate	var	typeDisplayNameInternal :String? { nil }

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		init() {}

		// MARK: Equatable methods
		//------------------------------------------------------------------------------------------------------------------
		static func == (lhs :MediaItem, rhs :MediaItem) -> Bool { lhs.id == rhs.id }
	}

	//------------------------------------------------------------------------------------------------------------------
	// MARK: - LivePhotoBundle
	class LivePhotoBundleMediaItem : MediaItem {

		// MARK: Properties
		fileprivate	override	var	typeDisplayNameInternal: String? { "Live Photo" }

								var	photoData :Data?

								var	videoAttachmentFilename :String?
								var	videoAttachmentData :Data?

								var	creationDate :Date?
								var	modificationDate :Date?

		private					let	itemProvider :NSItemProvider

		// MARK: Class methods
		//--------------------------------------------------------------------------------------------------------------
		static fileprivate func canLoad(itemProvider :NSItemProvider) -> LivePhotoBundleMediaItem? {
			// Check if can load
			return itemProvider.hasItemConformingToTypeIdentifier("com.apple.private.live-photo-bundle") ?
					LivePhotoBundleMediaItem(itemProvider: itemProvider) : nil
		}

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		private init(itemProvider :NSItemProvider) {
			// Store
			self.itemProvider = itemProvider

			// Do super
			super.init()
		}

		// MARK: Instance methods
		//--------------------------------------------------------------------------------------------------------------
		fileprivate func load(completionProc :@escaping () -> Void) {
			// Load
			_ = self.itemProvider.loadObject(ofClass: URL.self) {
				// Setup
				defer { completionProc() }

				// Handle results
				if let url = $0 {
					// Catch errors
					do {
						// Load files
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
						guard photoFile != nil else {
							// Did not find photo file
							self.error = NSExtensionItemError.couldNotIdentifyPhoto

							return
						}
						guard videoAttachmentFile != nil else {
							// Did not find video attachment file
							self.error = NSExtensionItemError.couldNotIdentifyVideoAttachment

							return
						}

						// Found files
						self.filename = photoFile!.name
						self.photoData = try FileReader.contentsAsData(of: photoFile!)
						self.image = Image(self.photoData!)

						self.videoAttachmentFilename =
								videoAttachmentFile!.name
									.deletingPathExtension
									.appending(pathExtension: videoAttachmentFile!.extension?.lowercased() ?? "")
						self.videoAttachmentData = try FileReader.contentsAsData(of: videoAttachmentFile!)
					} catch {
						// Error
						self.error = error
					}
				} else {
					// Error
					self.error = $1
				}
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	// MARK: - PhotoMediaItem
	class PhotoMediaItem : MediaItem {

		// MARK: Properties
		fileprivate	override	var	typeDisplayNameInternal :String? { "Photo" }

								var	data :Data?
								var	creationDate :Date?
								var	modificationDate :Date?

		private					let	itemProvider :NSItemProvider

		// MARK: Class methods
		//--------------------------------------------------------------------------------------------------------------
		static fileprivate func canLoad(itemProvider :NSItemProvider) -> PhotoMediaItem? {
			// Check if can load
			return itemProvider.hasItemConformingToTypeIdentifier(kUTTypeImage as String) ?
					PhotoMediaItem(itemProvider: itemProvider) : nil
		}

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		private init(itemProvider :NSItemProvider) {
			// Store
			self.itemProvider = itemProvider

			// Do super
			super.init()
		}

		// MARK: Instance methods
		//--------------------------------------------------------------------------------------------------------------
		fileprivate func load(completionProc :@escaping () -> Void) {
			// Prefer the ORIGINAL file when the provider exposes one via its file URL.  Some sources (notably Finder
			//	on macOS 26+) hand share extensions a transcoded PNG as the image representation while still exposing
			//	the untouched original (HEIC, etc.) through "public.file-url" - loading that preserves the real bytes,
			//	the EXIF/XMP metadata, and the original filename.
			if self.itemProvider.hasItemConformingToTypeIdentifier(kUTTypeFileURL as String) {
				// Resolve the original file URL
				_ = self.itemProvider.loadObject(ofClass: URL.self) { url, _ in
					// Handle results
					if let url = url {
						// Load the untouched original file
						self.load(fromOriginalFile: File(url))

						completionProc()
					} else {
						// Could not resolve the file URL - fall back to the image representation
						self.loadImageRepresentation(completionProc: completionProc)
					}
				}
			} else {
				// No file URL - load the image representation directly
				self.loadImageRepresentation(completionProc: completionProc)
			}
		}

		//--------------------------------------------------------------------------------------------------------------
		private func load(fromOriginalFile file :File) {
			// Access the original (may be security-scoped when delivered by a share)
			let	url = file.url
			let	didStartAccess = url.startAccessingSecurityScopedResource()
			defer { if didStartAccess { url.stopAccessingSecurityScopedResource() } }

			// The original file preserves its real bytes, metadata, and filename
			self.filename = file.name
			self.creationDate = file.creationDate
			self.modificationDate = file.modificationDate

			do {
				// Load data and create image
				self.data = try FileReader.contentsAsData(of: file)
				self.image = Image(self.data!)
			} catch {
				// Error
				self.error = error
			}
		}

		//--------------------------------------------------------------------------------------------------------------
		private func loadImageRepresentation(completionProc :@escaping () -> Void) {
			// Load
			// Determine the most specific concrete image type this provider holds - preserving EXIF/XMP metadata and the
			//	original filename - instead of transcoding to PNG.
			let	imageContentType = self.itemProvider.bestConcreteImageContentType
			let	imageContentTypeIdentifier = imageContentType?.identifier ?? (kUTTypeImage as String)
			_ = self.itemProvider.loadFileRepresentation(forTypeIdentifier: imageContentTypeIdentifier) {
				// Handle results
				if let url = $0 {
					// Success
					let	file = File(url)

					// Try to preserve the original filename
					if let suggestedName = self.itemProvider.suggestedName {
						// Use suggested name with the concrete file extension
						let	fileExtension = file.extension ?? imageContentType?.preferredFilenameExtension
						self.filename =
								(fileExtension != nil) ?
										suggestedName.deletingPathExtension.appending(pathExtension: fileExtension!) :
										suggestedName
					} else {
						// Fall back to the delivered file's name
						self.filename = file.name
					}

					self.creationDate = file.creationDate
					self.modificationDate = file.modificationDate

#if os(iOS)
					// iOS
					do {
						// Load data
						self.data = try Data(contentsOf: url)

						// Create image
						self.image = Image(self.data!)
					} catch {
						// Error
						self.error = error
					}
#endif
#if os(macOS)
					// macOS
					do {
						// Load data
						self.data = try FileReader.contentsAsData(of: file)

						// Create image - try loading directly
						self.image = Image(self.data!)

						// Check if succeeded
						if self.image == nil {
							// Try loading as a PLIST
							if let image = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(self.data!) as? NSImage {
								// Loaded as NSImage
								self.image = Image(image)
							}
						}
					} catch {
						// Error
						self.error = error
					}
#endif

					// Call completion
					completionProc()
				} else {
					// Could not load as file
					_ = $1
					_ = self.itemProvider.loadDataRepresentation(forTypeIdentifier: imageContentTypeIdentifier) {
						// Handle results
						if let data = $0 {
							// Success
							self.data = data

							self.image = Image(self.data!)
						} else {
							// Error
							self.error = $1
						}

						completionProc()
					}
				}
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	// MARK: - URLMediaItem
	class URLMediaItem : MediaItem {

		// MARK: Properties
		fileprivate	override	var	typeDisplayNameInternal :String? { "Photo" }

								var	data :Data?

		private					let	itemProvider :NSItemProvider

		// MARK: Class methods
		//--------------------------------------------------------------------------------------------------------------
		static fileprivate func canLoad(itemProvider :NSItemProvider) -> URLMediaItem? {
			// Check if can load
			return itemProvider.hasItemConformingToTypeIdentifier(kUTTypeURL as String) ?
					URLMediaItem(itemProvider: itemProvider) : nil
		}

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		private init(itemProvider :NSItemProvider) {
			// Store
			self.itemProvider = itemProvider

			// Do super
			super.init()
		}

		// MARK: Instance methods
		//--------------------------------------------------------------------------------------------------------------
		fileprivate func load(completionProc :@escaping () -> Void) {
			// Load
			_ = self.itemProvider.loadObject(ofClass: URL.self) {
				// Handle results
				if let url = $0 {
					// Success
					let urlSession = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
					let	dataTask =
								urlSession.dataTask(with: url) { data, response, error in
									// Store
									self.data = data

									self.filename = url.lastPathComponent
									self.image = (data != nil) ? Image(data!) : nil
									self.error = error

									// Call completion
									completionProc()
								}
					dataTask.resume()
				} else {
					// Error
					self.error = $1

					// Call completion
					completionProc()
				}
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	// MARK: - VideoMediaItem
	class VideoMediaItem : MediaItem {

		// MARK: Properties
		fileprivate	override	var	typeDisplayNameInternal :String? { "Video" }

								var	file :File?
								var	creationDate :Date?

		private					let	itemProvider :NSItemProvider

		// MARK: Class methods
		//--------------------------------------------------------------------------------------------------------------
		static fileprivate func canLoad(itemProvider :NSItemProvider) -> VideoMediaItem? {
			// Check if can load
			return (itemProvider.hasItemConformingToTypeIdentifier(kUTTypeVideo as String) ||
							itemProvider.hasItemConformingToTypeIdentifier(AVFileType.mov.rawValue) ||
							itemProvider.hasItemConformingToTypeIdentifier(AVFileType.mp4.rawValue) ||
							itemProvider.hasItemConformingToTypeIdentifier(AVFileType.m4v.rawValue)) ?
					VideoMediaItem(itemProvider: itemProvider) : nil
		}

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		private init(itemProvider :NSItemProvider) {
			// Store
			self.itemProvider = itemProvider

			// Do super
			super.init()
		}

		// MARK: Instance methods
		//--------------------------------------------------------------------------------------------------------------
		fileprivate func load(completionProc :@escaping () -> Void) {
			// Load
			_ = self.itemProvider.loadObject(ofClass: URL.self) {
				// Setup
				defer { completionProc() }

				// Handle results
				if let url = $0 {
					// Success
					self.file = File(url)

					let	asset = AVAsset(url: url)
					let	assetDuration = asset.duration
					self.creationDate = asset.creationDate?.dateValue

					let	assetImageGenerator = AVAssetImageGenerator(asset: asset)
					assetImageGenerator.appliesPreferredTrackTransform = true

					self.filename = self.file!.name

					if let cgImage =
							try? assetImageGenerator.copyCGImage(
									at: CMTime(value: assetDuration.value / 2, timescale: assetDuration.timescale),
							 		actualTime: nil) {
						// Was able to generate image
						self.image = Image(cgImage)
					}
				} else {
					// Error
					self.error = $1
				}
			}
		}
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func loadMediaItems(completionProc :@escaping (_ mediaItems :[MediaItem]) -> Void) {
		// Setup
		let	attachments = self.attachments!

		// Perform in the background
		DispatchQueue.global().async() {
			// Setup
			let	remainingMediaItemsCount = LockingNumeric<Int>()
			var	mediaItems = [MediaItem]()
			attachments.forEach() {
				// Check what can be loaded
				if let photoMediaItem = PhotoMediaItem.canLoad(itemProvider: $0) {
					// Can load as PhotoMediaItem
					remainingMediaItemsCount.add(1)
					mediaItems.append(photoMediaItem)
					photoMediaItem.load() { remainingMediaItemsCount.subtract(1) }
				} else if let videoMediaItem = VideoMediaItem.canLoad(itemProvider: $0) {
					// Can load as VideoMediaItem
					remainingMediaItemsCount.add(1)
					mediaItems.append(videoMediaItem)
					videoMediaItem.load() { remainingMediaItemsCount.subtract(1) }
				} else if let livePhotoBundleMediaItem = LivePhotoBundleMediaItem.canLoad(itemProvider: $0) {
					// Can load as LivePhotoBundleMediaItem
					remainingMediaItemsCount.add(1)
					mediaItems.append(livePhotoBundleMediaItem)
					livePhotoBundleMediaItem.load() { remainingMediaItemsCount.subtract(1) }
				} else if let urlMediaItem = URLMediaItem.canLoad(itemProvider: $0) {
					// Can load as URLMediaItem
					remainingMediaItemsCount.add(1)
					mediaItems.append(urlMediaItem)
					urlMediaItem.load() { remainingMediaItemsCount.subtract(1) }
				}
			}

			// Wait for all to be loaded
			remainingMediaItemsCount.wait()

			// Switch to main queue
			DispatchQueue.main.async() { completionProc(mediaItems) }
		}
	}
}
