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
    case swiftRocVStackElem(Array<SwiftRocElem>)
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
    let entry = rocElem.entry.pointee

    switch tagId {
    case 0:
        return SwiftRocElem.swiftRocPotatoTextElem(SwiftRocPotatoTextElem(schMext: getSwiftStr(rocStr: entry.potatoTextElem.schMext), poop: entry.potatoTextElem.poop))
    case 1:
        return SwiftRocElem.swiftRocTextElem(SwiftRocTextElem(text: getSwiftStr(rocStr: entry.textElem.text)))
    case 2:
        return entryToSwiftRocVStackElem(entry: entry)
    case 3:
        return SwiftRocElem.swiftRocXTextElem(SwiftRocXTextElem(ext: getSwiftStr(rocStr: entry.xTextElem.ext)))
    case 4:
        return SwiftRocElem.swiftRocXXTextElem(SwiftRocXXTextElem(sext: getSwiftStr(rocStr: entry.xxTextElem.sext)))
    default:
        return SwiftRocElem.swiftRocTextElem(SwiftRocTextElem(text: "FIXME: It bork, idk how to handle nulls"))
    }
}

func entryToSwiftRocVStackElem(entry: RocElemEntry) -> SwiftRocElem {
    let ptr = entry.vStackElem.children.elements!
    let len = entry.vStackElem.children.length
    let cap = entry.vStackElem.children.capacity

    let buffer = UnsafeBufferPointer(start: ptr, count: len);
    let arrayOfPtrs = Array(buffer)

    let myRocElem = arrayOfPtrs[0]!.assumingMemoryBound(to: RocElem.self).pointee

    let myArr = arrayOfPtrs.map { arrayPtr in
        withUnsafePointer(to:arrayPtr) { ptr2 in
            var bytes = Data(bytes: ptr2, count: MemoryLayout.size(ofValue: ptr2))
            let tagId = UInt(bytes[0] & 0b111)

            bytes[0] = bytes[0] & ~0b111
            let rocElem = bytes.withUnsafeBytes { (myPtr: UnsafePointer<RocElem>) in
                return myPtr.pointee
            }

            return rocElemToSwiftRocElem(tagId: tagId, rocElem: rocElem)
        }
    }

    return SwiftRocElem.swiftRocVStackElem(myArr)
}

func getTagId(rocElemPtr: UnsafePointer<RocElem>) -> UInt {
   var bytes = Data(bytes: rocElemPtr, count: MemoryLayout.size(ofValue: rocElemPtr))
   return UInt(bytes[0] & 0b111)
}

func getRocElem(rocElemPtr: UnsafePointer<RocElem>) -> RocElem {
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
        var argRocStr = getRocStr(swiftStr: "Swif")
        var retRocElem = RocElem()
        roc__mainForHost_1_exposed_generic(&retRocElem, &argRocStr)

        let swiftRocElem = withUnsafePointer(to: retRocElem) { ptr in
            let tagId = getTagId(rocElemPtr: ptr)
            let elem = getRocElem(rocElemPtr: ptr)
            print(tagId)
            print(elem)
            return rocElemToSwiftRocElem(tagId: tagId, rocElem: elem)
        }
        print(swiftRocElem)


        var argRocStr2 = getRocStr(swiftStr: "Swiftyyyyyyyyyyyyyyyyyyyyyyyyyyy")
        var retRocElem2 = RocElem()
        roc__mainForHost_1_exposed_generic(&retRocElem2, &argRocStr2)

        withUnsafePointer(to: retRocElem2) { ptr in
            let tagId = getTagId(rocElemPtr: ptr)
            let elem = getRocElem(rocElemPtr: ptr)
            print(tagId)
            print(elem)
            print(rocElemToSwiftRocElem(tagId: tagId, rocElem: elem))
        }


        var argRocStr3 = getRocStr(swiftStr: "Swi")
        var retRocElem3 = RocElem()
        roc__mainForHost_1_exposed_generic(&retRocElem3, &argRocStr3)

        withUnsafePointer(to: retRocElem3) { ptr in
            let tagId = getTagId(rocElemPtr: ptr)
            let elem = getRocElem(rocElemPtr: ptr)
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

