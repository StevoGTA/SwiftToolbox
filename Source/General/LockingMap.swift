//
//  LockingMap.swift
//  Swift Toolbox
//
//  Created by Stevo on 10/29/19.
//  Copyright © 2019 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: LockingMap
public class LockingMap<T : Hashable, U> {

	// MARK: Properties
	public	var	keys :[T] { return self.lock.read() { return Array(self.map.keys) } }
	public	var	values :[U] { return self.lock.read() { return Array(self.map.values) } }

	private	let	lock = ReadPreferringReadWriteLock()

	private	var	map = [T : U]()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init() {}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func value(for key :T) -> U? { return self.lock.read() { return self.map[key] } }

	//------------------------------------------------------------------------------------------------------------------
	public func set(_ value :U?, for key :T) { self.lock.write() { self.map[key] = value } }

	//------------------------------------------------------------------------------------------------------------------
	public func merge(_ map :[T : U]) { self.lock.write() { self.map.merge(map) { $1 } } }

	//------------------------------------------------------------------------------------------------------------------
	public func remove(_ keys :[T]) { self.lock.write() { keys.forEach() { self.map[$0] = nil } } }
}
