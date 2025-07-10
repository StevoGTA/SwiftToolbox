//
//  Equatable+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 2/20/25.
//  Copyright © 2025 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: Equatable extension
fileprivate extension Equatable {

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func isEqual(to: Any) -> Bool { self == (to as? Self) }
}

// MARK: - Global functions
//----------------------------------------------------------------------------------------------------------------------
// Normally would be coalesced into following function, but separate function needed for Xcode 13.4.1
func ==<T : Equatable>(lhs :T?, rhs :T?) -> Bool {
    // Ensure we have values
    guard let lhs = lhs, let rhs = rhs else { return (lhs == nil) && (rhs == nil) }

    return lhs.isEqual(to: rhs)
}

//----------------------------------------------------------------------------------------------------------------------
func ==<T>(lhs: T?, rhs: T?) -> Bool where T: Any {
	// Ensure we have values (coded to work in Xcode 13.4.1
	guard let lhs = lhs, let rhs = rhs else { return (lhs == nil) && (rhs == nil) }

	// Check types - Array, [AnyHashable : String]
    if let lhs = (lhs as? [Any]), let rhs = (rhs as? [Any]) {
		// Array check
        return (lhs.count == rhs.count) && lhs.elementsEqual(rhs, by: ==)
	} else if let lhs = (lhs as? [AnyHashable: Any]), let rhs = (rhs as? [AnyHashable: Any]) {
		// AnyHashable check
		return (lhs.count == rhs.count) && lhs.allSatisfy({ $1 == rhs[$0] })
	} else {
		// Don't know how to check
		return false
	}
}

//----------------------------------------------------------------------------------------------------------------------
func !=<T>(lhs: T?, rhs: T?) -> Bool where T: Any { !(lhs == rhs) }
