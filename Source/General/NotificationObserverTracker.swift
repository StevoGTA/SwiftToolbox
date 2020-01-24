//
//  NotificationObserverTracker.swift
//  Swift Toolbox
//
//  Created by Stevo on 1/21/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: NotificationObserverTracker
class NotificationObserverTracker {

	// MARK: Properties
	private	var	notificationObservers =
						[(notificationCenter :NotificationCenter, notificationObserver :NSObjectProtocol)]()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	deinit {
		// Remove all notification observers
		self.notificationObservers.forEach() { $0.notificationCenter.removeObserver($0.notificationObserver) }
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func register(for name :NSNotification.Name, with object :Any? = nil, using queue :OperationQueue? = nil,
			in notificationCenter :NotificationCenter = NotificationCenter.default,
			proc: @escaping (Notification) -> Void) {
		// Append
		self.notificationObservers.append((notificationCenter,
				notificationCenter.addObserver(forName: name, object: object, queue: queue, using: proc)))
	}
}
