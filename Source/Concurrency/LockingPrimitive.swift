//
//  LockingPrimitive.swift
//  Swift Toolbox
//
//  Created by Stevo on 11/6/19.
//  Copyright © 2019 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: LockingPrimitive
public class LockingPrimitive<T : Numeric> {

	// MARK: Properties
	public	var	value :T { return self.lock.read() { return self.valueInternal } }

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
	public func set(_ value :T) {
		// Set
		self.lock.write() { self.valueInternal = value }
	}

	//------------------------------------------------------------------------------------------------------------------
	public func add(_ value :T) {
		// Add
		self.lock.write() { self.valueInternal += value }
	}

	//------------------------------------------------------------------------------------------------------------------
	public func subtract(_ value :T) {
		// Add
		self.lock.write() { self.valueInternal -= value }
	}
}
