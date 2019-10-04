//
//  Dictionary+Extensions.swift
//
//  Created by Stevo on 12/3/18.
//  Copyright © 2018 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: Dictionary extension for array values
extension Dictionary where Key == String {

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public mutating func appendArrayValueElement<T>(key :Key, value :T) {
		// Check if has existing array
		if var array = (self[key] as? [T]) {
			// Has existing array
			self[key] = nil
			array.append(value)
			self[key] = (array as! Value)
		} else {
			// First item
			self[key] = ([value] as! Value)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	mutating func appendArrayValueElements<T>(key :Key, values :[T]) {
		// Check if has existing array
		if var array = (self[key] as? [T]) {
			// Has existing array
			self[key] = nil
			array += values
			self[key] = (array as! Value)
		} else {
			// First item
			self[key] = (values as! Value)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	mutating func removeArrayValueElement<T :Equatable>(key :Key, value :T) {
		// Check if have existing array
		if var array = (self[key] as? [T]) {
			// Has existing array
			self[key] = nil

			// Remove value
			array.remove(value)

			// Check if need to store
			if !array.isEmpty {
				// Store
				self[key] = (array as! Value)
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	mutating func appendSetValueElement<T : Hashable>(key :Key, value :T) {
		// Retrieve set
		var	set = (self[key] as? Set<T>) ?? Set<T>()
		self[key] = nil

		// Inset value
		set.insert(value)

		// Update us
		self[key] = (set as! Value)
	}

	//------------------------------------------------------------------------------------------------------------------
	mutating func removeSetValueElement<T :Hashable>(key :Key, value :T) {
		// Check if have existing set
		if var set = (self[key] as? Set<T>) {
			// Have existing set
			self[key] = nil

			// Remove value
			set.remove(value)

			// Check if need to store
			if !set.isEmpty {
				// Store
				self[key] = (set as! Value)
			}
		}
	}
}
