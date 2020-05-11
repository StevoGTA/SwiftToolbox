//
//  String+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 8/21/15.
//  Copyright © 2015 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: String General extension
extension String {

	// MARK: Properties
	static	let	`nil` :String? = nil

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(combining components :[String], with separator :String = ", ") {
		// Setup
		var	string = ""

		// Iterate all components
		components.enumerated().forEach() {
			// Append to string
			if $0.offset == 0 {
				// Start of string
				string = $0.element
			} else {
				// Continuing
				string += separator + "\($0.element)"
			}
		}

		self.init(string)
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func toDouble() -> Double? {
		// Convert to double
		return NumberFormatter().number(from: self)?.doubleValue
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - String Substring Extension
extension String {

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func substring(toCharacterIndex index :Int) -> String {
		return String(self[..<self.index(self.startIndex, offsetBy: index)])
	}

	//------------------------------------------------------------------------------------------------------------------
	func substring(fromCharacterIndex index :Int) -> String {
		return String(self[self.index(self.startIndex, offsetBy: index)...])
	}

	//------------------------------------------------------------------------------------------------------------------
	func substring(fromCharacterIndex fromIndex :Int, toCharacterIndex toIndex :Int) -> String {
		let	startIndex = self.index(self.startIndex, offsetBy: fromIndex)
		let	endIndex = self.index(self.startIndex, offsetBy: toIndex)

		return String(self[startIndex..<endIndex])
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - String Path Extension
extension String {

	// MARK: Properties
	public	var	pathComponents :[String] {
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
	public	var	firstPathComponent :String? {
						// Get path components
						let	pathComponents = self.pathComponents

						return (pathComponents.count > 0) ? pathComponents.first! : nil
					}
	public	var	lastPathComponent :String? {
						// Get path components
						let	pathComponents = self.pathComponents

						return (pathComponents.count > 0) ? pathComponents.last! : nil
					}
	public	var	lastPathComponentWithoutPathExtension :String? {
						// Get path components
						let	pathComponents = self.pathComponents

						return (pathComponents.count > 0) ? pathComponents.last!.deletingPathExtension : nil
					}
	public	var	deletingFirstPathComponent :String {
						// Get path components
						let	pathComponents = self.pathComponents

						return (pathComponents.count > 1) ?
								self.substring(fromCharacterIndex: pathComponents.first!.count + 1) : ""
					}
	public	var	deletingLastPathComponent :String {
						// Get path components
						let	pathComponents = self.pathComponents

						return (pathComponents.count > 1) ?
								self.substring(toCharacterIndex: self.count - pathComponents.last!.count - 1) : ""
					}
	public	var	pathExtension :String? {
						// Split path by "."
						let	nameComponents = self.components(separatedBy: ".")

						return (nameComponents.count > 0) ? nameComponents.last! : nil
					}
	public	var	deletingPathExtension :String {
						// Split path by "."
						let	nameComponents = self.components(separatedBy: ".")

						return (nameComponents.count > 1) ?
								self.substring(toCharacterIndex: self.count - nameComponents.last!.count - 1) : self
					}

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(combiningPathComponents pathComponents :[String]) { self.init(combining: pathComponents, with: "/") }

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func appending(pathComponent :String) -> String {
		return self.isEmpty ? pathComponent : self + "/" + pathComponent
	}

	//------------------------------------------------------------------------------------------------------------------
	public func appending(pathExtension :String) -> String {
		return !pathExtension.isEmpty ? self + "." + pathExtension : self
	}

	//------------------------------------------------------------------------------------------------------------------
	public func subPath(relativeTo path :String) -> String? {
		// Return subPath
		return path.hasPrefix(self) ? path.substring(fromCharacterIndex: self.count) : nil
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - String Currency Extension
extension String {

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(currencyValueInCents value :Int, addDollarSign :Bool = true) {
		// Init with format
		self.init(format: addDollarSign ? "$%d:%02d" : "%d:%02d", value / 100, value % 100)
	}
}
