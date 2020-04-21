//
//  NotificationCenter+Extensions.swift
//  Virtual Sheet Music
//
//  Created by Stevo on 4/8/20.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: NotificationCenter extension
extension NotificationCenter {

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func addObserver(forName name :Notification.Name, object :Any? = nil,
			using :@escaping (_ notification :Notification) -> Void) {
		// Add observer
		addObserver(forName: name, object: object, queue: nil, using: using)
	}

	//------------------------------------------------------------------------------------------------------------------
    func post(name :NSNotification.Name) { post(name: name, object: nil) }
}
