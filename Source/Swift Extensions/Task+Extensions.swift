//
//  Task+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 1/15/25.
//  Copyright © 2025 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: Task extension
public extension Task where Failure == Error {

	// MARK: Class methods
	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	static func delayed(byTimeInterval delayInterval: TimeInterval, priority: TaskPriority? = nil,
			@_implicitSelfCapture operation: @escaping @Sendable () async throws -> Success) -> Task {
		// Start task
		Task(priority: priority) {
			// Delay
			try await Task<Never, Never>.sleep(nanoseconds: UInt64(delayInterval * 1_000_000_000))

			return try await operation()
		}
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - Free functions
public func withRetries<T>(count :Int = 3, _ proc :() async throws -> T) async throws -> T {
	// Try a few times
	var	lastError :Error?
	for _ in 1...count {
		// Check cancelled
		try Task.checkCancellation()

		// Try
		do {
			// Perform
			return try await proc()
		} catch is CancellationError {
			// Cancelled
			throw CancellationError()
		} catch {
			// Note error
			lastError = error
		}
	}

	throw lastError!
}
