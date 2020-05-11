//
//  Date+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 11/23/16.
//  Copyright © 2016 Stevo Brock. All rights reserved.
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

	static			let	iso8601DateFormatter :DateFormatter = {
								// Setup
								let	dateFormatter = DateFormatter()
								dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

								return dateFormatter
							}()
	static			let	rfc3339DateFormatter :DateFormatter = {
								let	dateFormatter = DateFormatter()
								dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

								return dateFormatter
							}()
	static			let	rfc3339ExtendedDateFormatter :DateFormatter = {
								let	dateFormatter = DateFormatter()
								dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

								return dateFormatter
							}()

					var	iso8601 :String { return Date.iso8601DateFormatter.string(from: self) }
					var	rfc3339 :String { return Date.rfc3339DateFormatter.string(from: self) }
					var	rfc3339Extended :String { return Date.rfc3339ExtendedDateFormatter.string(from: self) }

	// MARK: Class methods
	//------------------------------------------------------------------------------------------------------------------
	static public func withTimeIntervalSince1970(_ timeIntervalSince1970 :TimeInterval?) -> Date? {
		// Return date, maybe
		return (timeIntervalSince1970 != nil) ? Date(timeIntervalSince1970: timeIntervalSince1970!) : nil
	}

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init?(fromISO8601 string :String?) {
		// Preflight
		guard string != nil else { return nil }

		// Setup
		if let date = type(of: self).iso8601DateFormatter.date(from: string!) {
			// Got date
			self.init(timeIntervalSinceNow: date.timeIntervalSinceNow)
		} else {
			// Invalid
			return nil
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	init?(fromRFC3339 string :String?) {
		// Preflight
		guard string != nil else { return nil }

		// Setup
		if let date = type(of: self).rfc3339DateFormatter.date(from: string!) {
			// Got date
			self.init(timeIntervalSinceNow: date.timeIntervalSinceNow)
		} else {
			// Invalid
			return nil
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	init?(fromRFC3339Extended string :String?) {
		// Preflight
		guard string != nil else { return nil }

		// Setup
		if let date = type(of: self).rfc3339ExtendedDateFormatter.date(from: string!) {
			// Got date
			self.init(timeIntervalSinceNow: date.timeIntervalSinceNow)
		} else {
			// Invalid
			return nil
		}
	}
}
