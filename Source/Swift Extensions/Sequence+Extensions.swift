//
//  Sequence+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 2/11/20.
//  Copyright © 2015 Stevo Brock. All rights reserved.
//

import Foundation

// MARK: Types
//----------------------------------------------------------------------------------------------------------------------
fileprivate	struct MapItem<T> {

	// MARK: Properties
	let	key :String
	let	element :T
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - Sequence Extension
extension Sequence {

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
    func sorted(stringKeyProc :(Self.Element) throws -> String,
			keyCompareProc: (String, String) -> Bool = { return $0 < $1 }) rethrows -> [Self.Element] {
		// Must have at least 2 elements
		guard self.underestimatedCount > 1 else { return Array(self) }

		// Create map
		var	map :[MapItem<Element>] =
					try autoreleasepool()
							{ return try self.map(
									{ return MapItem<Element>(key: try stringKeyProc($0), element: $0) }) }

		// Sort keys
		autoreleasepool() { map.sort(by: { return keyCompareProc($0.key, $1.key) }) }

		// Reconstruct sorted sequence
		let	sortedSequence = autoreleasepool() { return map.map({ return $0.element }) }

		return sortedSequence
	}
}
