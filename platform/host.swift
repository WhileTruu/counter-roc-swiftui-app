import Foundation
import SwiftUI

@_cdecl("roc_alloc")
func rocAlloc(size: Int, _alignment: UInt) -> UInt  {
    guard let ptr = malloc(size) else {
        return 0
    }
    return UInt(bitPattern: ptr)
}

@_cdecl("roc_dealloc")
func rocDealloc(ptr: UInt, _alignment: UInt)  {
    free(UnsafeMutableRawPointer(bitPattern: ptr))
}

@_cdecl("roc_realloc")
func rocRealloc(ptr: UInt, _oldSize: Int, newSize: Int, _alignment: UInt) -> UInt {
    guard let ptr = realloc(UnsafeMutableRawPointer(bitPattern: ptr), newSize) else {
        return 0
    }
    return UInt(bitPattern: ptr)
}

func isSmallString(rocStr: RocStr) -> Bool {
    return rocStr.capacity < 0
}

func getStrLen(rocStr: RocStr) -> Int {
    if isSmallString(rocStr: rocStr) {
        // Small String length is last in the byte of capacity.
        var cap = rocStr.capacity
        let count = MemoryLayout.size(ofValue: cap)
        let bytes = Data(bytes: &cap, count: count)
        let lastByte = bytes[count - 1]
        return Int(lastByte ^ 0b1000_0000)
    } else {
        return rocStr.len
    }
}

func getSwiftStr(rocStr: RocStr) -> String {
    let length = getStrLen(rocStr: rocStr)

    if isSmallString(rocStr: rocStr) {
        let data: Data = withUnsafePointer(to: rocStr) { ptr in
            Data(bytes: ptr, count: length)
        }
        return String(data: data, encoding: .utf8)!
    } else {
        let data = Data(bytes: rocStr.bytes, count: length)
        return String(data: data, encoding: .utf8)!
    }
}

func getRocStr(swiftStr: String) -> RocStr {
    let newString = strdup(swiftStr)

    return RocStr(
        bytes: newString,
        len: swiftStr.lengthOfBytes(using: String.Encoding.utf8),
        capacity: swiftStr.lengthOfBytes(using: String.Encoding.utf8)
    )
}

enum SwiftRocElem {
    case swiftRocPotatoTextElem(SwiftRocPotatoTextElem)
    case swiftRocTextElem(SwiftRocTextElem)
    case swiftRocXTextElem(SwiftRocXTextElem)
    case swiftRocXXTextElem(SwiftRocXXTextElem)
}

struct SwiftRocTextElem {
    var text: String
}

struct SwiftRocXTextElem {
    var ext: String
}

struct SwiftRocXXTextElem {
    var sext: String
}

struct SwiftRocPotatoTextElem {
    var schMext: String
    var poop: Float32
}

func rocElemToSwiftRocElem(tagId: UInt, rocElem: RocElem) -> SwiftRocElem {

    var swiftRocElem: SwiftRocElem = {
        switch tagId {
        case 0:
            return SwiftRocElem.swiftRocPotatoTextElem(SwiftRocPotatoTextElem(schMext: getSwiftStr(rocStr: rocElem.entry.pointee.potatoTextElem.schMext), poop: rocElem.entry.pointee.potatoTextElem.poop))
        case 1:
            return SwiftRocElem.swiftRocTextElem(SwiftRocTextElem(text: getSwiftStr(rocStr: rocElem.entry.pointee.textElem.text)))
        case 2:

            let ptr = rocElem.entry.pointee.vStackElem.children.elements!
            let len = rocElem.entry.pointee.vStackElem.children.length
            let cap = rocElem.entry.pointee.vStackElem.children.capacity
            // let buffer = UnsafeBufferPointer(start: ptr, count: len);
            let buffer = ptr.withMemoryRebound(to: Float32.self, capacity: MemoryLayout<Float32>.stride) {
                UnsafeBufferPointer(start: $0, count: len)
            }
            print(Array(buffer))
            return SwiftRocElem.swiftRocTextElem(SwiftRocTextElem(text: "this be a vstack"))
        case 3:
            return SwiftRocElem.swiftRocXTextElem(SwiftRocXTextElem(ext: getSwiftStr(rocStr: rocElem.entry.pointee.xTextElem.ext)))
        case 4:
            return SwiftRocElem.swiftRocXXTextElem(SwiftRocXXTextElem(sext: getSwiftStr(rocStr: rocElem.entry.pointee.xxTextElem.sext)))
        default:
            return SwiftRocElem.swiftRocTextElem(SwiftRocTextElem(text: "FIXME: It bork, idk how to handle nulls"))
        }
    }()

    return swiftRocElem
}

/**
Apparently the host byte order is little-endian on iOS and MacOS.
This means that the least significant byte comes first.
I suppose this also explains why the bit representation is reversed?

According to some random info on some Roc example platforms the last three
bits of the tag pointer define the tag, so, I actually need to read the
first byte's last three bits in reverse order, except, 0b111 still
masks the first three bits and when converted to an int, the number is
what would be expected from non-reversed bits.

Furthermore, if I add an Elem among the tags of Elem tagged union, apparently the
tag id is now in RocElem's pointer bits.

To get rocElems now, I think I need to remove the last three bits from the pointer somehow.
*/
// func getTagId(rocElem: RocElem) -> UInt {
//     withUnsafePointer(to: rocElem) { ptr in
//         var bytes = Data(bytes: ptr, count: MemoryLayout.size(ofValue: ptr))
//         let tagId = UInt(bytes[0] & 0b111)
//         // print("tagZ \(bits(fromByte: bytes[0])) \(bits(fromByte: bytes[1])) \(bits(fromByte: bytes[2])) \(bits(fromByte: bytes[3])) \(bits(fromByte: bytes[4])) \(bits(fromByte: bytes[5])) \(bits(fromByte: bytes[6])) \(bits(fromByte: bytes[7]))")
//
//         bytes[0] = bytes[0] & ~0b111
//
//         bytes.withUnsafeBytes {(myPtr: UnsafePointer<RocElem>) in
//             let rawPtr = UnsafeRawPointer(myPtr)
//             let realRocElem = rawPtr.load(as: RocElem.self)
//
//             var bytes2 = Data(bytes: rawPtr, count: MemoryLayout.size(ofValue: rawPtr))
//
//             print("tagX \(bits(fromByte: bytes2[0])) \(bits(fromByte: bytes2[1])) \(bits(fromByte: bytes2[2])) \(bits(fromByte: bytes2[3])) \(bits(fromByte: bytes2[4])) \(bits(fromByte: bytes2[5])) \(bits(fromByte: bytes2[6])) \(bits(fromByte: bytes2[7]))")
//
//             print("realRocElem \(realRocElem.entry.pointee.potatoTextElem)")
//             print("myPtr       \(rocElemToSwiftRocElem(tagId: tagId, rocElem: myPtr.pointee))")
//             print("rocElem     \(rocElem.entry.pointee.potatoTextElem)")
//         }
//
//         return tagId
//     }
// }

func getTagId2(rocElemPtr: UnsafePointer<RocElem>) -> UInt {
   var bytes = Data(bytes: rocElemPtr, count: MemoryLayout.size(ofValue: rocElemPtr))
   return UInt(bytes[0] & 0b111)
}

func getRocElem2(rocElemPtr: UnsafePointer<RocElem>) -> RocElem {
    var bytes = Data(bytes: rocElemPtr, count: MemoryLayout.size(ofValue: rocElemPtr))
    bytes[0] = bytes[0] & ~0b111

    return bytes.withUnsafeBytes { (myPtr: UnsafePointer<RocElem>) in
        return myPtr.pointee
    }
}

// MARK: View

struct ContentView: View {
    var str: String

    init() {
        var argRocStr = getRocStr(swiftStr: "Swift")
        var retRocElem = RocElem()
        roc__mainForHost_1_exposed_generic(&retRocElem, &argRocStr)

        withUnsafePointer(to: retRocElem) { ptr in
            let tagId = getTagId2(rocElemPtr: ptr)
            let elem = getRocElem2(rocElemPtr: ptr)
            print(tagId)
            print(elem)
            print(rocElemToSwiftRocElem(tagId: tagId, rocElem: elem))
        }


        var argRocStr2 = getRocStr(swiftStr: "Swiftyyyyyyyyyyyyyyyyyyyyyyyyyyy")
        var retRocElem2 = RocElem()
        roc__mainForHost_1_exposed_generic(&retRocElem2, &argRocStr2)

        withUnsafePointer(to: retRocElem2) { ptr in
            let tagId = getTagId2(rocElemPtr: ptr)
            let elem = getRocElem2(rocElemPtr: ptr)
            print(tagId)
            print(elem)
            print(rocElemToSwiftRocElem(tagId: tagId, rocElem: elem))
        }


        var argRocStr3 = getRocStr(swiftStr: "Swi")
        var retRocElem3 = RocElem()
        roc__mainForHost_1_exposed_generic(&retRocElem3, &argRocStr3)

        withUnsafePointer(to: retRocElem3) { ptr in
            let tagId = getTagId2(rocElemPtr: ptr)
            let elem = getRocElem2(rocElemPtr: ptr)
            print(tagId)
            print(elem)
            print(rocElemToSwiftRocElem(tagId: tagId, rocElem: elem))
        }

        self.str = "x"
    }

    var body: some View {
        Text(self.str)
            .padding()
    }
}

// MARK: Main

@main
struct RocTestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: Helpers

func bits(fromByte byte: UInt8) -> [Bit] {
    var byte = byte
    var bits = [Bit](repeating: .zero, count: 8)
    for i in 0..<8 {
        let currentBit = byte & 0x01
        if currentBit != 0 {
            bits[i] = .one
        }

        byte >>= 1
    }

    return bits
}

enum Bit: UInt8, CustomStringConvertible {
    case zero, one

    var description: String {
        switch self {
        case .one:
            return "1"
        case .zero:
            return "0"
        }
    }
}