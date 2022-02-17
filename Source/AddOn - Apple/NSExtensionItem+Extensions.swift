//
//  NSExtensionItem+Extensions.swift
//  Media Tools
//
//  Created by Stevo on 12/1/21.
//  Copyright © 2021 Stevo Brock. All rights reserved.
//

import AVFoundation
import CoreServices

#if os(iOS)
	import UIKit
#endif

//----------------------------------------------------------------------------------------------------------------------
// MARK: NSExtensionItem extension
extension NSExtensionItem {

	// MARK: - MediaItem
	class MediaItem {

		// MARK: Properties
					let	id = UUID().uuidString
					
					var	filename :String?
					var	image :CGImage?
					var	error :Error?
					var	typeDisplayName :String { self.typeDisplayNameInternal! }

					var	filenameDidChangeProc :(_ filename :String) -> Void = { _ in }

		fileprivate	var	typeDisplayNameInternal :String? { nil }

		// MARK: Lifecycle methods
		//------------------------------------------------------------------------------------------------------------------
		init() {}
	}

	//----------------------------------------------------------------------------------------------------------------------
	// MARK: - PhotoMediaItem
	class PhotoMediaItem : MediaItem {

		// MARK: Properties
		fileprivate	override	var	typeDisplayNameInternal :String? { "Photo" }

								var	data :Data?
								var	file :File?

		private					let	itemProvider :NSItemProvider

		// MARK: Class methods
		//------------------------------------------------------------------------------------------------------------------
		static fileprivate func canLoad(itemProvider :NSItemProvider) -> PhotoMediaItem? {
			// Check if can load
			return itemProvider.hasItemConformingToTypeIdentifier(kUTTypeImage as String) ?
					PhotoMediaItem(itemProvider: itemProvider) : nil
		}

		// MARK: Lifecycle methods
		//------------------------------------------------------------------------------------------------------------------
		private init(itemProvider :NSItemProvider) {
			// Store
			self.itemProvider = itemProvider

			// Do super
			super.init()
		}

		// MARK: Instance methods
		//------------------------------------------------------------------------------------------------------------------
		fileprivate func load(completionProc :@escaping () -> Void) {
			// Load
			_ = self.itemProvider.loadFileRepresentation(forTypeIdentifier: kUTTypeImage as String) {
				// Handle results
				if let url = $0 {
					// Success
					self.file = File(url)
					self.filename = self.file!.name

#if os(iOS)
					// iOS
					self.image = UIImage(data: try! Data(contentsOf: url))?.cgImage
#endif
#if os(macOS)
					// macOS
					do {
						// Create image
						let	data = try FileReader.contentsAsData(of: self.file!)
						let	imageSource = CGImageSourceCreateWithData(data as CFData, nil)
						self.image = CGImageSourceCreateImageAtIndex(imageSource!, 0, nil)
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
					_ = self.itemProvider.loadDataRepresentation(forTypeIdentifier: kUTTypeImage as String) {
						// Handle results
						if let data = $0 {
							// Success
							self.data = data
#if os(iOS)
							self.image = UIImage(data: data)?.cgImage
#endif
#if os(macOS)
							let	imageSource = CGImageSourceCreateWithData(data as CFData, nil)
							self.image = CGImageSourceCreateImageAtIndex(imageSource!, 0, nil)
#endif
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

	//----------------------------------------------------------------------------------------------------------------------
	// MARK: - URLMediaItem
	class URLMediaItem : MediaItem {

		// MARK: Properties
		fileprivate	override	var	typeDisplayNameInternal :String? { "Photo" }

								var	data :Data?

		private					let	itemProvider :NSItemProvider

		// MARK: Class methods
		//------------------------------------------------------------------------------------------------------------------
		static fileprivate func canLoad(itemProvider :NSItemProvider) -> URLMediaItem? {
			// Check if can load
			return itemProvider.hasItemConformingToTypeIdentifier(kUTTypeURL as String) ?
					URLMediaItem(itemProvider: itemProvider) : nil
		}

		// MARK: Lifecycle methods
		//------------------------------------------------------------------------------------------------------------------
		private init(itemProvider :NSItemProvider) {
			// Store
			self.itemProvider = itemProvider

			// Do super
			super.init()
		}

		// MARK: Instance methods
		//------------------------------------------------------------------------------------------------------------------
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

#if os(iOS)
									self.image = (data != nil) ? UIImage(data: data!)?.cgImage : nil
#endif
#if os(macOS)
									self.image = (data != nil) ? Image(data!).cgImage : nil
#endif
									self.filename = url.lastPathComponent
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

	//----------------------------------------------------------------------------------------------------------------------
	// MARK: - VideoMediaItem
	class VideoMediaItem : MediaItem {

		// MARK: Properties
		fileprivate	override	var	typeDisplayNameInternal :String? { "Video" }

								var	file :File?
								var	creationDate :Date?

		private					let	itemProvider :NSItemProvider

		// MARK: Class methods
		//------------------------------------------------------------------------------------------------------------------
		static fileprivate func canLoad(itemProvider :NSItemProvider) -> VideoMediaItem? {
			// Check if can load
			return (itemProvider.hasItemConformingToTypeIdentifier(kUTTypeVideo as String) ||
							itemProvider.hasItemConformingToTypeIdentifier(AVFileType.mov.rawValue)) ?
					VideoMediaItem(itemProvider: itemProvider) : nil
		}

		// MARK: Lifecycle methods
		//------------------------------------------------------------------------------------------------------------------
		private init(itemProvider :NSItemProvider) {
			// Store
			self.itemProvider = itemProvider

			// Do super
			super.init()
		}

		// MARK: Instance methods
		//------------------------------------------------------------------------------------------------------------------
		fileprivate func load(completionProc :@escaping () -> Void) {
			// Load
			_ = self.itemProvider.loadObject(ofClass: URL.self) {
				// Handle results
				if let url = $0 {
					// Success
					self.file = File(url)

					let	asset = AVAsset(url: url)
					let	assetDuration = asset.duration
					self.creationDate = asset.creationDate?.dateValue

					let	assetImageGenerator = AVAssetImageGenerator(asset: asset)
					assetImageGenerator.appliesPreferredTrackTransform = true

					self.image =
							try? assetImageGenerator.copyCGImage(
									at: CMTime(value: assetDuration.value / 2, timescale: assetDuration.timescale),
									actualTime: nil)

					self.filename = self.file!.name
				} else {
					// Error
					self.error = $1
				}

				// Call completion
				completionProc()
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
