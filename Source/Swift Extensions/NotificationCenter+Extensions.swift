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

	// MARK: Observer
	class Observer {

		// MARK: Properties
		private	var	opaque :NSObjectProtocol

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		@MainActor
		init(name :NSNotification.Name, object :Any? = nil, queue :OperationQueue? = nil,
				proc :@escaping @Sendable (_ notification :Notification) -> Void) {
			// Setup
			self.opaque =
					NotificationCenter.default.addObserver(forName: name, object: object, queue: queue, using: proc)
		}

		//--------------------------------------------------------------------------------------------------------------
		deinit {
			// Cleanup
			NotificationCenter.default.removeObserver(self.opaque)
		}
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	func addObserver(forName name :Notification.Name, object :Any? = nil,
			using :@escaping @Sendable (_ notification :Notification) -> Void) -> NSObjectProtocol {
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
