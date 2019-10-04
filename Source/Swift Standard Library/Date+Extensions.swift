//
//  Date+Extensions.swift
//
//  Created by Stevo on 11/23/16.
//  Copyright © 2016 Promere LLC. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: Date Error
enum DateError {
	case invalidStandardizedForm(string :String)
}

extension DateError : LocalizedError {

	// MARK: Properties
	public	var	errorDescription :String? {
						switch self {
							case .invalidStandardizedForm(let string):
								// Invalid standardized form
								return "Invalid standardized form \"\(string)\""
						}
					}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - Date extension
extension Date {

	// MARK: Properties
	static	public	let	`nil` :Date? = nil

	static			let	standardizedDateFormatter :DateFormatter = {
								let	dateFormatter = DateFormatter()
								dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

								return dateFormatter
							}()

					var	standardized :String { return Date.standardizedDateFormatter.string(from: self) }

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(fromStandardized standardizedString :String) throws {
		// Setup
		if let date = Date.standardizedDateFormatter.date(from: standardizedString) {
			// Got date
			self.init(timeIntervalSinceNow: date.timeIntervalSinceNow)
		} else {
			// Invalid
			throw DateError.invalidStandardizedForm(string: standardizedString)
		}
	}
}
