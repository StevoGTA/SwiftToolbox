//
//  PackedStruct.swift
//  Swift Toolbox
//
//  Created by Stevo on 5/29/25.
//  Copyright © 2025 Stevo Brock. All rights reserved.
//
//	Cloned and modified from original source by Per Olofsson on 2014-06-13.
//  Copyright (c) 2014 AutoMac. All rights reserved.
//	https://github.com/MagerValp/MVPCStruct/blob/master/MVPCStruct/CStruct.swift
//

//      BYTE ORDER      SIZE            ALIGNMENT
//  @   native          native          native
//  =   native          standard        none
//  <   little-endian   standard        none
//  >   big-endian      standard        none
//  !   network (BE)    standard        none


//      FORMAT  C TYPE                  SWIFT TYPE              SIZE
//      x       pad byte                no value
//      c       char                    String of length 1      1
//      b       signed char             Int                     1
//      B       unsigned char           UInt                    1
//      ?       _Bool                   Bool                    1
//      h       short                   Int                     2
//      H       unsigned short          UInt                    2
//      i       int                     Int                     4
//      I       unsigned int            UInt                    4
//      l       long                    Int                     4
//      L       unsigned long           UInt                    4
//      q       long long               Int                     8
//      Q       unsigned long long      UInt                    8
//      f       float                   Float                   4
//      d       double                  Double                  8
//      s       char[]                  String
//      p       char[]                  String
//      P       void *                  UInt                    4/8
//
//      Floats and doubles are packed with IEEE 754 binary32 or binary64 format.

//----------------------------------------------------------------------------------------------------------------------
// MARK: PackedStruct
struct PackedStruct {

	// MARK: Endianness
    enum Endianness {
    	// MARK: Values
    	case big
    	case little

    	// MARK: Properties
#if _endian(big)
		static	let	native :Endianness = .big
#else
		static	let	native :Endianness = .little
#endif
    }

	// MARK: Error
	enum Error : Swift.Error {
		case insufficientData
		case invalidData(_ character :Character)
		case invalidFormat(_ character :Character)
	}

	// MARK: Class methods
	//------------------------------------------------------------------------------------------------------------------
	static func unpack(data :Data, format :String) throws -> [Any] {
		// Iterate format
		var	count = 0
		var	endianness = Endianness.native
		var	index = 0
		var	values = [Any]()
		for c in format {
			// Check for integer
			if let value = Int(String(c)) {
				// Integer
				count = count * 10 + value
				continue
			}

			// Check if count is 0.
			if count == 0 {
				// Should be a control character
				switch c {
					case "@":
						// Native endian, aligned
						endianness = .native
						continue

					case "=":
						// Native endian, unaligned
						endianness = .native
						continue

					case "<":
						// Little endian, unaligned
						endianness = .little
						continue

					case ">":
						// Big endian, unaligned
						endianness = .big
						continue

					case " ":
						// Ignore whitespace
						continue

					default:
						// No control character
						count = 1
				}
			}

			// Check action
			if (c == "s") && (count > 0) {
				// Fixed-length string
				guard let subdata = data.subdata(fromIndex: index, length: count) else
						{ throw Error.insufficientData }
				guard let string = String(data: subdata, encoding: .utf8) else { throw Error.invalidData(c) }

				values.append(string)
				index += count
			} else {
				// Loop on count
				for _ in 0..<count {
					// Check action
					switch c {
						case "x":
							// Skip
							index += 1

						case "c":
							// char
							guard let value = data.subdata(fromIndex: index, length: 1)?.asUInt8 else
									{ throw Error.insufficientData }

							values.append(Character(UnicodeScalar(value)))
							index += 1

						case "?":
							// bool
							guard let value = data.subdata(fromIndex: index, length: 1)?.asUInt8 else
									{ throw Error.insufficientData }

							values.append((value == 0) ? false : true)
							index += 1

						case "b":
							// Int8
							guard let value = data.subdata(fromIndex: index, length: 1)?.asInt8 else
									{ throw Error.insufficientData }

							values.append(value)
							index += 1

						case "B":
							// UInt8
							guard let value = data.subdata(fromIndex: index, length: 1)?.asUInt8 else
									{ throw Error.insufficientData }

							values.append(value)
							index += 1

						case "h":
							// Int16
							guard let subdata = data.subdata(fromIndex: index, length: 2) else
									{ throw Error.insufficientData }

							values.append((endianness == .big) ? subdata.asInt16BE! : subdata.asInt16LE!)
							index += 2

						case "H":
							// UInt16
							guard let subdata = data.subdata(fromIndex: index, length: 2) else
									{ throw Error.insufficientData }

							values.append((endianness == .big) ? subdata.asUInt16BE! : subdata.asUInt16LE!)
							index += 2

						case "i", "l":
							// Int32
							guard let subdata = data.subdata(fromIndex: index, length: 4) else
									{ throw Error.insufficientData }

							values.append((endianness == .big) ? subdata.asInt32BE! : subdata.asInt32LE!)
							index += 4

						case "I", "L":
							// UInt32
							guard let subdata = data.subdata(fromIndex: index, length: 4) else
									{ throw Error.insufficientData }

							values.append((endianness == .big) ? subdata.asUInt32BE! : subdata.asUInt32LE!)
							index += 4

						case "q":
							// Int64
							guard let subdata = data.subdata(fromIndex: index, length: 8) else
									{ throw Error.insufficientData }

							values.append((endianness == .big) ? subdata.asInt64BE! : subdata.asInt64LE!)
							index += 8

						case "Q":
							// UInt64
							guard let subdata = data.subdata(fromIndex: index, length: 8) else
									{ throw Error.insufficientData }

							values.append((endianness == .big) ? subdata.asUInt64BE! : subdata.asUInt64LE!)
							index += 8

						case "f":
							// float
// TODO
							index += 4

						case "d":
							// double
// TODO
							index += 8

						case "s":
							// C string
							let	endIndex = data[index...].firstIndex(where: { $0 == 0x00 }) ?? data.endIndex
							guard let string = String(data: data[index..<endIndex!], encoding: .utf8) else
									{ throw Error.invalidData(c) }

							values.append(string)
							index = endIndex! + 1

						case "p":
							// P string
// TODO
break

						case "P":
							// Pointer
// TODO
break

						default:
							// Error
							throw Error.invalidFormat(c)
					}
				}
			}

			// Reset for next values
			count = 0
		}

		return values
    }
}

//----------------------------------------------------------------------------------------------------------------------
//MARK: - PackedStruct.Error extension
extension PackedStruct.Error : CustomStringConvertible, LocalizedError {

	// MARK: Properties
	public 	var	description :String { self.localizedDescription }
	public	var	errorDescription :String? {
						switch self {
							case .insufficientData:				return "Insufficient data"
							case .invalidData(let character):	return "Invalid data for \(character)"
							case .invalidFormat(let character):	return "Invalid format (at \(character))"
						}
					}
}
