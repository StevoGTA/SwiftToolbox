//
//  AVAssetResourceLoader.swift
//  Swift Toolbox
//
//  Created by Stevo on 11/24/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import AVFoundation
import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: AVAssetResourceLoadingRequest extension
extension AVAssetResourceLoadingRequest {

	// MARK: Properties
	var	identifier :String { String(format: "%p", self) }
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - AssetResourceLoader
class AssetResourceLoader : NSObject, AVAssetResourceLoaderDelegate {

	// MARK: Types
	typealias StartHTTPEndpointRequestProc =
				(_ identifier :String, _ offset :Int64, _ length :Int64, _ identifier :String,
						_ completionProc :@escaping DataHTTPEndpointRequest.CompletionProc) -> Void
	typealias CancelHTTPEndpointRequestProc = (_ identifier :String) -> Void

	// MARK: Properties
	private	let	id :String
	private	let	startHTTPEndpointRequestProc :StartHTTPEndpointRequestProc
	private	let	cancelHTTPEndpointRequestProc :CancelHTTPEndpointRequestProc

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(id :String, startHTTPEndpointRequestProc :@escaping StartHTTPEndpointRequestProc,
			cancelHTTPEndpointRequestProc :@escaping CancelHTTPEndpointRequestProc) {
		// Store
		self.id = id
		self.startHTTPEndpointRequestProc = startHTTPEndpointRequestProc
		self.cancelHTTPEndpointRequestProc = cancelHTTPEndpointRequestProc
	}

	// MARK: AVAssetResourceLoaderDelegate methods
	//------------------------------------------------------------------------------------------------------------------
	@objc func resourceLoader(_ resourceLoader :AVAssetResourceLoader,
			shouldWaitForLoadingOfRequestedResource assetResourceLoadingRequest :AVAssetResourceLoadingRequest) ->
			Bool {
		// Retrieve next data segment
		retrieveNextSegment(assetResourceLoadingRequest)

		return true
	}

//	//------------------------------------------------------------------------------------------------------------------
//    @objc func resourceLoader(_ resourceLoader :AVAssetResourceLoader,
//    		shouldWaitForRenewalOfRequestedResource renewalRequest :AVAssetResourceRenewalRequest) -> Bool {
//		return false
//	}

//	//------------------------------------------------------------------------------------------------------------------
//    @objc func resourceLoader(_ resourceLoader :AVAssetResourceLoader,
//    		shouldWaitForResponseTo authenticationChallenge :URLAuthenticationChallenge) -> Bool {
//		return false
//	}

//	//------------------------------------------------------------------------------------------------------------------
//    @objc func resourceLoader(_ resourceLoader :AVAssetResourceLoader,
//    		didCancel authenticationChallenge :URLAuthenticationChallenge) {
//	}

	//------------------------------------------------------------------------------------------------------------------
	@objc func resourceLoader(_ resourceLoader :AVAssetResourceLoader,
			didCancel assetResourceLoadingRequest :AVAssetResourceLoadingRequest) {
		// Cancel
		self.cancelHTTPEndpointRequestProc(assetResourceLoadingRequest.identifier)
	}

	// MARK: Private methods
	//------------------------------------------------------------------------------------------------------------------
	private func retrieveNextSegment(_ assetResourceLoadingRequest :AVAssetResourceLoadingRequest) {
		// Setup
		let	dataRequest = assetResourceLoadingRequest.dataRequest!
		let	remainingLength =
					dataRequest.requestedOffset + Int64(dataRequest.requestedLength) - dataRequest.currentOffset
		let	requestLength = min(remainingLength, 1024 * 1024)
		self.startHTTPEndpointRequestProc(self.id, dataRequest.currentOffset, requestLength,
				assetResourceLoadingRequest.identifier) { [weak self] in
					// Handle results
					if $1 != nil {
						// Success
						guard !assetResourceLoadingRequest.isFinished && !assetResourceLoadingRequest.isCancelled else
							{ return }

						// Check situation
						if assetResourceLoadingRequest.contentInformationRequest != nil {
							// Complete Content Information Request
							switch ($0!.contentType ?? "") {
								case "video/quicktime":
									// QuickTime
									assetResourceLoadingRequest.contentInformationRequest!.contentType =
											"com.apple.quicktime-movie"

								default:
									// Assume MPEG 4
									assetResourceLoadingRequest.contentInformationRequest!.contentType = "public.mpeg-4"
							}
							assetResourceLoadingRequest.contentInformationRequest!.contentLength =
									$0!.contentRange?.size ?? 0
							assetResourceLoadingRequest.contentInformationRequest!.isByteRangeAccessSupported = true

							// All done
							assetResourceLoadingRequest.finishLoading()
						} else {
							// Continue/Complete Data Request
							dataRequest.respond(with: $1!)

							// Check status
							if dataRequest.currentOffset <
									(dataRequest.requestedOffset + Int64(dataRequest.requestedLength)) {
								// Retrieve next segment
								self?.retrieveNextSegment(assetResourceLoadingRequest)
							} else {
								// All done
								assetResourceLoadingRequest.finishLoading()
							}
						}
					} else {
						// Error
						assetResourceLoadingRequest.finishLoading(with: $2)
					}
				}
	}
}
