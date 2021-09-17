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

	// MARK: Types
	public typealias CreateValueProc = () -> U

	// MARK: Properties
	public	var	dictionary :[T : U] { self.lock.read({ self.map }) }
	public	var	count :Int { self.lock.read({ self.map.count }) }
	public	var	isEmpty :Bool { self.count == 0 }
	public	var	keys :[T] { self.lock.read({ Array(self.map.keys) }) }
	public	var	values :[U] { self.lock.read({ Array(self.map.values) }) }

	public	var	createValueProc :CreateValueProc?

	private	let	lock = ReadPreferringReadWriteLock()

	private	var	map = [T : U]()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(_ initial :[T : U]? = nil) {
		// Setup
		self.map = initial ?? [:]
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func value(for key :T) -> U? {
		// Check situation
		if let createValueProc = self.createValueProc {
			// Can create value if not found
			return self.lock.write() {
				// Check for current value
				if let u = self.map[key] {
					// Already have a value
					return u
				} else {
					// Create a new value
					let	u = createValueProc()
					self.map[key] = u

					return u
				}
			}
		} else {
			// No creating
			return self.lock.read() { self.map[key] }
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func set(_ value :U?, for key :T) -> Self { self.lock.write({ self.map[key] = value }); return self }

	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func merge(_ map :[T : U]) -> Self {
		// Perform under lock
		self.lock.write({ self.map.merge(map, uniquingKeysWith: { $1 }) });

		return self
	}

	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func update(for key :T, with proc :(_ previous :U?) -> U?) -> Self {
		// Perform under lock
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
	@discardableResult
	public func remove(_ keys :[T]) -> Self { self.lock.write() { keys.forEach() { self.map[$0] = nil } }; return self }

	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func removeAll() -> [T : U] {
		// Perform under lock
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
// MARK: - LockingArrayMap
public class LockingArrayDictionary<T : Hashable, U> {

	// MARK: Properties
	public	var	isEmpty :Bool { self.lock.read() { self.map.isEmpty } }
	public	var	allValues :[U] { self.lock.read() { Array(self.map.values.joined()) } }

	private	let	lock = ReadPreferringReadWriteLock()

	private	var	map = [T : [U]]()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init() {}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func append(_ value :U, for key :T) {
		// Perform under lock
		self.lock.write() {
			// Check if have existing array
			if var array = self.map[key] {
				// Have existing array
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

	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func remove(_ key :T) -> [U]? {
		// Perform under lock
		self.lock.write() {
			// Get array
			let	array = self.map[key]

			// Remove array
			self.map[key] = nil

			return array
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	public func removeAll() { self.lock.write() { self.map.removeAll() } }
}

extension LockingArrayDictionary where U : Equatable {

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func remove(_ value :U, for key :T) {
		// Perform under lock
		self.lock.write() {
			// Check if has existing array
			if var array = self.map[key] {
				// Have existing array
				self.map[key] = nil
				array.removeAll(where: { $0 == value })
				if !array.isEmpty { self.map[key] = array }
			}
		}
	}
}
