//
//  Folder.swift
//  Swift Toolbox
//
//  Created by Stevo on 9/22/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: Folder
public class Folder {

	// MARK: Types
	enum Action {
		case process
		case ignore
	}

	typealias SubPathProc = (_ folder :Folder, _ subPath :String) -> Void
	typealias SubPathDeepProc = (_ folder :Folder, _ subPath :String) -> Action

	// MARK: Properties
	let	url :URL

	var	name :String { self.url.lastPathComponent }
	var	path :String { self.url.path }

	// MARK: Class methods
	//------------------------------------------------------------------------------------------------------------------
	static func from(_ url :URL?) -> Folder? { (url != nil) ? Folder(url!) : nil }

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(_ url :URL) {
		// Store
		self.url = url
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func folder(with subPath :String) -> Folder { Folder(self.url.appendingPathComponent(subPath)) }

	//------------------------------------------------------------------------------------------------------------------
	func file(with subPath :String) -> File { File(self.url.appendingPathComponent(subPath)) }
}
