//
//  LockingPrimitives.swift
//  Swift Toolbox
//
//  Created by Stevo on 11/6/19.
//  Copyright © 2019 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: LockingValue
public class LockingValue<T> {

	// MARK: Properties
	public	var	value :T { self.lock.read() { self.valueInternal } }

	private	let	lock = ReadPreferringReadWriteLock()

	private	var	valueInternal :T

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(_ initialValue :T) {
		// Store
		self.valueInternal = initialValue
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func set(_ value :T) {
		// Set
		self.lock.write() { self.valueInternal = value }
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - LockingNumeric
public class LockingNumeric<T : Numeric> {

	// MARK: Properties
	public	var	value :T { self.lock.read() { self.valueInternal } }

	private	let	lock = ReadPreferringReadWriteLock()

	private	var	valueInternal :T

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(_ value :T = 0) {
		// Store
		self.valueInternal = value
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func set(_ value :T) -> Self {
		// Set
		self.lock.write() { self.valueInternal = value }

		return self
	}

	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func add(_ value :T) -> Self {
		// Add
		self.lock.write() { self.valueInternal += value }

		return self
	}

	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func subtract(_ value :T) -> Self {
		// Subtract
		self.lock.write() { self.valueInternal -= value }

		return self
	}
}
