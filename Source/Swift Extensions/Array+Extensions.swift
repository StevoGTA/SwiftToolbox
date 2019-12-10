//
//  Array+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 10/10/19.
//  Copyright © 2019 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: - Array Extension
extension Array {

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func collate<T, U>() -> (ts :[T], us :[U]) {
		// Setup
		var	ts = [T]()
		var	us = [U]()

		// Iterate
		forEach() {
			// Check type
			if let t = $0 as? T {
				// T
				ts.append(t)
			} else {
				// U
				us.append($0 as! U)
			}
		}

		return (ts, us)
	}

	//------------------------------------------------------------------------------------------------------------------
	public mutating func remove(for indexSet :IndexSet) {
		// From https://stackoverflow.com/questions/26173565/removeobjectsatindexes-for-swift-arrays
		// Preflight
		guard var i = indexSet.first, i < count else { return }

		// Setup
		var	j = index(after: i)
		var	k = indexSet.integerGreaterThan(i) ?? endIndex

		// Scan through the elements
		while j != endIndex {
			// Check elements
			if k != j {
				// Swap these 2 elements
				swapAt(i, j)
				formIndex(after: &i)
			} else {
				// Get next index
				k = indexSet.integerGreaterThan(k) ?? endIndex
			}

			// Get next index
			formIndex(after: &j)
		}

		// Do the remove
		removeSubrange(i...)
	}
}
