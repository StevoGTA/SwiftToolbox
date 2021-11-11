//
//  Sequence+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 2/11/20.
//  Copyright © 2015 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: Types
fileprivate struct MapItem<T, U> {

	// MARK: Properties
	let	key :T
	let	element :U
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - Sequence Extension
extension Sequence {

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func sorted<T : Comparable>(keyProc :(Self.Element) throws -> T,
			keyCompareProc: (T, T) -> Bool = { $0 < $1 }) rethrows -> [Self.Element] {
		// Must have at least 2 elements
		guard self.underestimatedCount > 1 else { return Array(self) }

		// Create map
		var	map :[MapItem<T, Element>] =
					try autoreleasepool()
							{ try self.map({ MapItem<T, Element>(key: try keyProc($0), element: $0) }) }

		// Sort keys
		autoreleasepool() { map.sort(by: { keyCompareProc($0.key, $1.key) }) }

		// Reconstruct sorted sequence
		let	sortedSequence = autoreleasepool() { map.map({ $0.element }) }

		return sortedSequence
	}
}
