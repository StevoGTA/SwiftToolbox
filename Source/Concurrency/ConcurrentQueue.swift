//
//  ConcurrentQueue.swift
//  Swift Toolbox
//
//  Created by Stevo on 3/8/22.
//  Copyright © 2022 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: ConcurrentQueue
public class ConcurrentQueue<T> {

	// MARK: Enums
	public enum MaxConcurrency {
		case specified(value :Int)
		case coresMinusOne
		case cores
		case unlimited
	}

	// MARK: Types
	public typealias Proc = (_ item :T) -> Void

	// MARK: Properties
	private	let	maxConcurrentItems :Int

	private	let	procDispatchQueue :DispatchQueue
	private	let	proc :Proc

	private	let	itemsLock = Lock()
	private	let	activeItemsCount = LockingNumeric<Int>()
	private	var	queuedItems = [T]()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(maxConcurrency :MaxConcurrency = .coresMinusOne, procDispatchQueue :DispatchQueue = .global(),
			proc :@escaping Proc) {
		// Setup
		switch maxConcurrency {
			case .specified(let value):	self.maxConcurrentItems = value
			case .coresMinusOne:		self.maxConcurrentItems = max(ProcessInfo.processInfo.processorCount - 1, 1)
			case .cores:				self.maxConcurrentItems = ProcessInfo.processInfo.processorCount
			case .unlimited:			self.maxConcurrentItems = .max
		}

		// Store
		self.procDispatchQueue = procDispatchQueue
		self.proc = proc
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func add(_ item :T) {
		// Add
		self.itemsLock.perform() { self.queuedItems.append(item) }

		// Process
		processItems()
	}

	//------------------------------------------------------------------------------------------------------------------
	public func add(_ items :[T]) {
		// Add
		self.itemsLock.perform() { self.queuedItems += items }

		// Process
		processItems()
	}

	//------------------------------------------------------------------------------------------------------------------
	public func wait() { self.activeItemsCount.wait() }

	// MARK: Private methods
	//------------------------------------------------------------------------------------------------------------------
	private func processItems() {
		// Setup
		let	procsDispatchQueue = self.procDispatchQueue
		let	proc = self.proc

		// Process
		self.itemsLock.perform() {
			// Check situation
			while (self.activeItemsCount.value < self.maxConcurrentItems) && !self.queuedItems.isEmpty {
				// Activate a queued item
				let	item = self.queuedItems.removeFirst()
				self.activeItemsCount.add(1)

				// Perform
				procsDispatchQueue.async() {
					// Perform
					proc(item)

					// Done
					self.activeItemsCount.subtract(1)

					// Process more items
					DispatchQueue.main.async() { [weak self] in self?.processItems() }
				}
			}
		}
	}
}
