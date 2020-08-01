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
	public	var	keys :[T] { return self.lock.read() { Array(self.map.keys) } }
	public	var	values :[U] { return self.lock.read() { Array(self.map.values) } }

	private	let	lock = ReadPreferringReadWriteLock()

	private	var	map = [T : U]()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init() {}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func value(for key :T) -> U? { return self.lock.read() { self.map[key] } }

	//------------------------------------------------------------------------------------------------------------------
	public func set(_ value :U?, for key :T) { self.lock.write() { self.map[key] = value } }

	//------------------------------------------------------------------------------------------------------------------
	public func merge(_ map :[T : U]) { self.lock.write() { self.map.merge(map, uniquingKeysWith: { $1 }) } }

	//------------------------------------------------------------------------------------------------------------------
	public func update(for key :T, with proc :(_ previous :U?) -> U?) {
		// Update value under lock
		self.lock.write() {
			// Retrieve current value
			let	value = self.map[key]
			self.map[key] = nil

			// Call proc and set new value
			self.map[key] = proc(value)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	public func remove(_ key :T) { self.lock.write() { self.map[key] = nil } }
	
	//------------------------------------------------------------------------------------------------------------------
	public func remove(_ keys :[T]) { self.lock.write() { keys.forEach() { self.map[$0] = nil } } }

	//------------------------------------------------------------------------------------------------------------------
	public func removeAll() { self.lock.write() { self.map.removeAll() } }
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: LockingArrayMap
public class LockingArrayDictionary<T : Hashable, U> {

	// MARK: Properties
	public	var	isEmpty :Bool { return self.lock.read() { self.map.isEmpty } }
	public	var	values :[U] { return self.lock.read() { Array(self.map.values.joined()) } }

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
	public func values(for key :T) -> [U]? { return self.lock.read() { self.map[key] } }
}
