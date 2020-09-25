//
//  RangeReplaceableCollection+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 8/17/15.
//  Copyright © 2015 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: RangeReplaceableCollection Equatable Extension
extension RangeReplaceableCollection where Iterator.Element : Equatable {  

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func contains(_ element :Self.Iterator.Element) -> Bool { firstIndex(of: element) != nil }

	//------------------------------------------------------------------------------------------------------------------
	public mutating func remove(_ element: Self.Iterator.Element) {
		// Find
		if let found = firstIndex(of: element) {
			// Remove
			remove(at: found)
		}  
	}

	//------------------------------------------------------------------------------------------------------------------
	public mutating func remove(_ array :[Self.Iterator.Element]) {
		// Iterate array
		array.forEach() {
			// Check for existence in this array
			if let index = firstIndex(of: $0) {
				// Remove
				remove(at: index)
			}
		}
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - RangeReplaceableCollection Hashable Extension
extension RangeReplaceableCollection where Self.Iterator.Element: Hashable {

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func uniq() -> Self {
		// Setup
		var seen :Set<Self.Iterator.Element> = Set()

		// Reduce
		return reduce(Self()) { result, item in
			// Check if seen
			if seen.contains(item) {
				// Return no add
				return result
			} else {
				// Return add
				seen.insert(item)

				return result + [item]
			}
		}
	}
}
