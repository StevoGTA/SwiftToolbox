//
//  Atom.swift
//  Swift Toolbox
//
//  Created by Stevo on 5/28/25.
//  Copyright © 2025 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: Atom
public struct Atom {

	// MARK: Properties
	public	let	type :OSType
	public	let	payloadPos :off_t
	public	let	payloadByteCount :off_t
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: Container Atom
public struct ContainerAtom {

	// MARK: Properties
	public	let	type :OSType
	public	let	payloadPos :off_t
	public	let	contentByteCount :off_t
	public	let	childAtoms :[Atom]

	// MARK: Lifecycle methods
	//--------------------------------------------------------------------------------------------------------------
	public init(atom :Atom, contentByteCount :off_t, childAtoms :[Atom]) {
		// Store
		self.type = atom.type
		self.payloadPos = atom.payloadPos
		self.contentByteCount = contentByteCount
		self.childAtoms = childAtoms
	}

	// MARK: Instance methods
	//--------------------------------------------------------------------------------------------------------------
	public func atom(ofType type :OSType) -> Atom? { self.childAtoms.first(where: { $0.type == type }) }
}
