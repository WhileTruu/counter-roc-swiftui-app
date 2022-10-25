import Foundation
import SwiftUI

// MARK: Roc memory

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

func rocListToSwiftArray<T>(rocList: RocList, _ elemFromPointer: (UnsafeRawPointer) -> T) -> Array<T> {
    let ptr = rocList.elements!
    let len = rocList.length
    let cap = rocList.capacity

    let buffer = UnsafeBufferPointer(start: ptr, count: len);
    let arrayOfPtrs = Array(buffer)

    let myArr = arrayOfPtrs.map { arrayPtr in
        withUnsafePointer(to:arrayPtr) { ptr2 in
            return elemFromPointer(ptr2)
        }
    }

    return myArr
}

// Mark: Roc Elem

func swiftRocElemFromPointer(ptr: UnsafeRawPointer) -> SwiftRocElem {
    var bytes = Data(bytes: ptr, count: MemoryLayout.size(ofValue: ptr))
    let tagId = UInt(bytes[0] & 0b111)

    bytes[0] = bytes[0] & ~0b111
    let rocElem = bytes.withUnsafeBytes { (elemPtr: UnsafePointer<RocElem>) in
        return elemPtr.pointee
    }

    let entry = rocElem.entry.pointee

    // FIXME Can unsafety be reduced by moving things around?
    let elem: SwiftRocElem?

    switch tagId {
    case 0:
        elem = entryToSwiftRocVStackElem2(rocList: entry.stackElem.children)
    case 1:
        elem = SwiftRocElem.swiftRocTextElem(SwiftRocTextElem(text: getSwiftStr(rocStr: entry.textElem.text)))
    case 2:
        elem = entryToSwiftRocVStackElem2(rocList: entry.stackElem.children)
    default:
        elem = nil
    }

    return elem!
}

func entryToSwiftRocVStackElem2(rocList: RocList) -> SwiftRocElem {
    let array = rocListToSwiftArray(rocList: rocList, swiftRocElemFromPointer)

    return SwiftRocElem.swiftRocVStackElem(array)
}

enum SwiftRocElem {
    case swiftRocTextElem(SwiftRocTextElem)
    case swiftRocVStackElem(Array<SwiftRocElem>)
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

Furthermore, if I add an Elem among the tags of Elem tagged union, apparently the
tag id is now in RocElem's pointer bits.

To get rocElems now, I think I need to remove the last three bits from the pointer somehow.

--

Comment restored for reference - the stuff is working now, I think.

Also, tags are brought in here alphabetically ordered, so in case of tags `A` and
`B`, `A` = 0 and `B` = 0, an empty tag would be NULL.
*/
func getTagId<T>(ptr: UnsafePointer<T>) -> UInt {
   var bytes = Data(bytes: ptr, count: MemoryLayout.size(ofValue: ptr))
   return UInt(bytes[0] & 0b111)
}

func getRocEntry<T, U>(ptr: UnsafePointer<T>) -> U {
    var bytes = Data(bytes: ptr, count: MemoryLayout.size(ofValue: ptr))
    bytes[0] = bytes[0] & ~0b111

    return bytes.withUnsafeBytes { (myPtr: UnsafePointer<U>) in
        return myPtr.pointee
    }
}

// MARK: View

struct ContentView: View {
    var str: String
    var swiftRocElem: SwiftRocElem

    init() {
        var argRocStr = getRocStr(swiftStr: "Swif")
        var retRocElem = RocElem()
        roc__mainForHost_1_exposed_generic(&retRocElem, &argRocStr)

        swiftRocElem = withUnsafePointer(to: retRocElem) { ptr in
            let tagId = getTagId(ptr: ptr)
            let elem: RocElemEntry = getRocEntry(ptr: ptr)
            print(tagId)
            print(elem)
            return swiftRocElemFromPointer(ptr: ptr)
        }
        print(swiftRocElem)


        var argRocStr2 = getRocStr(swiftStr: "Swiftyyyyyyyyyyyyyyyyyyyyyyyyyyy")
        var retRocElem2 = RocElem()
        roc__mainForHost_1_exposed_generic(&retRocElem2, &argRocStr2)

        withUnsafePointer(to: retRocElem2) { ptr in
            let tagId = getTagId(ptr: ptr)
            let elem: RocElemEntry = getRocEntry(ptr: ptr)
            print(tagId)
            print(elem)
            print(swiftRocElemFromPointer(ptr: ptr))
        }


        var argRocStr3 = getRocStr(swiftStr: "Swi")
        var retRocElem3 = RocElem()
        roc__mainForHost_1_exposed_generic(&retRocElem3, &argRocStr3)

        withUnsafePointer(to: retRocElem3) { ptr in
            let tagId = getTagId(ptr: ptr)
            let elem: RocElemEntry = getRocEntry(ptr: ptr)
            print(tagId)
            print(elem)
            print(swiftRocElemFromPointer(ptr: ptr))
        }

        self.str = "x"
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(self.str)
                .padding()
            swiftRocElemToView(elem: self.swiftRocElem)
        }
    }
}
func swiftRocElemToView(elem: SwiftRocElem) -> some View {
    switch elem {
    case .swiftRocTextElem(let innerElem):
        return AnyView(Text(innerElem.text).padding())
    case .swiftRocVStackElem(let innerElems):
        return AnyView(swiftRocElemToView2(elems: innerElems))
    }
}

func swiftRocElemToView2(elems: Array<SwiftRocElem>) -> some View {
    VStack(alignment: .leading) {
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

