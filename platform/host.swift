import Foundation
import SwiftUI

// MARK: Roc memory

@_cdecl("roc_alloc")
func rocAlloc(size: Int, _alignment: UInt) -> UInt {
    guard let ptr = malloc(size) else {
        return 0
    }
    return UInt(bitPattern: ptr)
}

@_cdecl("roc_dealloc")
func rocDealloc(ptr: UInt, _alignment: UInt) {
    free(UnsafeMutableRawPointer(bitPattern: ptr))
}

@_cdecl("roc_realloc")
func rocRealloc(ptr: UInt, _oldSize: Int, newSize: Int, _alignment: UInt) -> UInt {
    guard let ptr = realloc(UnsafeMutableRawPointer(bitPattern: ptr), newSize) else {
        return 0
    }
    return UInt(bitPattern: ptr)
}

// MARK: Roc Str

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

// Mark: Roc List

func rocListToSwiftArray<T, U>(rocList: RocList, _ elemFromPointer: (UnsafePointer<T>) -> U) -> Array<U> {
    let ptr = rocList.elements!
    let len = rocList.length
    let cap = rocList.capacity

    let buffer = ptr.withMemoryRebound(to: T.self, capacity: len) {
        UnsafeBufferPointer(start: $0, count: len)
    }

    return Array(buffer).map { elem in
        withUnsafePointer(to: elem) { elemPtr in
            return elemFromPointer(elemPtr)
        }
    }
}

// Mark: Roc Elem

func swiftRocElemFromPointer(ptr: UnsafePointer<RocElem>) -> SwiftRocElem {
    let tagId = getTagId(ptr: ptr)
    let entry: RocElemEntry = getRocEntry(ptr: ptr)

    // FIXME Can unsafety be reduced by moving things around?
    let elem: SwiftRocElem?

    switch tagId {
    case 0:
        elem = entryToSwiftRocHStackElem(entry: entry)
    case 1:
        elem = SwiftRocElem.swiftRocTextElem(SwiftRocTextElem(text: getSwiftStr(rocStr: entry.textElem.text)))
    case 2:
        elem = entryToSwiftRocVStackElem(entry: entry)
    default:
        elem = nil
    }

    return elem!
}

func entryToSwiftRocVStackElem(entry: RocElemEntry) -> SwiftRocElem {
    let elems = entry.stackElem.children
    let array: Array<SwiftRocElem> = rocListToSwiftArray(rocList: elems, swiftRocElemFromPointer)

    return SwiftRocElem.swiftRocVStackElem(array)
}

func entryToSwiftRocHStackElem(entry: RocElemEntry) -> SwiftRocElem {
    let elems = entry.stackElem.children
    let array: Array<SwiftRocElem> = rocListToSwiftArray(rocList: elems, swiftRocElemFromPointer)

    return SwiftRocElem.swiftRocHStackElem(array)
}

enum SwiftRocElem {
    case swiftRocTextElem(SwiftRocTextElem)
    case swiftRocVStackElem(Array<SwiftRocElem>)
    case swiftRocHStackElem(Array<SwiftRocElem>)
}

struct SwiftRocTextElem {
    var text: String
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

Furthermore, if I add an Elem among the tags of Elem tagged union, the
tag id is now in RocElem's pointer bits. The data structure with the pointer with
the three significant bits appeared to change when the tag union's tags contained
itself. It's also likely that I misunderstood this while hacking around with pointers.

Tags are brought in here alphabetically ordered, so in case of tags `A` and
`B`, `A` = 0 and `B` = 0, an empty tag would be NULL.
*/
func getTagId<T>(ptr: UnsafePointer<T>) -> UInt {
    let bytes = Data(bytes: ptr, count: MemoryLayout.size(ofValue: ptr))
    return UInt(bytes[0] & 0b111)
}

/**
Last three bits of the elem pointer need to be removed to get another elem pointer
that actually points to the entry.

Maybe a lot of pain could be avoided if the initial pointer weren't considered a
RocElem pointer.
Or perhaps the weirdness is due to the way Swift imports stuff from the header file.
*/
func getRocEntry(ptr: UnsafePointer<RocElem>) -> RocElemEntry {
    var bytes = Data(bytes: ptr, count: MemoryLayout.size(ofValue: ptr))
    bytes[0] = bytes[0] & ~0b111

    return bytes.withUnsafeBytes { (myPtr: UnsafePointer<RocElem>) in
        return myPtr.pointee.entry.pointee
    }
}

// MARK: View

struct ContentView: View {
    var swiftRocElem: SwiftRocElem

    init() {
        var argRocStr = getRocStr(swiftStr: "Swif")
        var closure = UnsafeMutableRawPointer.allocate(
            byteCount: MemoryLayout<UInt>.stride,
            alignment: MemoryLayout<UInt>.alignment
        )
        var retModel = UnsafeMutableRawPointer.allocate(
            byteCount: MemoryLayout<UInt>.stride,
            alignment: MemoryLayout<UInt>.alignment
        )

        var retRocElem = RocElem()

        roc__programForHost_1__Init_caller(&argRocStr, &closure, &retModel)

        roc__programForHost_1__Render_caller(&retModel, &closure, &retRocElem)


        swiftRocElem = withUnsafePointer(to: retRocElem) { ptr in
            return swiftRocElemFromPointer(ptr: ptr)
        }
    }

    var body: some View {
        swiftRocElemToView(elem: self.swiftRocElem)
    }
}

func swiftRocElemToView(elem: SwiftRocElem) -> some View {
    switch elem {
    case .swiftRocTextElem(let innerElem):
        return AnyView(Text(innerElem.text).padding())
    case .swiftRocVStackElem(let innerElems):
        return AnyView(swiftRocElemsToVStack(elems: innerElems))
    case .swiftRocHStackElem(let innerElems):
        return AnyView(swiftRocElemsToHStack(elems: innerElems))
    }
}

func swiftRocElemsToVStack(elems: Array<SwiftRocElem>) -> some View {
    VStack(alignment: .leading) {
        ForEach(elems.indices, id: \.self) { i in
            swiftRocElemToView(elem: elems[i])
        }
    }
}

func swiftRocElemsToHStack(elems: Array<SwiftRocElem>) -> some View {
    HStack(alignment: .top) {
        ForEach(elems.indices, id: \.self) { i in
            swiftRocElemToView(elem: elems[i])
        }
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

