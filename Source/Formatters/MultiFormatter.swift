//
//  MultiFormatter.swift
//  ObjC Toolbox
//
//  Created by Stevo on 10/11/24.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: MultiFormatter
class MultiFormatter : Formatter {

	// MARK: Properties
	@objc			var	wasFilteredProc :() -> Void = {}

			private	let	allowedCharacterSet :CharacterSet?
			private	let	maxLength :Int?

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	@objc init(allowedCharacterSet :CharacterSet, maxLength :Int) {
		// Store
		self.allowedCharacterSet = allowedCharacterSet
		self.maxLength = maxLength

		// Do super
		super.init()
	}

	//------------------------------------------------------------------------------------------------------------------
	@objc init(allowedCharacterSet :CharacterSet) {
		// Store
		self.allowedCharacterSet = allowedCharacterSet
		self.maxLength = nil

		// Do super
		super.init()
	}

	//------------------------------------------------------------------------------------------------------------------
	@objc init(maxLength :Int) {
		// Store
		self.allowedCharacterSet = nil
		self.maxLength = maxLength

		// Do super
		super.init()
	}

	//------------------------------------------------------------------------------------------------------------------
	required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

	// MARK: Formatter methods
	//------------------------------------------------------------------------------------------------------------------
	override func string(for obj :Any?) -> String? { obj as? String }

	//------------------------------------------------------------------------------------------------------------------
	override func getObjectValue(_ obj :AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string :String,
			errorDescription error :AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
		// Return info
		obj?.pointee = string as AnyObject

		return true
	}

	//------------------------------------------------------------------------------------------------------------------
	override func isPartialStringValid(_ partialStringPtr :AutoreleasingUnsafeMutablePointer<NSString>,
			proposedSelectedRange proposedSelRangePtr :NSRangePointer?, originalString origString :String,
			originalSelectedRange origSelRange :NSRange,
			errorDescription error :AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
		// Setup
		let	initialLength = partialStringPtr.pointee.length

		// Check allowed characters
		if let allowedCharacterSet = self.allowedCharacterSet {
			// Remove dis-allowed characters
			partialStringPtr.pointee =
					String(partialStringPtr.pointee).filter({ allowedCharacterSet.contains($0.unicodeScalars.first!) })
							as NSString
		}

		// Check length
		if let maxLength = self.maxLength {
			// Trim
			partialStringPtr.pointee = String(partialStringPtr.pointee).prefix(maxLength) as NSString
		}

		if partialStringPtr.pointee.length == initialLength {
			// Unchanged
			return true
		} else {
			// Was filtered
			proposedSelRangePtr?.pointee = NSMakeRange(partialStringPtr.pointee.length, 0)

			// Call proc
			self.wasFilteredProc()

			return false
		}
	}
}
