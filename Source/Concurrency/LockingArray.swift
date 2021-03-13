//
//  LockingArray.swift
//  Swift Toolbox
//
//  Created by Stevo on 12/6/19.
//  Copyright © 2019 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: LockingArray
public class LockingArray<T> {

	// MARK: Properties
	public	var	count :Int { self.lock.read() { self.array.count } }
	public	var	isEmpty :Bool { self.lock.read() { self.array.isEmpty } }
	public	var	values :[T] { self.lock.read() { self.array } }

	private	let	lock = ReadPreferringReadWriteLock()

	private	var	array = [T]()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init() {}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func append(_ value :T) -> Self { self.lock.write({ self.array.append(value) }); return self }

	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func append(_ values :[T]) -> Self { self.lock.write({ self.array += values }); return self }

	//------------------------------------------------------------------------------------------------------------------
	public func forEach(proc :(_ value :T) -> Void) { self.lock.read({ self.array.forEach({ proc($0) }) }) }

	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func sort(by compareProc :(_ value1 :T, _ value2 :T) -> Bool) -> Self {
		// Sort
		self.lock.write({ self.array.sort(by: compareProc) })

		return self
	}

	//------------------------------------------------------------------------------------------------------------------
	public func removeFirst() -> T { self.lock.write({ self.array.removeFirst() }) }

	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func removeAll(where proc :(_ value :T) -> Bool) -> Self {
		// Remove all using proc
		self.lock.write({ self.array.removeAll(where: proc) })

		return self
	}

	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func removeAll() -> [T] {
		// Perform
		self.lock.write({
			// Get values
			let values = self.array

			// Remove all values
			self.array.removeAll()

			return values
		})
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - Operators
public func += <T>(left :inout LockingArray<T>, right :[T]) { left.append(right) }
