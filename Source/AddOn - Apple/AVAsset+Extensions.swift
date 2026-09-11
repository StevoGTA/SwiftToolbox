//
//  AVAsset+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 9/11/26.
//  Copyright © 2026 Stevo Brock. All rights reserved.
//

import AVFoundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: AVAsset extension
extension AVAsset {

	// MARK: Properties
	var	videoCodecID :FourCharCode? {
				get async throws {
					// Get the format of the first video track
					guard let videoTrack = try await loadTracks(withMediaType: .video).first,
							let formatDescription = try await videoTrack.load(.formatDescriptions).first else
						{ return nil }

					return CMFormatDescriptionGetMediaSubType(formatDescription)
				}
			}
}
