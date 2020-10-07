//
//  CGImageSource+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 5/11/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation
import ImageIO

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

					case .`default`, .string, .alternateText:
						// Can use self
						return value

					case .arrayUnordered, .arrayOrdered , .alternateArray:
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
				}
			}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - CGImageSource extension
extension CGImageSource {

	// MARK: Properties
	var	metadata :[String : Any]? {
				// Setup
				guard let imageMetadata = CGImageSourceCopyMetadataAtIndex(self, 0, .none) else { return nil }
				guard let tags = CGImageMetadataCopyTags(imageMetadata) as? [CGImageMetadataTag] else { return nil }

				// Transmogrify
				var	metadata = [String : [String : Any]]()
				tags.forEach() {
					// Get info
					guard let prefix = CGImageMetadataTagCopyPrefix($0), let name = CGImageMetadataTagCopyName($0)
							else { return }

					// Get current class info
					var	info = metadata[prefix as String] ?? [:]
					info[name as String] = $0.transmogrifiedValue
					metadata[prefix as String] = info
				}

				return metadata
			}
}
