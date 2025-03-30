//
//  PHImageManager+Extensions.swift
//  Media Tools - Xcode 16
//
//  Created by Stevo Brock on 3/2/25.
//  Copyright © 2025 Stevo Brock. All rights reserved.
//

import Photos
import UIKit

//----------------------------------------------------------------------------------------------------------------------
// MARK: PHImageManager extension
extension PHImageManager {

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func requestImage(forImageAsset asset :PHAsset, targetSize :CGSize, contentMode :PHImageContentMode,
			options :PHImageRequestOptions?) async throws -> (image :UIImage?, info :[AnyHashable : Any]) {
		// Warp to async world...
		try await withCheckedThrowingContinuation() { continuation in
			// Make request
			requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: options)
					{ image, info in
						// Check for error
						if let error = info?[PHImageErrorKey] as? Error {
							// Error
							continuation.resume(throwing: error)

							return
						}

						// Check if cancelled
						guard !((info?[PHImageCancelledKey] as? Bool) ?? false) else {
							// Cancelled
							continuation.resume(throwing: CancellationError())

							return
						}

						// Check if received degraded image
						guard !(info?[PHImageResultIsDegradedKey] as? Bool ?? false) else {
							// This proc will be called again
							return
						}

						// Resume continuation
						continuation.resume(returning: (image, info!))
					}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func requestAVAsset(forVideoAsset asset :PHAsset, options: PHVideoRequestOptions? = nil) async ->
			(AVAsset?, AVAudioMix?, [AnyHashable : Any]?) {
		// Warp to async world...
		await withCheckedContinuation() { continuation in
			// Make request
			requestAVAsset(forVideo: asset, options: options) { continuation.resume(returning: ($0, $1, $2)) }
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func requestPlayerItem(forVideo asset :PHAsset, options: PHVideoRequestOptions? = nil) async ->
			(AVPlayerItem?, [AnyHashable : Any]?) {
		// Warp to async wrold
		await withCheckedContinuation() { continuation in
			// Make request
			requestPlayerItem(forVideo: asset, options: options) { continuation.resume(returning: ($0, $1)) }
		}
	}
}
