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
	public	var	values :Set<T> { return self.lock.read() { return self.set } }
	
	private	let	lock = ReadPreferringReadWriteLock()

	private	var	set = Set<T>()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init() {}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func contains(_ value :T) -> Bool { return self.lock.read() { return self.set.contains(value) } }

	//------------------------------------------------------------------------------------------------------------------
	public func insert(_ value :T) { self.lock.write() { self.set.insert(value) } }

	//------------------------------------------------------------------------------------------------------------------
	public func formUnion(_ values: [T]) { self.lock.write() { self.set.formUnion(values) } }

	//------------------------------------------------------------------------------------------------------------------
	public func remove(_ value :T) { self.lock.write() { self.set.remove(value) } }

	//------------------------------------------------------------------------------------------------------------------
	public func removeAll() { self.lock.write() { self.set.removeAll() } }
}
