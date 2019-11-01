//
//  LockingSet.swift
//  Swift Toolbox
//
//  Created by Stevo on 10/30/19.
//  Copyright © 2019 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: LockingSet
public class LockingSet<T : Hashable> {

	// MARK: Properties
	private	var	set = Set<T>()
	private	let	setLock = ReadPreferringReadWriteLock()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init() {}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func insert(_ value :T) { self.setLock.write() { self.set.insert(value) } }

	//------------------------------------------------------------------------------------------------------------------
	public func remove(_ value :T) { self.setLock.write() { self.set.remove(value) } }

	//------------------------------------------------------------------------------------------------------------------
	public func contains(_ value :T) -> Bool { return self.setLock.read() { return self.set.contains(value) } }
}
