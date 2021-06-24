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
public class Folder : Equatable {

	// MARK: Types
	public enum Action {
		case process
		case ignore
	}

	public typealias SubPathProc = (_ folder :Folder, _ subPath :String) -> Void
	public typealias SubPathDeepProc = (_ folder :Folder, _ subPath :String) -> Action

	// MARK: Properties
	static			let	temporary = Folder(URL(fileURLWithPath: NSTemporaryDirectory()))

			public	let	url :URL

			public	var	name :String { self.url.lastPathComponent }
			public	var	path :String { self.url.path }

	// MARK: Equatable methods
	//------------------------------------------------------------------------------------------------------------------
	public static func == (lhs: Folder, rhs: Folder) -> Bool { lhs.url == rhs.url }

	// MARK: Class methods
	//------------------------------------------------------------------------------------------------------------------
	static func from(_ url :URL?) -> Folder? { (url != nil) ? Folder(url!) : nil }

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(_ url :URL) {
		// Store
		self.url = url
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func folder(with subPath :String) -> Folder { Folder(self.url.appendingPathComponent(subPath)) }

	//------------------------------------------------------------------------------------------------------------------
	public func file(with subPath :String) -> File { File(self.url.appendingPathComponent(subPath)) }

	//------------------------------------------------------------------------------------------------------------------
	public func subPath(for folder :Folder) -> String { folder.path.subPath(relativeTo: self.path)! }

	//------------------------------------------------------------------------------------------------------------------
	public func subPath(for file :File) -> String { file.path.subPath(relativeTo: self.path)! }
}
