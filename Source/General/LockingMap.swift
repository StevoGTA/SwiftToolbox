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
			var	keys :[T] { return self.mapLock.read() { return Array(self.map.keys) } }

	private	var	map = [T : U]()
	private	let	mapLock = ReadPreferringReadWriteLock()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init() {}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func value(for key :T) -> U? { return self.mapLock.read() { return self.map[key] } }

	//------------------------------------------------------------------------------------------------------------------
	public func set(_ value :U?, for key :T) { self.mapLock.write() { self.map[key] = value } }

	//------------------------------------------------------------------------------------------------------------------
	public func remove(_ keys :[T]) { self.mapLock.write() { keys.forEach() { self.map[$0] = nil } } }
}
