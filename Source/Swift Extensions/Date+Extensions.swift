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
			self = date
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
			self = date
		} else {
			// Invalid
			return nil
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	public init?(fromRFC3339Extended string :String?) {
		// Preflight
		guard string != nil else { return nil }

		// Read the form rfc3339ExtendedString writes, "yyyy-MM-dd'T'HH:mm:ss.SSS±HHmm", directly
		let	timeIntervalSince1970 =
					string!.utf8.withContiguousStorageIfAvailable() { bytes -> TimeInterval? in
						// Check length and separators
						guard (bytes.count == 28), (bytes[4] == 0x2D), (bytes[7] == 0x2D), (bytes[10] == 0x54),
								(bytes[13] == 0x3A), (bytes[16] == 0x3A), (bytes[19] == 0x2E),
								(bytes[23] == 0x2B) || (bytes[23] == 0x2D) else { return nil }

						// Read numbers
						func number(at index :Int, count :Int) -> Int? {
							// Accumulate digits
							var	value = 0
							for byte in bytes[index..<(index + count)] {
								// Check digit
								guard (byte >= 0x30) && (byte <= 0x39) else { return nil }
								value = value * 10 + Int(byte - 0x30)
							}

							return value
						}
						guard let year = number(at: 0, count: 4), year >= 1600,
								let month = number(at: 5, count: 2), (month >= 1) && (month <= 12),
								let day = number(at: 8, count: 2), day >= 1,
								let hour = number(at: 11, count: 2), hour < 24,
								let minute = number(at: 14, count: 2), minute < 60,
								let second = number(at: 17, count: 2), second < 60,
								let millisecond = number(at: 20, count: 3),
								let offsetHours = number(at: 24, count: 2), offsetHours < 24,
								let offsetMinutes = number(at: 26, count: 2), offsetMinutes < 60 else { return nil }

						// Check day is within month
						let	isLeapYear = ((year % 4) == 0) && (((year % 100) != 0) || ((year % 400) == 0))
						let	daysInMonth =
									(month == 2) ?
											(isLeapYear ? 29 : 28) : (((month == 4) || (month == 6) || (month == 9) ||
															(month == 11)) ?
													30 : 31)
						guard day <= daysInMonth else { return nil }

						// Compose days since 1970-01-01 in the Gregorian calendar (years start in March so the leap day
						//	comes last)
						let	marchYear = (month <= 2) ? year - 1 : year
						let	era = marchYear / 400
						let	yearOfEra = marchYear - era * 400
						let	dayOfYear = (153 * ((month + 9) % 12) + 2) / 5 + day - 1
						let	dayOfEra = yearOfEra * 365 + yearOfEra / 4 - yearOfEra / 100 + dayOfYear
						let	days = era * 146097 + dayOfEra - 719468

						// Compose milliseconds, then seconds the same way DateFormatter does
						let	offsetSeconds = (offsetHours * 3600 + offsetMinutes * 60) * ((bytes[23] == 0x2D) ? -1 : 1)
						let	seconds = days * 86400 + hour * 3600 + minute * 60 + second - offsetSeconds

						return Double(seconds * 1000 + millisecond) / 1000.0
					} ?? nil

		// Check results
		if let timeIntervalSince1970 = timeIntervalSince1970 {
			// Read directly
			self.init(timeIntervalSince1970: timeIntervalSince1970)
		} else if let date = DateFormatter.rfc3339Extended.date(from: string!) {
			// Read by DateFormatter
			self = date
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
