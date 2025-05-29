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
	public	let	payloadPos :UInt64
	public	let	payloadByteCount :UInt64
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: Container Atom
public struct ContainerAtom {

	// MARK: Properties
	public	let	atoms :[Atom]

	// MARK: Instance methods
	//--------------------------------------------------------------------------------------------------------------
	public func atom(ofType type :OSType) -> Atom? { self.atoms.first(where: { $0.type == type }) }
}
