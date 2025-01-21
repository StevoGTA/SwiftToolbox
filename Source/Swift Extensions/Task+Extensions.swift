//
//  Task+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 1/15/25.
//  Copyright © 2025 Stevo Brock. All rights reserved.
//

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
