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
// Could be coalesced into the function below, but this is needed for Xcode 13.4.1
func ==<T : Equatable>(lhs :T?, rhs :T?) -> Bool {
	// Check values
	switch (lhs, rhs) {
		case (.none, .none):					return true
		case (.none, .some), (.some, .none):	return false
		case (.some(let lhs), .some(let rhs)):	return lhs.isEqual(to: rhs)
	}
}

//----------------------------------------------------------------------------------------------------------------------
func ==<T>(lhs: T?, rhs: T?) -> Bool where T: Any {
	// Check values
	let	lhsValue :T, rhsValue :T
	switch (lhs, rhs) {
		case (.none, .none):					return true
		case (.none, .some), (.some, .none):	return false
		case (.some(let lhs), .some(let rhs)):	lhsValue = lhs; rhsValue = rhs
	}

	// Check runtime type
    if let lhs = (lhsValue as? [Any]), let rhs = (rhsValue as? [Any]) {
		// Array check
        return (lhs.count == rhs.count) && lhs.elementsEqual(rhs, by: ==)
	} else if let lhs = (lhsValue as? [AnyHashable: Any]), let rhs = (rhsValue as? [AnyHashable: Any]) {
		// AnyHashable check
		return (lhs.count == rhs.count) && lhs.allSatisfy({ $1 == rhs[$0] })
	} else if let lhs = (lhsValue as? AnyHashable), let rhs = (rhsValue as? AnyHashable) {
		// Hashable check - covers scalars, Sets, and anything else Hashable
		return lhs == rhs
	} else {
		// Don't know how to check
		return false
	}
}

//----------------------------------------------------------------------------------------------------------------------
func !=<T>(lhs: T?, rhs: T?) -> Bool where T: Any { !(lhs == rhs) }
