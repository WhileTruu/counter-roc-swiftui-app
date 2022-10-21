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
        print(getTagId(rocElem: retRocElem))

        var argRocStr2 = getRocStr(swiftStr: "Swiftyyyyyyyyyyyyyyyyyyyyyyyyyyy")
        var retRocElem2 = RocElem()
        roc__mainForHost_1_exposed_generic(&retRocElem2, &argRocStr2)
        print("\nelem2 \(retRocElem2)")
        print(getTagId(rocElem: retRocElem2))

        var argRocStr3 = getRocStr(swiftStr: "Swi")
        var retRocElem3 = RocElem()
        roc__mainForHost_1_exposed_generic(&retRocElem3, &argRocStr3)
        print("\nelem3 \(retRocElem3)")
        print(getTagId(rocElem: retRocElem3))

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

/**
Apparently the host byte order is little-endian on iOS and MacOS.
This means that the least significant byte comes first.
I suppose this also explains why the bit representation is reversed?

According to some random info on some Roc example platforms the last three
bits of the tag pointer define the tag, so, I actually need to read the
first byte's last three bits in reverse order, except, 0b111 still
masks the first three bits and when converted to an int, the number is
what would be expected from non-reversed bits.
*/
func getTagId(rocElem: RocElem) -> UInt {
    withUnsafePointer(to: rocElem.tag) { ptr in
        let bytes = Data(bytes: ptr, count: MemoryLayout.size(ofValue: ptr))

        return UInt(bytes[0] & 0b111)
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