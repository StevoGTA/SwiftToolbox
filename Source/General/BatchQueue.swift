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

	private	var	items = [T]()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(maximumBatchSize :Int = 500, proc :@escaping Proc) {
		// Store
		self.maximumBatchSize = maximumBatchSize
		self.proc = proc
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func add(_ item :T) {
		// Add
		self.items.append(item)

		// Check if time to process some
		if self.items.count >= self.maximumBatchSize {
			// Time to process
			self.proc(Array(self.items[0..<self.maximumBatchSize]))
			self.items = Array(self.items.dropFirst(self.maximumBatchSize))
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	public func add(_ items :[T]) {
		// Add
		self.items += items

		// Check if time to process some
		while self.items.count >= self.maximumBatchSize {
			// Time to process
			self.proc(Array(self.items[0..<self.maximumBatchSize]))
			self.items = Array(self.items.dropFirst(self.maximumBatchSize))
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	public func finalize() {
		// Nothing to do if no items
		guard !self.items.isEmpty else { return }
		
		// Call proc
		self.proc(self.items)

		// Cleanup
		self.items.removeAll()
	}
}
