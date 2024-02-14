//
//  DateFormatter+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 4/13/22.
//  Copyright © 2022 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: DateFormatter extensions
public extension DateFormatter {

	// MARK: Properties
	static	let	iso8601 :DateFormatter = DateFormatter(dateFormat: "yyyy-MM-dd'T'HH:mm:ssZ")
	static	let	rfc3339 :DateFormatter = DateFormatter(dateFormat: "yyyy-MM-dd'T'HH:mm:ssZ")
	static	let	rfc3339Extended :DateFormatter = DateFormatter(dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSZ")

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	convenience init(dateFormat :String) {
		// Do super
		self.init()

		// Setup
		self.dateFormat = dateFormat
	}
}
