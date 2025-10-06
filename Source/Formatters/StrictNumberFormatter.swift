//
//  StrictNumberFormatter.swift
//  ObjC Toolbox
//
//  Created by Stevo on 2/21/25.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: StrictNumberFormatter
class StrictNumberFormatter : NumberFormatter, @unchecked Sendable {

	// MARK: NumberFormatter methods
	//--------------------------------------------------------------------------------------------------------------
	override func isPartialStringValid(_ partialString :String,
			newEditingString newString :AutoreleasingUnsafeMutablePointer<NSString?>?,
			errorDescription error :AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
		// Check if valid
		if partialString.isEmpty { return true };

		// Check if supporting floats
		if self.allowsFloats {
			// Supports floats
			guard let value = Float(partialString) else { return false }

			return ((self.minimum == nil) || (value >= Float(truncating: self.minimum!))) &&
					((self.maximum == nil) || (value <= Float(truncating: self.maximum!)))
		} else {
			// Only integers
			guard let value = Int(partialString) else { return false }

			return ((self.minimum == nil) || (value >= Int(truncating: self.minimum!))) &&
					((self.maximum == nil) || (value <= Int(truncating: self.maximum!)))
		}
	}
}
