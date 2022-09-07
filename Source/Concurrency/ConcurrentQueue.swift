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
	public enum ConcurrentItems {

		// MARK: Values
		case specified(_ value :Int)

		case coreCount
		case coreCountMinus(_ value :Int)

		case unlimited

		// MARK: Methods
		func resolved(with coreCount :Int) -> Int {
					// Check value
					switch self {
						case .specified(let value):			return min(coreCount, value)
						case .coreCount:					return coreCount
						case .coreCountMinus(let value):	return max(coreCount - value, 1)
						case .unlimited:					return .max
					}
				}
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
	public init(maxConcurrentItems :ConcurrentItems = .coreCountMinus(1), procDispatchQueue :DispatchQueue = .global(),
			proc :@escaping Proc) {
		// Setup
		self.maxConcurrentItems = maxConcurrentItems.resolved(with: ProcessInfo.processInfo.processorCount)

		// Store
		self.procDispatchQueue = procDispatchQueue
		self.proc = proc
	}

	//------------------------------------------------------------------------------------------------------------------
	public convenience init(maxConcurrentItems :Int, procDispatchQueue :DispatchQueue = .global(),
			proc :@escaping Proc) {
		// Call designated initializor
		self.init(maxConcurrentItems: .specified(maxConcurrentItems), procDispatchQueue: procDispatchQueue, proc: proc)
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
		// Process
		self.itemsLock.perform() {
			// Check situation
			while (self.activeItemsCount.value < self.maxConcurrentItems) && !self.queuedItems.isEmpty {
				// Activate a queued item
				let	item = self.queuedItems.removeFirst()
				self.activeItemsCount.add(1)

				// Perform
				self.procDispatchQueue.async() { [weak self] in
					// Perform
					self?.proc(item)

					// Done
					self?.activeItemsCount.subtract(1)

					// Process more items
					DispatchQueue.main.async() { [weak self] in self?.processItems() }
				}
			}
		}
	}
}
