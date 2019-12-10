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
	public	var	values :[T] { return self.lock.read() { return self.array } }

	private	let	lock = ReadPreferringReadWriteLock()

	private	var	array = [T]()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init() {}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func append(_ value :T) { self.lock.write() { self.array.append(value) } }

	//------------------------------------------------------------------------------------------------------------------
	public func removeAll() { self.lock.write() { self.array.removeAll() } }
}
