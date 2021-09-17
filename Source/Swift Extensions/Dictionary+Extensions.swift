//
//  Dictionary+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 12/3/18.
//  Copyright © 2018 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: Dictionary extension for convenience initializers
public extension Dictionary {

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(_ pairs :[Element]) {
		// Init
		self.init()

		// Iterate elements and construct dictionary
		pairs.forEach() { self[$0.key] = $0.value }
	}

	//------------------------------------------------------------------------------------------------------------------
	init(_ keys :[Key], valueProc :(_ key :Key) -> Value?) {
		// Init
		self.init()

		// Iterate keys and construct dicctionary
		keys.forEach() { self[$0] = valueProc($0) }
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func map<T, U>(keyProc :(_ key :Key) -> T = { $0 as! T },
			valueProc :(_ value :Value) -> U = { $0 as! U }) -> [T : U] {
		// Setup
		Dictionary<T, U>(self.map({ (keyProc($0), valueProc($1)) }))
	}

	//------------------------------------------------------------------------------------------------------------------
	mutating func removeValues(forKeys keys :[Key]) { keys.forEach() { self[$0] = nil } }
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: Dictionary extension for values of Arrays and Sets
public extension Dictionary {

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func stringArray(for key :Key) -> [String]? {
		// Check what we have
		if let array = self[key] as? [String] {
			// Have array
			return array
		} else if let string = self[key] as? String {
			// Have string
			return [string]
		} else {
			// Neither
			return nil
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	mutating func appendArrayValueElement<T>(key :Key, value :T) {
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
	mutating func insertSetValueElement<T : Hashable>(key :Key, value :T) {
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

//----------------------------------------------------------------------------------------------------------------------
// MARK: - Dictionary extension for String keys and Any values
public extension Dictionary where Key == String, Value == Any {

	// MARK: Properties
	var	data :Data { try! JSONSerialization.data(withJSONObject: self, options: []) }

	// MARK: Class methods
	//------------------------------------------------------------------------------------------------------------------
	static func from(_ data :Data?) -> [Key : Value]? {
		// Return info
		return (data != nil) ?
				try! JSONSerialization.jsonObject(with: data!, options: []) as! [Key : Value] : nil
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func equals(_ other :[Key : Value]) -> Bool {
		// Key count must match
		guard self.count == other.count else { return false }

		// Iterate all keys/values
		for (key, value) in self {
			// Ensure other dictionary has value for this key
			guard let otherValue = other[key] else { return false }

			// Compare values
			if let array = value as? [String], let otherArray = otherValue as? [String], array == otherArray { continue }
			if let bool = value as? Bool, let otherBool = otherValue as? Bool, bool == otherBool { continue }
			if let dictionary = value as? [String : Any], let otherDictionary = otherValue as? [String : Any], dictionary.equals(otherDictionary) { continue }
			if let double = value as? Double, let otherDouble = otherValue as? Double, double == otherDouble { continue }
			if let int = value as? Int, let otherInt = otherValue as? Int, int == otherInt { continue }
			if let int64 = value as? Int64, let otherInt64 = otherValue as? Int64, int64 == otherInt64 { continue }
			if let string = value as? String, let otherString = otherValue as? String, string == otherString { continue }

			return false
		}

		return true
	}
}
