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
		return try await queueInternal(decodableHTTPEndpointRequest, identifier: identifier, priority: priority)
				{ resultProc in
					// Setup
					decodableHTTPEndpointRequest.completionProc = { _, info, error in
						// Handle results
						resultProc((info != nil) ?
								.success(info!) :
								.failure(error ?? HTTPEndpointRequestError.unableToProcessResponseData))
					}
				}
	}

	//------------------------------------------------------------------------------------------------------------------
	func queue(_ integerHTTPEndpointRequest :IntegerHTTPEndpointRequest, identifier :String = "",
			priority :Priority = .normal) async throws -> Int {
		// Queue and await
		return try await queueInternal(integerHTTPEndpointRequest, identifier: identifier, priority: priority)
				{ resultProc in
					// Setup
					integerHTTPEndpointRequest.completionProc = { _, value, error in
						// Handle results
						resultProc((value != nil) ?
								.success(value!) :
								.failure(error ?? HTTPEndpointRequestError.unableToProcessResponseData))
					}
				}
	}

	//------------------------------------------------------------------------------------------------------------------
	func queue<T>(_ jsonHTTPEndpointRequest :JSONHTTPEndpointRequest<T>, identifier :String = "",
			priority :Priority = .normal) async throws -> T {
		// Queue and await
		return try await queueInternal(jsonHTTPEndpointRequest, identifier: identifier, priority: priority)
				{ resultProc in
					// Setup
					jsonHTTPEndpointRequest.completionProc = { _, info, error in
						// Handle results
						resultProc((info != nil) ?
								.success(info!) :
								.failure(error ?? HTTPEndpointRequestError.unableToProcessResponseData))
					}
				}
	}

	//------------------------------------------------------------------------------------------------------------------
	func queue(_ stringHTTPEndpointRequest :StringHTTPEndpointRequest, identifier :String = "",
			priority :Priority = .normal) async throws -> String {
		// Queue and await
		return try await queueInternal(stringHTTPEndpointRequest, identifier: identifier, priority: priority)
				{ resultProc in
					// Setup
					stringHTTPEndpointRequest.completionProc = { _, string, error in
						// Handle results
						resultProc((string != nil) ?
								.success(string!) :
								.failure(error ?? HTTPEndpointRequestError.unableToProcessResponseData))
					}
				}
	}

	//------------------------------------------------------------------------------------------------------------------
	func queue(_ successHTTPEndpointRequest :SuccessHTTPEndpointRequest, identifier :String = "",
			priority :Priority = .normal) async throws {
		// Queue and await
		let	_ :Void =
					try await queueInternal(successHTTPEndpointRequest, identifier: identifier, priority: priority)
							{ resultProc in
								// Setup
								successHTTPEndpointRequest.completionProc = { _, error in
									// Handle results
									resultProc((error == nil) ? .success(()) : .failure(error!))
								}
							}
	}

	// MARK: Private methods
	//------------------------------------------------------------------------------------------------------------------
	private func queueInternal<T>(_ httpEndpointRequest :HTTPEndpointRequest, identifier :String,
			priority :Priority, setup :(_ resultProc :@escaping (Result<T, Error>) -> Void) -> Void) async throws -> T {
		// Setup
		let	continuation = LockingValue<CheckedContinuation<T, Error>?>(nil)

		return try await withTaskCancellationHandler() {
			// Queue and await
			try await withCheckedThrowingContinuation() {
				// Store continuation
				continuation.set($0)

				// Check if already cancelled (the cancellation handler may have fired before the continuation existed)
				guard !Task.isCancelled else {
					// Cancelled
					continuation.swap(nil)?.resume(throwing: CancellationError())

					return
				}

				// Setup
				setup() { continuation.swap(nil)?.resume(with: $0) }

				// Queue
				self.queue(httpEndpointRequest, identifier: identifier, priority: priority)
			}
		} onCancel: {
			// Cancel request
			httpEndpointRequest.cancel()

			// Resume if not already resumed
			continuation.swap(nil)?.resume(throwing: CancellationError())
		}
	}
}
