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
// MARK: CGImageSource extension
extension CGImageSource {

	// MARK: Properties
	var	metadata :[String : Any]? {
				// Setup
				guard let imageMetadata = CGImageSourceCopyMetadataAtIndex(self, 0, .none) else { return nil }
				guard let tags = CGImageMetadataCopyTags(imageMetadata) else { return nil }

				// Convert to dictionary
				var	metadata = [String : Any]()
				(tags as NSArray).forEach() {
					// Setup
					let	tagMetadata = $0 as! CGImageMetadataTag
					if let cfPrefix = CGImageMetadataTagCopyPrefix(tagMetadata),
							let cfName = CGImageMetadataTagCopyName(tagMetadata) {
						// Setup
						let	name = "\(cfPrefix)::\(cfName)"
						let	value = CGImageMetadataTagCopyValue(tagMetadata)
						metadata[name] = value
					}
				}

				return metadata
			}
}
