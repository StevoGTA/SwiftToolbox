//
//  NotificationCenter+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 4/8/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: NotificationCenter extension
public extension NotificationCenter {

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	func addObserver(forName name :Notification.Name, object :Any? = nil,
			using :@escaping (_ notification :Notification) -> Void) -> NSObjectProtocol {
		// Add observer
		return addObserver(forName: name, object: object, queue: nil, using: using)
	}

	//------------------------------------------------------------------------------------------------------------------
	func post(name :NSNotification.Name, userInfo :[AnyHashable : Any]) {
		// Post
		post(name: name, object: nil, userInfo: userInfo)
	}

	//------------------------------------------------------------------------------------------------------------------
	func post(name :NSNotification.Name) { post(name: name, object: nil) }
}
