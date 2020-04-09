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
    func post(name :NSNotification.Name) { post(name: name, object: nil) }
}
