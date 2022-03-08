//
//  BatchQueue.swift
//  Swift Toolbox
//
//  Created by Stevo on 1/24/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: BatchQueue
public class BatchQueue<T> {

	// MARK: Types
	public typealias Proc = (_ items :[T]) -> Void

	// MARK: Properties
	private	let	maximumBatchSize :Int
	private	let	proc :Proc
	private	let	procDispatchQueue :DispatchQueue?
	private	let	itemBatchesInFlight = LockingNumeric<Int>()

	private	var	items = [T]()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(maximumBatchSize :Int = 500, procDispatchQueue :DispatchQueue? = nil, proc :@escaping Proc) {
		// Store
		self.maximumBatchSize = maximumBatchSize
		self.proc = proc
		self.procDispatchQueue = procDispatchQueue
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func add(_ item :T) {
		// Add
		self.items.append(item)

		// Check if time to process some
		if self.items.count >= self.maximumBatchSize {
			// Time to process
			let	items = Array(self.items[0..<self.maximumBatchSize])
			self.items = Array(self.items.dropFirst(self.maximumBatchSize))

			process(items)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	public func add(_ items :[T]) {
		// Add
		self.items += items

		// Check if time to process some
		while self.items.count >= self.maximumBatchSize {
			// Time to process
			let	items = Array(self.items[0..<self.maximumBatchSize])
			self.items = Array(self.items.dropFirst(self.maximumBatchSize))

			process(items)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	public func finalize() {
		// Check for items
		if !self.items.isEmpty {
			// Process
			let	items = self.items
			self.items.removeAll()

			process(items)

			// Wait until all finished
			self.itemBatchesInFlight.wait()
		}
	}

	// Private methods
	//------------------------------------------------------------------------------------------------------------------
	private func process(_ items :[T]) {
		// Check if have specified DispatchQueue
		if self.procDispatchQueue != nil {
			// Perform on queue
			self.itemBatchesInFlight.add(1)
			self.procDispatchQueue!.async() {
				// Process
				self.proc(items)

				// Done
				self.itemBatchesInFlight.subtract(1)
			}
		} else {
			// Perform
			self.proc(items)
		}
	}
}
