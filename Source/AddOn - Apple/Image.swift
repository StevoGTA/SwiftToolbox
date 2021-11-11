//
//  Image.swift
//  Swift Toolbox
//
//  Created by Stevo on 11/3/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import AVFoundation
import Foundation

#if os(iOS)
	import MobileCoreServices
	import UIKit
#else
	import ImageIO
#endif

//----------------------------------------------------------------------------------------------------------------------
// MARK: CGImageMetadataTag extension
extension CGImageMetadataTag {

	// MARK: Properties
	var	transmogrifiedValue :Any? {
				// Setup
				let	value = CGImageMetadataTagCopyValue(self)

				// Check type
				switch CGImageMetadataTagGetType(self) {
					case .invalid:
						// Invalid
						return nil

					case .`default`, .string:
						// Can use self
						return value

					case .arrayUnordered, .arrayOrdered , .alternateArray, .alternateText:
						// Array
						let	firstValue = (value as! [Any]).first
						if firstValue is Int64 {
							// Number
							return value as! [Int64]
						} else {
							// Assume CGImageMetadataTag array
							return (value as! [CGImageMetadataTag]).map({ $0.transmogrifiedValue })
						}

					case .structure:
						// Dictionary
						let name = CGImageMetadataTagCopyName(self)

						return [name! as String :
								(value as! [String : CGImageMetadataTag]).mapValues({ $0.transmogrifiedValue })]

					default:
						// Unknown
						fatalError("Unknown case \(CGImageMetadataTagGetType(self)) in CGImageMetadataTag extension")
				}
			}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - Image
class Image {

	// MARK: Types
	enum ScaleMode {
		case aspectFit
		case aspectFill
		case unconstrained
	}

	enum Orientation : Int {
		// Values
		case topLeft = 1
		case topRight = 2
		case bottomRight = 3
		case bottomLeft = 4
		case leftTop = 5
		case rightTop = 6
		case rightBottom = 7
		case leftBottom = 8

		// Properties
		static	let	up = Orientation.topLeft
		static	let	upMirrored = Orientation.topRight
		static	let	down = Orientation.bottomRight
		static	let	downMirrored = Orientation.bottomLeft
		static	let	rightMirrored = Orientation.leftTop
		static	let	left = Orientation.rightTop
		static	let	leftMirrored = Orientation.rightBottom
		static	let	right = Orientation.leftBottom
	}

	enum StorageType {
		case png
		case jpeg
		case heic
	}

	// MARK: Properties
			lazy	var	cgImage :CGImage? = { [unowned self] in
								// Check if have CGImage already
								if self.cgImageInternal != nil { return self.cgImageInternal }

								// Create from source
								return (self.cgImageSource != nil) ?
										CGImageSourceCreateImageAtIndex(self.cgImageSource!, 0, nil) : nil
							}()
			lazy	var	orientation :Orientation = { [unowned self] in
								// Setup
								let	metadata = self.metadata
								let	orientation = (metadata?["tiff"] as? [String : Any])?["Orientation"] as? String

								// Check results
								if let value = Int(orientation) {
									// Have value
									return Orientation(rawValue: value)!
								} else {
									// Use default
									return .up
								}
							}()
			lazy	var	size :CGSize? = { [unowned self] in
								// Preflight
								guard let cgImage = self.cgImage else { return nil }

								// Check orientation
								switch self.orientation {
									case .topLeft, .topRight, .bottomRight, .bottomLeft:
										// Normal
										return CGSize(width: cgImage.width, height: cgImage.height)

									case .rightTop, .rightBottom, .leftBottom, .leftTop:
										// Rotated
										return CGSize(width: cgImage.height, height: cgImage.width)
								}
							}()
			lazy	var	cgColorSpace :CGColorSpace? = { [unowned self] in return self.cgImage?.colorSpace }()

			lazy	var	metadata :[String : Any]? = {
								// Setup
								guard let cgImageSource = self.cgImageSource else { return nil }
								guard let imageMetadata = CGImageSourceCopyMetadataAtIndex(cgImageSource, 0, .none) else
										{ return nil }
								guard let tags = CGImageMetadataCopyTags(imageMetadata) as? [CGImageMetadataTag] else
										{ return nil }

								// Transmogrify
								var	metadata = [String : [String : Any]]()
								tags.forEach() {
									// Get info
									guard let prefix = CGImageMetadataTagCopyPrefix($0),
											let name = CGImageMetadataTagCopyName($0) else { return }

									// Get current class info
									var	info = metadata[prefix as String] ?? [:]
									info[name as String] = $0.transmogrifiedValue
									metadata[prefix as String] = info
								}

								return metadata
							}()
			lazy	var	properties :[String : Any]? = {
								// Setup
								guard let cgImageSource = self.cgImageSource else { return nil }

								return CGImageSourceCopyProperties(cgImageSource, nil) as? [String : Any]
							}()

	private			let	cgImageInternal :CGImage?
	private			let	cgImageSource :CGImageSource?

	// MARK: Class methods
	//------------------------------------------------------------------------------------------------------------------
	static func creationDate(from info :[String : Any]) -> Date? {
		// Check what we have
		if let createDate = (info["xmp"] as? [String : Any])?["CreateDate"] as? String,
				let offsetTime = (info["exif"] as? [String : Any])?["OffsetTime"] as? String {
			// 2021-09-14T10:27:38.915 + -07:00
			return Date(fromRFC3339Extended: createDate + offsetTime.replacingOccurrences(of: ":", with: ""))
		} else {
			// Unknown
			return nil
		}
	}

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(_ data :Data) {
		// Setup
		self.cgImageInternal = nil
		self.cgImageSource = CGImageSourceCreateWithData(data as CFData, nil)
	}

	//------------------------------------------------------------------------------------------------------------------
	init(_ file :File) {
		// Setup
		self.cgImageInternal = nil
		self.cgImageSource = CGImageSourceCreateWithURL(file.url as CFURL, nil)
	}

	//------------------------------------------------------------------------------------------------------------------
	init(_ cgImage :CGImage) {
		// Setup
		self.cgImageInternal = cgImage
		self.cgImageSource = nil
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func scaled(to size :CGSize, scaleMode :ScaleMode) -> Image? {
		// Setup
		guard let cgImage = self.cgImage else { return nil }
		guard let imageSize = self.size else { return nil }
		guard let cgColorSpace = self.cgColorSpace else { return nil }

		// Calculate final bitmap size
		let	sizeUse :CGSize
		var	scaledImageSize :CGSize
		switch scaleMode {
			case .aspectFit:
				// Aspect Fit
				let	wScale = size.width / imageSize.width
				let	hScale = size.height / imageSize.height
				scaledImageSize =
						(wScale < hScale) ?
								CGSize(width: imageSize.width * wScale, height: imageSize.height * wScale) :
								CGSize(width: imageSize.width * hScale, height: imageSize.height * hScale)
				sizeUse = scaledImageSize

			case .aspectFill:
				// Aspect Fill
				let	wScale = size.width / imageSize.width
				let	hScale = size.height / imageSize.height
				scaledImageSize =
						(wScale < hScale) ?
								CGSize(width: imageSize.width * hScale, height: imageSize.height * hScale) :
								CGSize(width: imageSize.width * wScale, height: imageSize.height * wScale)
				sizeUse = size

			case .unconstrained:
				// Axis Independent
				scaledImageSize = size
				sizeUse = size
		}

		// Create bitmap data store
		let	data :UnsafeMutableRawPointer
		let	cgContext :CGContext
		switch cgColorSpace.model {
			case .rgb:
				// RGB
				data = malloc(Int(sizeUse.width) * Int(sizeUse.height) * 4)
				cgContext =
						CGContext(data: data, width: Int(sizeUse.width), height: Int(sizeUse.height), bitsPerComponent: 8,
								bytesPerRow: Int(sizeUse.width) * 4, space: cgColorSpace,
								bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

			case .cmyk:
				// CMYK
				data = malloc(Int(sizeUse.width) * Int(sizeUse.height) * 4 * 2)
				cgContext =
						CGContext(data: data, width: Int(sizeUse.width), height: Int(sizeUse.height), bitsPerComponent: 16,
								bytesPerRow: Int(sizeUse.width) * 4 * 2, space: CGColorSpaceCreateDeviceCMYK(),
								bitmapInfo: CGImageAlphaInfo.none.rawValue)!

			default:
				// Other
				NSLog("Image - unknown ColorSpace when scaling: \(cgColorSpace.model)")

				return nil
		}

		// Check scale mode
		if scaleMode == .aspectFit {
			// Clear as there may be transparent pixels
#if os(iOS)
			cgContext.setFillColor(UIColor.clear.cgColor)
#else
			cgContext.setFillColor(.clear)
#endif
			cgContext.fill(CGRect(origin: .zero, size: imageSize))
		}

		// Adjust context based on orientation
		switch self.orientation {
			case .topLeft:
				// Up - nothing to do
				break

			case .topRight:
				// Up Mirrored
				fatalError("Image - unimplemented \"topRight\" when scaling")

			case .bottomRight:
				// Down
				cgContext.concatenate(CGAffineTransform(translationX: sizeUse.width * 0.5, y: sizeUse.height * 0.5))
				cgContext.concatenate(CGAffineTransform(rotationAngle: .pi))
				cgContext.concatenate(
						CGAffineTransform(translationX: (-sizeUse.height * 0.5) * sizeUse.width / sizeUse.height,
								y: (-sizeUse.width * 0.5) * sizeUse.height / sizeUse.width))

			case .bottomLeft:
				// Down Mirrored
				fatalError("Image - unimplemented \"bottomLeft\" when scaling")

			case .rightTop:
				// Left
				cgContext.concatenate(CGAffineTransform(translationX: sizeUse.width * 0.5, y: sizeUse.height * 0.5))
				cgContext.concatenate(CGAffineTransform(rotationAngle: -.pi / 2.0))
				cgContext.concatenate(
						CGAffineTransform(translationX: (-sizeUse.height * 0.5) * sizeUse.width / sizeUse.height,
								y: (-sizeUse.width * 0.5) * sizeUse.height / sizeUse.width))

				scaledImageSize = CGSize(width: scaledImageSize.height, height: scaledImageSize.width)

			case .rightBottom:
				// Left Mirrored
				fatalError("Image - unimplemented \"rightBottom\" when scaling")

			case .leftBottom:
				// Right
				cgContext.concatenate(CGAffineTransform(translationX: sizeUse.width * 0.5, y: sizeUse.height * 0.5))
				cgContext.concatenate(CGAffineTransform(rotationAngle: .pi / 2.0))
				cgContext.concatenate(
						CGAffineTransform(translationX: (-sizeUse.height * 0.5) * sizeUse.width / sizeUse.height,
								y: (-sizeUse.width * 0.5) * sizeUse.height / sizeUse.width))

				scaledImageSize = CGSize(width: scaledImageSize.height, height: scaledImageSize.width)
				break;

			case .leftTop:
				// Right Mirrored
				fatalError("Image - unimplemented \"leftTop\" when scaling")
		}

		// Draw image
		let	origin =
					CGPoint(x: (sizeUse.width - scaledImageSize.width) * 0.5,
							y: (sizeUse.height - scaledImageSize.height) * 0.5)
		cgContext.draw(cgImage, in: CGRect(origin: origin, size: scaledImageSize))

		// Create new image reference
		let	image = Image(cgContext.makeImage()!)

		// Cleanup
		free(data)

		return image
	}

	//------------------------------------------------------------------------------------------------------------------
	func data(forPreferredStorageType storageType :StorageType = .heic) -> Data? {
		// Preflight
		guard let cgImage = self.cgImage else { return nil }

		// Setup
		let	uti :CFString
		switch storageType {
			case .png:
				// PNG
				uti = kUTTypePNG

			case .jpeg:
				// JPEG
				uti = kUTTypeJPEG

			case .heic:
				// HEIC
				if #available(OSX 10.13, *) {
					// HEIC only available on macOS 10.13 and later
					uti = AVFileType.heic as CFString
				} else {
					// Pre-macOS 10.13
					uti = kUTTypeJPEG
				}
		}

		let	data = NSMutableData()
		let	imageDestination = CGImageDestinationCreateWithData(data, uti, 1, nil)!
		CGImageDestinationAddImage(imageDestination, cgImage, nil)
		CGImageDestinationFinalize(imageDestination)

		return data as Data
	}
}
