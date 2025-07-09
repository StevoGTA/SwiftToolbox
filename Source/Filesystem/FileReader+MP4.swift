//
//  FileReader+MP4.swift
//  Swift Toolbox
//
//  Created by Stevo on 5/29/25.
//  Copyright © 2025 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: FileReader MP4 extension
public extension FileReader {

	// MARK: Sco64AtomPayload
	fileprivate struct Sco64AtomPayload {

		// MARK: Properties
		let	packetGroupOffsets :[Int64]

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		init(_ data :Data) throws {
			// Unpack values
			let	values = try PackedStruct.unpack(data: data, format: ">4BI")
			let	packetGroupOffsetCount = values[4] as! UInt32

			var	packetGroupOffsets = [Int64]()
			for _ in 0..<packetGroupOffsetCount {
				// Unpack chunk
				let subdata = data.subdata(fromIndex: 8 + packetGroupOffsets.count * 8, length: 8) ?? Data()
				packetGroupOffsets.append(Int64(subdata.asUInt64BE!))
			}

			// Store
			self.packetGroupOffsets = packetGroupOffsets
		}
	}

	// MARK: SxmlAtomPayload
	fileprivate struct SxmlAtomPayload {

		// MARK: Properties
		let	string :String

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		init(_ data :Data) throws {
			// Unpack values
			let	values = try PackedStruct.unpack(data: data, format: ">4Bs")

			// Store
			self.string = values[4] as! String
		}
	}

	// MARK: ShdlrAtomPayload
	fileprivate struct ShdlrAtomPayload {

		// MARK: SubTypes
		enum SubType : FourCharCode {
			case metadata = "meta"
			case sound = "soun"
			case video = "vide"
		}

		// MARK: Properties
		let	subType :FourCharCode

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		init(_ data :Data) throws {
			// Unpack values
			let	values = try PackedStruct.unpack(data: data, format: ">4B5I")

			// Store
			self.subType = values[5] as! FourCharCode
		}
	}

	// MARK: SstscAtomPayload
	fileprivate struct SstscAtomPayload {

		// MARK: PacketGroupInfo
		struct PacketGroupInfo {

			// MARK: Properties
			let	chunkStartIndex :Int
			let	packetCount :Int
			let	sampleDescriptionIndex :Int

			// MARK: Lifecycle methods
			init(_ data :Data) throws {
				// Unpack values
				let	values = try PackedStruct.unpack(data: data, format: ">3I")

				// Store
				self.chunkStartIndex = Int(values[0] as! UInt32)
				self.packetCount = Int(values[1] as! UInt32)
				self.sampleDescriptionIndex = Int(values[2] as! UInt32)
			}
		}

		// MARK: Properties
		let	packetGroupInfos :[PacketGroupInfo]

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		init(_ data :Data) throws {
			// Unpack values
			let	values = try PackedStruct.unpack(data: data, format: ">4BI")
			let	packetGroupInfoCount = values[4] as! UInt32

			var	packetGroupInfos = [PacketGroupInfo]()
			for _ in 0..<packetGroupInfoCount {
				// Unpack chunk
				let subdata = data.subdata(fromIndex: 8 + packetGroupInfos.count * 12, length: 12) ?? Data()
				packetGroupInfos.append(try PacketGroupInfo(subdata))
			}

			// Store
			self.packetGroupInfos = packetGroupInfos
		}
	}

	// MARK: SstcoAtomPayload
	fileprivate struct SstcoAtomPayload {

		// MARK: Properties
		let	packetGroupOffsets :[Int64]

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		init(_ data :Data) throws {
			// Unpack values
			let	values = try PackedStruct.unpack(data: data, format: ">4BI")
			let	packetGroupOffsetCount = values[4] as! UInt32

			var	packetGroupOffsets = [Int64]()
			for _ in 0..<packetGroupOffsetCount {
				// Unpack chunk
				let subdata = data.subdata(fromIndex: 8 + packetGroupOffsets.count * 4, length: 4) ?? Data()
				packetGroupOffsets.append(Int64(subdata.asUInt32BE!))
			}

			// Store
			self.packetGroupOffsets = packetGroupOffsets
		}
	}

	// MARK: SstszAtomPayload
	fileprivate struct SstszAtomPayload {

		// MARK: Properties
		let	globalPacketByteCount :Int
		let	packetByteCounts :[Int]

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		init(_ data :Data) throws {
			// Unpack values
			let	values = try PackedStruct.unpack(data: data, format: ">4B2I")
			let	globalPacketByteCount = values[4] as! UInt32
			let	packetByteCountCount = values[5] as! UInt32

			var	packetByteCounts = [Int]()
			if globalPacketByteCount == 0 {
				// No global packet byte count
				for _ in 0..<packetByteCountCount {
					// Unpack chunk
					let subdata = data.subdata(fromIndex: 12 + packetByteCounts.count * 4, length: 4) ?? Data()
					packetByteCounts.append(Int(subdata.asUInt32BE!))
				}
			}

			// Store
			self.globalPacketByteCount = Int(globalPacketByteCount)
			self.packetByteCounts = packetByteCounts
		}
	}

	// MARK: SsttsAtomPayload
	fileprivate struct SsttsAtomPayload {

		// MARK: Chunk
		struct Chunk {

			// MARK: Properties
			let	packetCount :Int
			let	packetDuration :Int

			// MARK: Lifecycle methods
			init(_ data :Data) throws {
				// Unpack values
				let	values = try PackedStruct.unpack(data: data, format: ">2I")

				// Store
				self.packetCount = Int(values[0] as! UInt32)
				self.packetDuration = Int(values[1] as! UInt32)
			}
		}

		// MARK: Properties
		let	chunks :[Chunk]

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		init(_ data :Data) throws {
			// Unpack values
			let	values = try PackedStruct.unpack(data: data, format: ">4BI")
			let	chunkCount = values[4] as! UInt32

			var	chunks = [Chunk]()
			for _ in 0..<chunkCount {
				// Unpack chunk
				let subdata = data.subdata(fromIndex: 8 + chunks.count * 8, length: 8) ?? Data()
				chunks.append(try Chunk(subdata))
			}

			// Store
			self.chunks = chunks
		}
	}

	// MARK: MP4Error
	enum MP4Error : Swift.Error {
		case notAnMP4File(_ file :File)
	}

	// MARK: Metadata Kinds
	enum Metadata {
		case xml(_ xmlDocument :XMLDocument)
	}

	// MARK: Class methods
	//------------------------------------------------------------------------------------------------------------------
	static func iterateMetadata(from file :File, proc :(_ metadata :Metadata) -> Void) throws {
		// Setup
		let	fileReader = FileReader(file)

		// Open file
		try fileReader.open()

		// Check file type
		var atom = try fileReader.readAtom()
		guard atom.type == "ftyp" else { throw MP4Error.notAnMP4File(file) }

		// Iterate top-level atoms
		while true {
			// Catch errors
			do {
				// Read next atom
				try? fileReader.seekToAtom(after: atom)
				atom = try fileReader.readAtom()

				// Check atom type
				switch atom.type {
					case "meta":
						// meta
						if let metaContainerAtom = try? fileReader.readAsContainerAtom(atom, contentByteCount: 4),
								let xmlAtom = metaContainerAtom.atom(ofType: "xml "),
								let xmlAtomPayload = try? SxmlAtomPayload(try fileReader.readAtomPayload(xmlAtom)),
								let xmlDocument = try? XMLDocument(xmlString: xmlAtomPayload.string) {
							// Call proc
							proc(.xml(xmlDocument))
						}

					default:
						// Skip
						break
				}
			} catch {
				// All done
				return
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	static private func composePacketAndLocations(fileReader :FileReader, stsdAtom :Atom,
			stblContainerAtom :ContainerAtom, sttsAtomPayload :SsttsAtomPayload, stscAtomPayload :SstscAtomPayload,
			stszAtomPayload :SstszAtomPayload, stcoAtomPayload :SstcoAtomPayload?, co64AtomPayload :Sco64AtomPayload?)
			-> [Media.PacketAndLocation] {
		// Setup
		let	packetGroupOffsets = stcoAtomPayload?.packetGroupOffsets ?? co64AtomPayload!.packetGroupOffsets

		// Construct info
		var	stszPacketByteCountIndex = 0

		var	stscPacketGroupInfoIndex = 0
		var	stscPacketGroupInfoPacketCount = stscAtomPayload.packetGroupInfos[stscPacketGroupInfoIndex].packetCount

		var	stcoBlockOffsetIndex = 0

		var	currentBlockPacketIndex = 0
		var	currentByteOffset = packetGroupOffsets[stcoBlockOffsetIndex]

		// Iterate all stts entries
		let	sttsChunkCount = sttsAtomPayload.chunks.count
		var	packetAndLocations = [Media.PacketAndLocation]()
		for sttsChunkIndex in 0..<sttsChunkCount {
			// Get packet info
			let	sttsChunk = sttsAtomPayload.chunks[sttsChunkIndex]
			let	sttsChunkPacketCount = sttsChunk.packetCount
			let	sttsChunkPacketDuration = sttsChunk.packetDuration

			// Iterate packets
			var	packetIndex = 0
			while (packetIndex < sttsChunkPacketCount) {
				// Get info
				let	packetByteCount =
							(stszAtomPayload.globalPacketByteCount > 0) ?
									stszAtomPayload.globalPacketByteCount :
									stszAtomPayload.packetByteCounts[stszPacketByteCountIndex]

				// Add Packet Location Info
				packetAndLocations.append(
						Media.PacketAndLocation(
								packet: Media.Packet(duration: sttsChunkPacketDuration, byteCount: packetByteCount),
								byteOffset: currentByteOffset))

				// Update
				currentBlockPacketIndex += 1
				if currentBlockPacketIndex < stscPacketGroupInfoPacketCount {
					// Still more to go in this block
					currentByteOffset += Int64(packetByteCount)
				} else {
					// Finished with this block
					let	blockOffsetCount =
								stcoAtomPayload?.packetGroupOffsets.count ?? co64AtomPayload!.packetGroupOffsets.count

					stcoBlockOffsetIndex += 1
					if stcoBlockOffsetIndex < blockOffsetCount {
						// Update info
						currentBlockPacketIndex = 0
						currentByteOffset = packetGroupOffsets[stcoBlockOffsetIndex]

						// Check if have more block groups
						if (stscPacketGroupInfoIndex + 1)  < stscAtomPayload.packetGroupInfos.count {
							// Check if next block group
							let	nextBlockStartIndex =
										stscAtomPayload.packetGroupInfos[stscPacketGroupInfoIndex + 1].chunkStartIndex
							if ((stcoBlockOffsetIndex + 1) == nextBlockStartIndex) {
								// Next block group
								stscPacketGroupInfoIndex += 1
								stscPacketGroupInfoPacketCount =
										stscAtomPayload.packetGroupInfos[stscPacketGroupInfoIndex].packetCount
							}
						}
					}
				}

				// Update
				packetIndex += 1
				stszPacketByteCountIndex += 1
			}
		}

		return packetAndLocations
	}
}

//----------------------------------------------------------------------------------------------------------------------
//MARK: - FileReader.MP4Error extension
extension FileReader.MP4Error : CustomStringConvertible, LocalizedError {

	// MARK: Properties
	public 	var	description :String { self.localizedDescription }
	public	var	errorDescription :String? {
						switch self {
							case .notAnMP4File(let file):	return "\(file.path) is not an MP4 file"
						}
					}
}
