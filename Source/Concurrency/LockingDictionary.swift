//
//  LockingDictionary.swift
//  Swift Toolbox
//
//  Created by Stevo on 10/29/19.
//  Copyright © 2019 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: LockingDictionary
public class LockingDictionary<T : Hashable, U> {

	// MARK: Properties
	public	var	dictionary :[T : U] { self.lock.read({ self.map }) }
	public	var	count :Int { self.lock.read({ self.map.count }) }
	public	var	isEmpty :Bool { self.count == 0 }
	public	var	keys :[T] { self.lock.read({ Array(self.map.keys) }) }
	public	var	values :[U] { self.lock.read({ Array(self.map.values) }) }

	private	let	lock = ReadPreferringReadWriteLock()

	private	var	map = [T : U]()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init() {}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func value(for key :T) -> U? { self.lock.read() { self.map[key] } }

	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func set(_ value :U?, for key :T) -> Self { self.lock.write({ self.map[key] = value }); return self }

	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func merge(_ map :[T : U]) -> Self {
		// Perform with lock
		self.lock.write({ self.map.merge(map, uniquingKeysWith: { $1 }) });

		return self
	}

	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func update(for key :T, with proc :(_ previous :U?) -> U?) -> Self {
		// Update value under lock
		self.lock.write() {
			// Retrieve current value
			let	value = self.map[key]
			self.map[key] = nil

			// Call proc and set new value
			self.map[key] = proc(value)
		}

		return self
	}

	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func remove(_ key :T) -> U? {
		// Perform under lock
		self.lock.write() {
			// Retrieve value
			let value = self.map[key]

			// Remove
			self.map[key] = nil

			return value
		}
	}
	
	//------------------------------------------------------------------------------------------------------------------
	public func remove(_ keys :[T]) { self.lock.write() { keys.forEach() { self.map[$0] = nil } } }

	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func removeAll() -> [T : U] {
		// Perform
		self.lock.write() {
			// Get map
			let map = self.map

			// Remove all
			self.map.removeAll()

			return map
		}
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: LockingArrayMap
public class LockingArrayDictionary<T : Hashable, U> {

	// MARK: Properties
	public	var	isEmpty :Bool { self.lock.read() { self.map.isEmpty } }
	public	var	values :[U] { self.lock.read() { Array(self.map.values.joined()) } }

	private	let	lock = ReadPreferringReadWriteLock()

	private	var	map = [T : [U]]()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init() {}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func appendArrayValue(_ value :U, for key :T) {
		// Perform under lock
		self.lock.write() {
			// Check if has existing array
			if var array = self.map[key] {
				// Has existing array
				self.map[key] = nil
				array.append(value)
				self.map[key] = array
			} else {
				// First item
				self.map[key] = [value]
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	public func values(for key :T) -> [U]? { self.lock.read() { self.map[key] } }
}
