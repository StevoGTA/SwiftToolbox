//
//  String+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 8/21/15.
//  Copyright © 2015 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: String General extension
extension String {

	// MARK: Properties
	static	let	`nil` :String? = nil

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(combining components :[String], with separator :String) {
		// Setup
		var	string = ""

		// Iterate all components
		components.forEach() {
			// Append to string
			if string.isEmpty {
				// Start of string
				string = $0
			} else {
				// Continuing
				string += separator + "\($0)"
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

						return (pathComponents.count > 0) ? pathComponents[0] : nil
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

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func appending(pathComponent :String) -> String {
		return self.isEmpty ? pathComponent : self + "/" + pathComponent
	}

	//------------------------------------------------------------------------------------------------------------------
	public func appending(pathExtension :String) -> String {
		return !pathExtension.isEmpty ? self + "." + pathExtension : self
	}
}
