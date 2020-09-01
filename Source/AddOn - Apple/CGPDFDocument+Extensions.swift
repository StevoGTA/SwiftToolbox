//
//  CGPDFDocument+Extensions.swift
//  Virtual Sheet Music
//
//  Created by Stevo on 8/31/20.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: CGPDFDictionaryRef extension
extension CGPDFDictionaryRef {

	// MARK: Properties
	var	info :[String : Any] {
				// Compose info
				var	info = [String : Any]()
				CGPDFDictionaryApplyBlock(self, { key, value, _ in
					// Decode key
					let	key = String(cString: UnsafePointer<CChar>(key), encoding: .isoLatin1)!
					guard (key != "Parent") && (key != "P") else { return true }

					// Store
					info[key] = value.value

					return true
				}, nil)

				return info
			}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: CGPDFArray extension
fileprivate extension CGPDFArrayRef {

	// MARK: Properties
	var	values :[Any] {
				// Transmogrify values
				var	values = [Any]()
				CGPDFArrayApplyBlock(self, { _, value, _ in
					// Add to array
					values.append(value.value!)

					return true
				}, nil)

				return values
			}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - CGPDFObjectRef extension
fileprivate extension CGPDFObjectRef {

	// MARK: Notes
	// See https://stackoverflow.com/questions/43454670/swift-cgpdfdocument-parsing

	// MARK: Properties
	var	value :Any? {
				// Check type
				switch CGPDFObjectGetType(self) {
					case .null:
						// Null
						return nil

					case .boolean:
						// Boolean
						var	value :CGPDFBoolean = 0
						CGPDFObjectGetValue(self, .boolean, &value)

						return value == 1

					case .integer:
						// Integer
						var	value :CGPDFInteger = 0
						CGPDFObjectGetValue(self, .integer, &value)

						return value

					case .real:
						// Real
						var	value :CGPDFReal = 0.0
						CGPDFObjectGetValue(self, .integer, &value)

						return value

					case .name:
						// Name
						var	value :UnsafePointer<Int8>? = nil
						CGPDFObjectGetValue(self, .name, &value)

						return String(cString: UnsafePointer<CChar>(value!), encoding: .isoLatin1)

					case .string:
						// String
						var	value :UnsafePointer<Int8>? = nil
						CGPDFObjectGetValue(self, .string, &value)

						return CGPDFStringCopyTextString(OpaquePointer(value!))

					case .array:
						// Array
						var	value :CGPDFArrayRef? = nil
						CGPDFObjectGetValue(self, .array, &value)

						return value?.values

					case .dictionary:
						// Dictionary
						var	value :CGPDFDictionaryRef? = nil
						CGPDFObjectGetValue(self, .dictionary, &value)

						return value!.info

					case .stream:
						// Stream
						return "Stream - not retrieved"

					default:
						// Other
						fatalError("CGPDFObject unhandled object type: other")
				}
			}
}
