//
//  String+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 8/21/15.
//  Copyright © 2015 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: Currency Extension
extension String {

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(currencyValueInCents value :Int, addDollarSign :Bool = true) {
		// Init with format
		self.init(format: addDollarSign ? "$%d.%02d" : "%d.%02d", value / 100, value % 100)
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - General extension
extension String {

	// MARK: RandomCharacterOptions
	public struct RandomCharacterOptions : OptionSet {

		// MARK: Properties
		static	public	let	lowercaseLetters = RandomCharacterOptions(rawValue: 1 << 0)
		static	public	let	uppercaseLetters = RandomCharacterOptions(rawValue: 1 << 1)
		static	public	let	numbers = RandomCharacterOptions(rawValue: 1 << 2)

				public	let	rawValue :Int

		// MARK: Lifecycle methods
		public init(rawValue :Int) { self.rawValue = rawValue }
	}

	// MARK: Properties
	static	let	`nil` :String? = nil

			var	capitalizingFirstLetter :String { self.prefix(1).capitalized + self.dropFirst() }
			var	removingLeadingAndTrailingQuotes :String {
						// Check for leading and trailing quotes
						let	hasLeadingQuote = hasPrefix("\"") || hasPrefix("'")
						let	hasTrailingQuote = hasSuffix("\"") || hasSuffix("'")

						return (hasLeadingQuote || hasTrailingQuote) ?
								substring(fromCharacterIndex: hasLeadingQuote ? 1 : 0,
										toCharacterIndex: hasTrailingQuote ? (self.count - 1) : self.count) :
								self
					}
			var	asDouble :Double? { NumberFormatter().number(from: self)?.doubleValue }

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init<T : ExpressibleByStringInterpolation>(combining components :[T], with separator :String = ", ") {
		// Setup
		var	string = ""

		// Iterate all components
		components.enumerated().forEach() {
			// Append to string
			if $0.offset == 0 {
				// Start of string
				string = "\($0.element)"
			} else {
				// Continuing
				string += separator + "\($0.element)"
			}
		}

		self.init(string)
	}

	//------------------------------------------------------------------------------------------------------------------
	public init(randomCharactersOfLength length :Int,
			options :RandomCharacterOptions = [.lowercaseLetters, .uppercaseLetters, .numbers]) {
		// Setup
		var	characters = ""
		if options.contains(.lowercaseLetters) { characters += "abcdefghijklmnopqrstuvwxyz" }
		if options.contains(.uppercaseLetters) { characters += "ABCDEFGHIJKLMNOPQRSTUVWXYZ" }
		if options.contains(.numbers) { characters += "0123456789" }

		self.init((0..<length).map{ _ in characters.randomElement()! })
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func filtered(by characterSet :CharacterSet) -> String {
		// Return filtered string
		return String(self.unicodeScalars.filter({ characterSet.contains($0) }))
	}

	//------------------------------------------------------------------------------------------------------------------
	func alignedLeft(fieldWidth :Int) -> String { self.withCString() { String(format: "%-\(fieldWidth)s", $0) } }

	//------------------------------------------------------------------------------------------------------------------
	func alignedRight(fieldWidth :Int) -> String { self.withCString() { String(format: "%\(fieldWidth)s", $0) } }

	//------------------------------------------------------------------------------------------------------------------
	func centered(fieldWidth :Int) -> String {
		// Check if need padding
        guard fieldWidth > self.count else { return self }

        // Setup
		let padding = fieldWidth - self.count
        let paddingRight = padding / 2
        guard paddingRight > 0 else { return " " + self }

        let paddingLeft = (padding % 2 == 0) ? paddingRight : paddingRight + 1

        return " ".withCString() { String(format: "%\(paddingLeft)s\(self)%\(paddingRight)s", $0, $0) }
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - HTTPRequest/HTTPResponse extension
public extension String {

	// MARK: Properties
	var	httpRequestRange :(start :Int64, length :Int64)? {
				// Examples:
				//	bytes=0-499
				let	components = self.components(separatedBy: "=")
				guard components.count == 2 else { return nil }
				guard components[0] == "bytes" else { return nil }

				let parts = components[1].components(separatedBy: "-")
				guard parts.count == 2 else { return nil }
				guard let start = Int64(parts[0]) else { return nil }
				guard let end = Int64(parts[1]) else { return nil }

				return (start, end - start + 1)
			}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - Path Extension
public extension String {

	// MARK: Properties
	var	pathComponents :[String] {
				// What's our deal?
				if self.isEmpty {
					// Empty
					return []
				} else if hasPrefix("/") {
					// /asdfasdfa
					return dropFirst(1).components(separatedBy: "/")
				} else {
					// asdfa/asdf
					return components(separatedBy: "/")
				}
			}
	var	firstPathComponent :String? { self.pathComponents.first }
	var	lastPathComponent :String? { self.pathComponents.last }
	var	lastPathComponentWithoutPathExtension :String? { self.pathComponents.last?.deletingPathExtension }
	var	deletingFirstPathComponent :String {
				// Get path components
				let	pathComponents = self.pathComponents

				return (pathComponents.count > 1) ?
						self.substring(fromCharacterIndex: pathComponents.first!.count + 1) : ""
			}
	var	deletingLastPathComponent :String {
				// Get path components
				let	pathComponents = self.pathComponents

				return (pathComponents.count > 1) ?
						self.substring(toCharacterIndex: self.count - pathComponents.last!.count - 1) : ""
			}
	var	pathExtension :String? {
				// Setup
				let	components = self.components(separatedBy: ".")

				return (components.count > 1) ? components.last : nil
			}
	var	deletingPathExtension :String {
				// Split path by "."
				let	nameComponents = self.components(separatedBy: ".")

				return (nameComponents.count > 1) ?
						self.substring(toCharacterIndex: self.count - nameComponents.last!.count - 1) : self
			}

	// MARK: Class methods
	//------------------------------------------------------------------------------------------------------------------
	static func allTreeSubPaths(given leafSubPaths :[String]) -> Set<String> {
		// Setup
		var	subPaths = Set<String>(!leafSubPaths.isEmpty ? [""] : [])
		leafSubPaths.forEach() {
			// Add all folder subPaths going up the tree
			var	subPath = $0
			while !subPath.isEmpty {
				// Add
				subPaths.insert(subPath)

				// Go up a level
				subPath = subPath.deletingLastPathComponent
			}
		}

		return subPaths
	}

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(combiningPathComponents pathComponents :[String]) { self.init(combining: pathComponents, with: "/") }

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func appending(pathComponent :String) -> String {
		// Return correct path considering:
		//	- self may be empty
		//	- self may end in "/"
		//	- pathComponent may be empty
		//	- pathComponent may start with "/"
		if self.isEmpty {
			// Self is empty
			return pathComponent
		} else if pathComponent.isEmpty {
			// Path component is empty
			return self
		} else {
			// Neither are empty
			return (self.hasSuffix("/") ? self : self + "/") +
					(pathComponent.hasPrefix("/") ? pathComponent.substring(fromCharacterIndex: 1) : pathComponent)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func appending(pathExtension :String) -> String { !pathExtension.isEmpty ? self + "." + pathExtension : self }

	//------------------------------------------------------------------------------------------------------------------
	func lastPathComponents(_ count :Int) -> [String] { self.pathComponents.suffix(count) }

	//------------------------------------------------------------------------------------------------------------------
	func lastPathComponentsSubPath(_ count :Int) -> String { String(combining: lastPathComponents(count), with: "/") }

	//------------------------------------------------------------------------------------------------------------------
	func subPath(relativeTo path :String) -> String? {
		// Ensure common root
		guard hasPrefix(path) else { return nil }

		// Get remaining part
		let	subPath = substring(fromCharacterIndex: path.count)

		return subPath.hasPrefix("/") ? subPath.substring(fromCharacterIndex: 1) : subPath
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - Substring Extension
extension String {

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func hasPrefix(from strings :Set<String>) -> Bool { strings.first(where: { self.hasPrefix($0) }) != nil }

	//------------------------------------------------------------------------------------------------------------------
	public func substring(toCharacterIndex index :Int) -> String {
		// Return string
		return String(self[..<self.index(self.startIndex, offsetBy: index)])
	}

	//------------------------------------------------------------------------------------------------------------------
	public func substring(fromCharacterIndex index :Int) -> String {
		// Return string
		return String(self[self.index(self.startIndex, offsetBy: index)...])
	}

	//------------------------------------------------------------------------------------------------------------------
	func substring(fromCharacterIndex fromIndex :Int, toCharacterIndex toIndex :Int) -> String {
		// Setup
		let	startIndex = self.index(self.startIndex, offsetBy: fromIndex)
		let	endIndex = self.index(self.startIndex, offsetBy: toIndex)

		return String(self[startIndex..<endIndex])
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - Time extension
enum TimeFormat {
	case minutesSeconds			// 00:00
	case hoursMinutesSeconds	// 00:00:00
}

extension String {

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(for timeInterval :TimeInterval, using timeFormat :TimeFormat) {
		// Check format
		var	timeIntervalUse = timeInterval
		switch timeFormat {
			case .minutesSeconds:
				// Minutes:Seconds
				let	minutes = Int((timeIntervalUse + 0.5) / 60.0)
				timeIntervalUse -= TimeInterval(minutes) * 60.0
				let	seconds = Int(timeIntervalUse + 0.5)
				self.init(format: "%02d:%02d", minutes, seconds)

			case .hoursMinutesSeconds:
				// Hours:Minutes:Seconds
				let	hours = Int((timeIntervalUse + 0.5) / 60.0 / 60.0)
				timeIntervalUse -= TimeInterval(hours) * 60.0 * 60.0
				let	minutes = Int((timeIntervalUse + 0.5) / 60.0)
				timeIntervalUse -= TimeInterval(minutes) * 60.0
				let	seconds = Int(timeIntervalUse + 0.5)
				self.init(format: "%02d:%02d:%02d", hours, minutes, seconds)
		}
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - Phone Number Extension
extension String {

	// MARK: Properties
	var	asPhoneNumberForDisplay :String {
				// Setup
				let	test = self + "          "
				let	areaCode = test.substring(toCharacterIndex: 3).filtered(by: .decimalDigits)
				let	prefix =
							test.substring(fromCharacterIndex: 3, toCharacterIndex: 6)
									.filtered(by: .decimalDigits)
				let	suffix =
							test.substring(fromCharacterIndex: 6, toCharacterIndex: 10)
									.filtered(by: .decimalDigits)

				// Check results
				if areaCode.isEmpty {
					// Nothing
					return ""
				} else if prefix.isEmpty {
					// Partial area code
					return "(\(areaCode)"
				} else if suffix.isEmpty {
					// Partial prefix
					return "(\(areaCode)) \(prefix)"
				} else {
					// Full-ish
					return "(\(areaCode)) \(prefix)-\(suffix)"
				}
			}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - URL extension
public extension String {

	// MARK: Properties
	static	private	let	pathTransformCharacterSet = CharacterSet(charactersIn: "/").inverted

					var	urlPathEncoded :String
							{ self.addingPercentEncoding(withAllowedCharacters: Self.pathTransformCharacterSet)! }

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func urlQueryEncoded(encodePlus :Bool) -> String {
		// Return encoded string
		return encodePlus ?
				self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
						.replacingOccurrences(of: "+", with: "%2B") :
				self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
	}
}
