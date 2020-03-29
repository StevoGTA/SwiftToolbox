//
//  UserDefaults+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 3/19/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: UserDefaults extensions
extension UserDefaults {

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func bool(forKey key :String, default value :Bool) -> Bool {
		return (UserDefaults.standard.object(forKey: key) as? NSNumber)?.boolValue ?? value
	}

	//------------------------------------------------------------------------------------------------------------------
	func float(forKey key :String, default value :Float) -> Float {
		return (UserDefaults.standard.object(forKey: key) as? NSNumber)?.floatValue ?? value
	}

	//------------------------------------------------------------------------------------------------------------------
	func double(forKey key :String, default value :Double) -> Double {
		return (UserDefaults.standard.object(forKey: key) as? NSNumber)?.doubleValue ?? value
	}
}
