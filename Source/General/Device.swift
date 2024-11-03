//
//  Device.swift
//  Swift Toolbox
//
//  Created by Stevo Brock on 10/16/24.
//  Copyright © 2024 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: Device
struct Device {

	// Platform
	enum Platform {
		case desktop	// Desktop or Laptpo
		case device		// Device without a screen
		case mobile		// Phone or Tablet
		case tv			// TV
		case watch		// Watch
	}

	// Family
	enum Family : String {
		case appleTV
		case appleWatch
		case iPad
		case iPhone
		case mac
	}
}
