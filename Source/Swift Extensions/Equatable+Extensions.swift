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
func ==<T>(lhs: T?, rhs: T?) -> Bool where T: Any {
	// Ensure we have values
	guard let lhs, let rhs else { return (lhs == nil) && (rhs == nil) }

	// Check types - plain, Array, AnyHashable
	if let isEqual = (lhs as? any Equatable)?.isEqual {
		// Plain check
		return isEqual(rhs)
	} else if let lhs = (lhs as? [Any]), let rhs = (rhs as? [Any]), lhs.count == rhs.count {
		// Array check
		return lhs.elementsEqual(rhs, by: ==)
	} else if let lhs = (lhs as? [AnyHashable: Any]), let rhs = (rhs as? [AnyHashable: Any]), lhs.count == rhs.count {
		// AnyHashable check
		return lhs.allSatisfy({ $1 == rhs[$0] })
	} else {
		// Don't know how to check
		return false
	}
}

//----------------------------------------------------------------------------------------------------------------------
func !=<T>(lhs: T?, rhs: T?) -> Bool where T: Any { !(lhs == rhs) }
