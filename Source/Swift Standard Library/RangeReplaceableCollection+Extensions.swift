//
//  RangeReplaceableCollection+Extensions.swift
//
//  Created by Stevo on 8/17/15.
//  Copyright © 2015 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: RangeReplaceableCollection Equatable Extension
extension RangeReplaceableCollection where Iterator.Element : Equatable {  

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public mutating func remove(_ object: Self.Iterator.Element) {
		// Find
		if let found = self.index(of: object) {
			// Remove
			self.remove(at: found)
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
