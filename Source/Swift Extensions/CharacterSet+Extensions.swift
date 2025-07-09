//
//  CharacterSet+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 6/3/25.
//  Copyright © 2025 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: CharacterSet extension
public extension CharacterSet {

	// MARK: Properties
	static	let	decimalDigitsPlusPeriod = CharacterSet.decimalDigits.union(CharacterSet(charactersIn: "."))
}
