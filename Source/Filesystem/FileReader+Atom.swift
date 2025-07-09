//
//  FileReader+Atom.swift
//  Swift Toolbox
//
//  Created by Stevo on 5/29/25.
//  Copyright © 2025 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: FileReader Atom extension
extension FileReader {

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func readAtom() throws -> Atom {
		// Read byte count as UInt32
		let	byteCount32 = try read(byteCount: MemoryLayout<UInt32>.size).asUInt32BE!

		// Read type as OSType
		let	type = try read(byteCount: MemoryLayout<OSType>.size).asOSType!

		// Do we need to read byte count as UInt64?
		let	payloadByteCount :off_t
		if byteCount32 == 1 {
			// Yes
			payloadByteCount = off_t(try read(byteCount: MemoryLayout<UInt64>.size).asUInt64BE!) - 16
		} else {
			// No
			payloadByteCount = off_t(byteCount32) - 8
		}

		return Atom(type: type, payloadPos: try self.tell(), payloadByteCount: payloadByteCount)
	}

	//------------------------------------------------------------------------------------------------------------------
	func readAtomPayload(_ atom :Atom) throws -> Data {
		// Move to
		try seek(byteCount: atom.payloadPos, whence: SEEK_SET)

		return try read(byteCount: Int(atom.payloadByteCount))
	}

	//------------------------------------------------------------------------------------------------------------------
	func readAsContainerAtom(_ atom :Atom, contentByteCount :off_t = 0) throws -> ContainerAtom {
		// Move to
		try seek(byteCount: atom.payloadPos + contentByteCount, whence: SEEK_SET)

		// Read Atoms
		var	childAtoms = [Atom]()
		while (try tell()) < (atom.payloadPos + atom.payloadByteCount - contentByteCount) {
			// Get atom info
			let	childAtom = try readAtom()

			// Check for terminator atom
			if (childAtom.type == 0) || (childAtom.payloadByteCount == 0) {
				// Done
				break
			}

			// Add to array
			childAtoms.append(childAtom)

			// Seek
			try seekToAtom(after: childAtom)
		}

		return ContainerAtom(atom: atom, contentByteCount: contentByteCount, childAtoms: childAtoms)
	}

	//------------------------------------------------------------------------------------------------------------------
	func seekToAtom(after atom :Atom) throws {
		// Seek
		try seek(byteCount: atom.payloadPos + atom.payloadByteCount, whence: SEEK_SET)
	}
}
