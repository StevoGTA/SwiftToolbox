//
//  CoalescingWriter.swift
//  Swift Toolbox
//
//  Created by Stevo on 12/15/25.
//  Copyright © 2025 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: CoalescingWriter
public actor CoalescingWriter<T> {

	// MARK: Properties
	private	var	pending :T?
	private	var	isRunning = false

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init() {}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func submit(_ value :T, writeProc :@escaping (_ t :T) async -> Void) {
		// Update pending
		self.pending = value

		// Check if running
		guard !self.isRunning else { return }

		// Run
		self.isRunning = true
		Task() {
			// Run until no more pending
			while let value = self.pending {
				// No more pending
				self.pending = nil

				// Write
				await writeProc(value)
			}

			// Not running
			self.isRunning = false
		}
	}
}
