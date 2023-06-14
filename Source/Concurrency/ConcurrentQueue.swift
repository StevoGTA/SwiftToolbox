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

	public enum Priority : Int {
		case background
		case normal
		case high
	}

	// MARK: Properties
	private	let	maxConcurrentItems :Int

	private	let	itemsLock = Lock()
	private	let	activeItemsCount = LockingNumeric<Int>()
	private	var	queuedItems = [(item :T, priority :Priority)]()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(maxConcurrentItems :ConcurrentItems = .coreCountMinus(1)) {
		// Setup
		self.maxConcurrentItems = maxConcurrentItems.resolved(with: ProcessInfo.processInfo.processorCount)
	}

	//------------------------------------------------------------------------------------------------------------------
	public convenience init(maxConcurrentItems :Int) {
		// Call designated initializor
		self.init(maxConcurrentItems: .specified(maxConcurrentItems))
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func add(_ item :T, priority :Priority = .normal) {
		// Add
		self.itemsLock.perform() { self.queuedItems.append((item, priority)) }

		// Process
		processItems()
	}

	//------------------------------------------------------------------------------------------------------------------
	public func add(_ items :[T], priority :Priority = .normal) {
		// Add
		self.itemsLock.perform() { self.queuedItems += items.map({ ($0, priority) }) }

		// Process
		processItems()
	}

	//------------------------------------------------------------------------------------------------------------------
	public func wait() { while !self.itemsLock.perform({ self.queuedItems.isEmpty }) { self.activeItemsCount.wait() } }

	// MARK: Subclass methods
	//------------------------------------------------------------------------------------------------------------------
	fileprivate func process(_ item :T, completion :@escaping () -> Void) {}

	// MARK: Private methods
	//------------------------------------------------------------------------------------------------------------------
	private func processItems() {
		// Process
		self.itemsLock.perform() {
			// Check situation
			while (self.activeItemsCount.value < self.maxConcurrentItems) && !self.queuedItems.isEmpty {
				// Order by priority
				self.queuedItems.sort(by: { $0.priority.rawValue > $1.priority.rawValue })

				// Activate a queued item
				let	item = self.queuedItems.removeFirst()
				self.activeItemsCount.add(1)

				// Process
				process(item.item) { [weak self] in
					// Done
					self?.activeItemsCount.subtract(1)

					// Process more items
					DispatchQueue.main.async() { [weak self] in self?.processItems() }
				}
			}
		}
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - ProcConcurrentQueue
public class ProcConcurrentQueue<T> : ConcurrentQueue<T> {

	// MARK: Types
	public typealias Proc = (_ item :T) -> Void

	// MARK: Properties
	private	let	procDispatchQueue :DispatchQueue
	private	let	proc :Proc

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(maxConcurrentItems :ConcurrentItems = .coreCountMinus(1), procDispatchQueue :DispatchQueue = .global(),
			proc :@escaping Proc) {
		// Store
		self.procDispatchQueue = procDispatchQueue
		self.proc = proc

		// Do super
		super.init(maxConcurrentItems: maxConcurrentItems)
	}

	//------------------------------------------------------------------------------------------------------------------
	public convenience init(maxConcurrentItems :Int, procDispatchQueue :DispatchQueue = .global(),
			proc :@escaping Proc) {
		// Call designated initializor
		self.init(maxConcurrentItems: .specified(maxConcurrentItems), procDispatchQueue: procDispatchQueue, proc: proc)
	}

	// MARK: ConcurrentQueue methods
	//------------------------------------------------------------------------------------------------------------------
	fileprivate override func process(_ item :T, completion :@escaping () -> Void) {
		// Setup
		let	proc = self.proc

		// Perform
		self.procDispatchQueue.async() {
			// Perform
			proc(item)

			// Done
			completion()
		}
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - ConcurrentProcQueue
public class ConcurrentProcQueue : ConcurrentQueue< () -> Void> {

	// MARK: Properties
	private	let	procDispatchQueue :DispatchQueue

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(maxConcurrentItems :ConcurrentItems = .coreCountMinus(1),
			procDispatchQueue :DispatchQueue = .global()) {
		// Store
		self.procDispatchQueue = procDispatchQueue

		// Do super
		super.init(maxConcurrentItems: maxConcurrentItems)
	}

	//------------------------------------------------------------------------------------------------------------------
	public convenience init(maxConcurrentItems :Int, procDispatchQueue :DispatchQueue = .global()) {
		// Call designated initializor
		self.init(maxConcurrentItems: .specified(maxConcurrentItems), procDispatchQueue: procDispatchQueue)
	}

	// MARK: ConcurrentQueue methods
	//------------------------------------------------------------------------------------------------------------------
	fileprivate override func process(_ item :@escaping () -> Void, completion :@escaping () -> Void) {
		// Perform
		self.procDispatchQueue.async() {
			// Perform
			item()

			// Done
			completion()
		}
	}
}
