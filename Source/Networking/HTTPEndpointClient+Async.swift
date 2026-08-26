//
//  HTTPEndpointClient+Async.swift
//  Swift Toolbox
//
//  Created by Stevo on 8/26/26.
//  Copyright © 2026 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: HTTPEndpointClient async extension
public extension HTTPEndpointClient {

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func queue<T>(_ decodableHTTPEndpointRequest :DecodableHTTPEndpointRequest<T>, identifier :String = "",
			priority :Priority = .normal) async throws -> T {
		// Queue and await
		return try await withCheckedThrowingContinuation() { continuation in
			// Setup
			decodableHTTPEndpointRequest.completionProc = { _, info, error in
				// Handle results
				if info != nil {
					// Success
					continuation.resume(returning: info!)
				} else {
					// Error
					continuation.resume(throwing: error ?? HTTPEndpointRequestError.unableToProcessResponseData)
				}
			}

			// Queue
			self.queue(decodableHTTPEndpointRequest as HTTPEndpointRequest, identifier: identifier, priority: priority)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func queue<T>(_ jsonHTTPEndpointRequest :JSONHTTPEndpointRequest<T>, identifier :String = "",
			priority :Priority = .normal) async throws -> T {
		// Queue and await
		return try await withCheckedThrowingContinuation() { continuation in
			// Setup
			jsonHTTPEndpointRequest.completionProc = { _, info, error in
				// Handle results
				if info != nil {
					// Success
					continuation.resume(returning: info!)
				} else {
					// Error
					continuation.resume(throwing: error ?? HTTPEndpointRequestError.unableToProcessResponseData)
				}
			}

			// Queue
			self.queue(jsonHTTPEndpointRequest, identifier: identifier, priority: priority)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func queue(_ stringHTTPEndpointRequest :StringHTTPEndpointRequest, identifier :String = "",
			priority :Priority = .normal) async throws -> String {
		// Queue and await
		return try await withCheckedThrowingContinuation() { continuation in
			// Setup
			stringHTTPEndpointRequest.completionProc = { _, string, error in
				// Handle results
				if string != nil {
					// Success
					continuation.resume(returning: string!)
				} else {
					// Error
					continuation.resume(throwing: error ?? HTTPEndpointRequestError.unableToProcessResponseData)
				}
			}

			// Queue
			self.queue(stringHTTPEndpointRequest, identifier: identifier, priority: priority)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func queue(_ successHTTPEndpointRequest :SuccessHTTPEndpointRequest, identifier :String = "",
			priority :Priority = .normal) async throws {
		// Queue and await
		let	_ :Void =
					try await withCheckedThrowingContinuation() { continuation in
						// Setup
						successHTTPEndpointRequest.completionProc = { _, error in
							// Handle results
							if error == nil {
								// Success
								continuation.resume(returning: ())
							} else {
								// Error
								continuation.resume(throwing: error!)
							}
						}

						// Queue
						self.queue(successHTTPEndpointRequest, identifier: identifier, priority: priority)
					}
	}
}
