//
//  AnyComparable.swift
//  Swift Toolbox
//
//  Created by Stevo on 3/17/21.
//  Copyright © 2021 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: AnyComparable
public struct AnyComparable : Comparable, Equatable {

	// MARK: Types
	public typealias CompareProc = (_ lhs :AnyComparable, _ rhs :AnyComparable) -> Bool

	// MARK: BoxBase
	class BoxBase {

		// MARK: Properties
		var	value :Any { fatalError("Must be overridden") }

		// MARK: Methods
		func compare(_ other :BoxBase) -> Bool { fatalError("Must be overridden") }
		func equals(_ other :BoxBase) -> Bool { fatalError("Must be overridden") }
	}

	// MARK: Box
	class Box<T : Comparable> : BoxBase {

		// MARK :Properties
					let	t :T

		override	var	value :Any { t }

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		init(_ t : T) { self.t = t }

		// MARK: BoxBase methods
		//--------------------------------------------------------------------------------------------------------------
		override func compare(_ other :BoxBase) -> Bool { self.t < (other as! Box<T>).t }

		//--------------------------------------------------------------------------------------------------------------
		override func equals(_ other :BoxBase) -> Bool { self.t == (other as! Box<T>).t }
	}

	// MARK: Properties
	public	var	value :Any { self.boxBase.value }

	private	let	boxBase :BoxBase

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init<T : Comparable>(_ t :T) {
		// Store
		self.boxBase = Box(t)
	}

	// MARK: Comparable implementation
	//------------------------------------------------------------------------------------------------------------------
	public static func < (lhs :AnyComparable, rhs :AnyComparable) -> Bool { lhs.boxBase.compare(rhs.boxBase) }

	// MARK: Equatable implementation
	//------------------------------------------------------------------------------------------------------------------
	public static func == (lhs :AnyComparable, rhs :AnyComparable) -> Bool { lhs.boxBase.equals(rhs.boxBase) }
}
