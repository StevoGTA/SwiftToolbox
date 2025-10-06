//
//  MaxLengthFormatter.swift
//  ObjC Toolbox
//
//  Created by Stevo on 9/20/24.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: MaxLengthFormatter
class MaxLengthFormatter : Formatter {

	// MARK: Properties
	@objc			var	wasFilteredProc :() -> Void = {}

			private	let	maxLength :Int

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	@objc init(maxLength :Int) {
		// Store
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
		// Check length
		if partialStringPtr.pointee.length <= self.maxLength { return true }

		// Trim
		partialStringPtr.pointee = String(partialStringPtr.pointee).prefix(self.maxLength) as NSString
		proposedSelRangePtr?.pointee = NSMakeRange(self.maxLength, 0)

		// Call proc
		self.wasFilteredProc()

		return false;
	}
}
