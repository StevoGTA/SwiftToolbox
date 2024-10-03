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

extension DateError : CustomStringConvertible, LocalizedError {

	// MARK: Properties
	public 	var	description :String { self.localizedDescription }
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

					var	beginningOfDay :Date
							{ Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day],
									from: self))! }
					var	endOfDay :Date {
								// Setup
								var	dateComponents = DateComponents()
								dateComponents.day = 1
								dateComponents.second = -1

								return Calendar.current.date(byAdding: dateComponents, to: self.beginningOfDay)!
							}

			public	var	iso8601String :String { DateFormatter.iso8601.string(from: self) }
			public	var	rfc3339String :String { DateFormatter.rfc3339.string(from: self) }
			public	var	rfc3339ExtendedString :String { DateFormatter.rfc3339Extended.string(from: self) }

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
		if let date = DateFormatter.iso8601.date(from: string!) {
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
		if let date = DateFormatter.rfc3339.date(from: string!) {
			// Got date
			self.init(timeIntervalSinceNow: date.timeIntervalSinceNow)
		} else {
			// Invalid
			return nil
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	public init?(fromRFC3339Extended string :String?) {
		// Preflight
		guard string != nil else { return nil }

		// Setup
		if let date = DateFormatter.rfc3339Extended.date(from: string!) {
			// Got date
			self.init(timeIntervalSinceNow: date.timeIntervalSinceNow)
		} else {
			// Invalid
			return nil
		}
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func adding(months :Int) -> Date {
		// Setup
		var	dateComponents = DateComponents()
		dateComponents.month = months

		return NSCalendar.current.date(byAdding: dateComponents, to: self)!
	}

	//------------------------------------------------------------------------------------------------------------------
	func adding(years :Int) -> Date {
		// Setup
		var	dateComponents = DateComponents()
		dateComponents.year = years

		return NSCalendar.current.date(byAdding: dateComponents, to: self)!
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - Dictionary extension for String keys and Data values
public extension Dictionary where Key == String, Value == Data {

	// Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func date(for key :String, dateFormatter :DateFormatter = .rfc3339Extended) -> Date? {
		// Try to get data
		guard let data = self[key] else { return nil }
		guard let string = String(data: data, encoding: .utf8) else { return nil }

		return dateFormatter.date(from: string)
	}
}
