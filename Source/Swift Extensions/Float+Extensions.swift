//
//  Float+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 6/3/25.
//  Copyright © 2025 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: Float Atom extension
public extension Float {

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init?(_ string :String?, validCharacterSet :CharacterSet? = nil) {
		// Check if string is nil
		guard string != nil else { return nil }

		// Check if have valid CharacterSet
		if validCharacterSet != nil {
			// Find any non-numeric
			let	endIndex =
						string!.unicodeScalars.firstIndex(where: { !validCharacterSet!.contains($0) }) ??
								string!.endIndex
			guard endIndex > string!.startIndex else { return nil }

			// Set value
			self.init(Float(string![string!.startIndex..<endIndex])!)
		} else {
			// Set value
			self.init(string!)
		}
	}
}
