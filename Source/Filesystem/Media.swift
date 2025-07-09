//
//  Media.swift
//  Swift Toolbox
//
//  Created by Stevo on 6/2/25.
//  Copyright © 2025 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: Media
struct Media {

	// MARK: Packet
	struct Packet {

		// MARK: Properties
		let	duration :Int
		let	byteCount :Int
	}

	// MARK: PacketAndLocation
	struct PacketAndLocation {

		// MARK: Properties
		let	packet :Packet
		let	byteOffset :Int64
	}
}
