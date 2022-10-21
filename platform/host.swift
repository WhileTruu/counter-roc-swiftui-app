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

func getTag(rocElem: inout RocElem) -> Int {
    let count = MemoryLayout.size(ofValue: rocElem.entry)

    print("myasd \(rocElem)")
    let bytes = withUnsafePointer(to: rocElem) { ptr in
        // Is it possible unused tags are being dropped & compile time, and
        // therefor it's always just one here?
        // idk, check breakout again maybe
        // ANyway, the tag id is supposed to be in the final 3 bits of the pointer.
        // ALways looks like a 0 to me though..

        print("ptr \(ptr)")
        let bytes = Data(bytes: ptr, count: MemoryLayout.size(ofValue: ptr))
        print(bytes[7] & 0b111)

        print(unsafeBitCast(ptr, to: Int64.self) & 0b0000_0111)
        print(unsafeBitCast(ptr, to: Int.self) & 0b0000_0111)
        print(unsafeBitCast(ptr, to: UInt.self) & 0b0000_0111)
        print(unsafeBitCast(ptr, to: UInt64.self) & 0b0000_0111)
        // print(unsafeBitCast(ptr, to: Array<UInt8>.self) & 0b0000_0111)
        return ptr.pointee
    }

    // let x = rocElem.entry.withMemoryRebound(to: UInt.self, capacity: 8) {
    //     print("xx \($0)")
    //     return strlen($0)
    // }
    // print("x \(x)")

    // withUnsafePointer(to: rocElem) { pointerBuffer in
    //     for byte in pointerBuffer {
    //         print(byte)
    //     }
    // }


    // print(bytes)
    return 1 // Int(bytes & 0b0000_0111)
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

struct ContentView: View {
    var str: String

    init() {
        var argRocStr = getRocStr(swiftStr: "Swift")
        var retRocElem = RocElem()
        roc__mainForHost_1_exposed_generic(&retRocElem, &argRocStr)
        print("\nelem1 \(retRocElem)")
        yolo(label: "retRocElem 1", rocElem: &retRocElem)

        var argRocStr2 = getRocStr(swiftStr: "Swiftyyyyyyyyyyyyyyyyyyyyyyyyyyy")
        var retRocElem2 = RocElem()
        roc__mainForHost_1_exposed_generic(&retRocElem2, &argRocStr2)
        print("\nelem2 \(retRocElem2)")
        yolo(label: "retRocElem 2", rocElem: &retRocElem2)

        var argRocStr3 = getRocStr(swiftStr: "Swi")
        var retRocElem3 = RocElem()
        roc__mainForHost_1_exposed_generic(&retRocElem3, &argRocStr3)
        print("\nelem3 \(retRocElem3)")
        yolo(label: "retRocElem 3", rocElem: &retRocElem3)

        print("output \(retRocElem)")
        // print("output \(getTag(rocElem: &retRocElem))")

        // print("elem! \(getSwiftStr(rocStr: retRocElem.entry.potatoTextElem.schMext))")
        self.str = "x"//getSwiftStr(rocStr: retRocElem.entry.textElem.text)
    }

    var body: some View {
        Text(self.str)
            .padding()
    }
}

func yolo(label: String, rocElem: inout RocElem) {

    withUnsafeMutablePointer(to: &rocElem.tag) { ptr in
        let bytes = Data(bytes: ptr, count: MemoryLayout.size(ofValue: ptr))

        print("tag \(UInt(bitPattern: ptr)) \(bits(fromByte: bytes[0])) \(bytes[0])")

    }

    withUnsafeMutablePointer(to: &rocElem) { ptr in
        let bytes = Data(bytes: ptr, count: MemoryLayout.size(ofValue: ptr))
        print(bits(fromByte: bytes[0]))
        print("\(label) ptr         \(UInt(bitPattern: ptr) & 0b111)")
    }
     withUnsafeMutablePointer(to: &rocElem) { ptr in
         print("\(label) ptr 2       \(ptr)")
    }
    withUnsafeMutablePointer(to: &rocElem.entry) { ptr in
        let bytes = Data(bytes: ptr, count: MemoryLayout.size(ofValue: ptr))
        print(bytes[MemoryLayout.size(ofValue: ptr) - 1])
        print("\(label) entry ptr   \(ptr)")
    }
    withUnsafeMutablePointer(to: &rocElem.entry) { ptr in
        print("\(label) entry ptr 2 \(ptr)")
    }
}

@main
struct RocTestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

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