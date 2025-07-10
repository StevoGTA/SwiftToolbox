//
//  AsyncQueue.swift
//  Swift Toolbox
//
//  Created by Stevo on 3/6/25.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: AsyncQueue
public class AsyncQueue<T> {

	// MARK: Properties
	private	let	maxConcurrency :Int
	private	let	items = LockingArray<T>()

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public init(maxConcurrency :Int = 6) {
		// Store
		self.maxConcurrency = maxConcurrency
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func add(item :T) { self.items.append(item) }

	//------------------------------------------------------------------------------------------------------------------
	public func add(items :[T]) { self.items.append(items) }

	//------------------------------------------------------------------------------------------------------------------
	public func waitForAll() async throws {
		// To the asyncs!
		try await withThrowingTaskGroup(of: Void.self) { group in
			// Keep trying until we have processed all items
			while !self.items.isEmpty {
				// Do them all
				var	concurrentItems = 0
				while !self.items.isEmpty {
					// Get first item
					let	item = self.items.removeFirst()

					// See if we need to wait
					if concurrentItems >= self.maxConcurrency { try await group.next() }

					// Add task
					concurrentItems += 1
					group.addTask() {
						// Process item
						try await self.process(item: item)

						// One less concurrent item
						concurrentItems -= 1
					}
				}

				// Wait
				try await group.waitForAll()
			}
		}
	}

	// MARK: Subclass methods
	//------------------------------------------------------------------------------------------------------------------
	public func process(item :T) async throws {}
}
