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

// MARK: State/ store type of a thing

class AppState: ObservableObject {
    @Published private(set) var model: Model

    init() {
        self.model = initRocProgram()
    }

    func update(_ msgPtr: UnsafeRawPointer?) {
        self.model = withUnsafePointer(to: msgPtr) {
            return updateRocProgram(self.model, $0)
        }
    }

    func render(_ model: Model) -> some View {
        var retRocElem = RocElem()
        var closure = UnsafeMutableRawPointer.allocate(
                byteCount: Int(roc__programForHost_1__View_size()),
                alignment: Int(roc__programForHost_1__View_size())
        )

        roc__programForHost_1__View_caller(model, &closure, &retRocElem)

        closure.deallocate()

        return withUnsafePointer(to: retRocElem) { ptr in
            return renderRocElemFromPointer(ptr: ptr, action: self.update)
        }
    }
}

func initRocProgram() -> Model {
    var argRocStr = getRocStr(swiftStr: "Hello from Swift! :)")
    var closure = UnsafeMutableRawPointer.allocate(
            byteCount: Int(roc__programForHost_1__Init_size()),
            alignment: Int(roc__programForHost_1__Init_size())
    )
    var model = Model.allocate(
            byteCount: Int(roc__programForHost_1__Init_result_size()),
            alignment: Int(roc__programForHost_1__Init_result_size())
    )

    roc__programForHost_1__Init_caller(&argRocStr, closure, model)

    closure.deallocate()

    return model
}

func updateRocProgram(_ model: Model, _ msg: UnsafeRawPointer) -> Model {
    var closure = UnsafeMutableRawPointer.allocate(
            byteCount: Int(roc__programForHost_1__Update_size()),
            alignment: Int(roc__programForHost_1__Update_size())
    )
    var returnModel = Model.allocate(
            byteCount: Int(roc__programForHost_1__Update_result_size()),
            alignment: Int(roc__programForHost_1__Update_result_size())
    )

    roc__programForHost_1__Update_caller(model, msg, closure, returnModel)

    closure.deallocate()

    return returnModel
}

func renderRocElemFromPointer(ptr: UnsafePointer<RocElem>, action: @escaping (UnsafeRawPointer?) -> Void) -> some View {
    let tagId = getTagId(ptr: ptr)
    let entry: RocElemEntry = getRocEntry(ptr: ptr)

    switch tagId {
    case 0:
        let label = getSwiftStr(rocStr: entry.buttonElem.label)
        let onClick = entry.buttonElem.onClick

        return AnyView(Button(label, action: { action(onClick) }).padding())
    case 1:
        return AnyView(renderRocElemEntryAsHStack(entry: entry, action: action))
    case 2:
        let text = getSwiftStr(rocStr: entry.textElem.text)

        return AnyView(Text(text).padding())
    case 3:
        return AnyView(renderRocElemEntryAsVStack(entry: entry, action: action))
    default:
        return AnyView(Text("Unknown tag id: \(tagId)!").padding())
    }
}

func renderRocElemEntryAsVStack(entry: RocElemEntry, action: @escaping (UnsafeRawPointer?) -> Void) -> some View {
    VStack(alignment: .leading) {
        let elems = entry.stackElem.children
        let array = rocListToSwiftArray(rocList: elems, { ptr in
            renderRocElemFromPointer(ptr: ptr, action: action)
        })

        ForEach(array.indices, id: \.self) { i in
            array[i]
        }
    }
}

func renderRocElemEntryAsHStack(entry: RocElemEntry, action: @escaping (UnsafeRawPointer?) -> Void) -> some View {
    HStack(alignment: .top) {
        let elems = entry.stackElem.children
        let array = rocListToSwiftArray(rocList: elems, { ptr in
            renderRocElemFromPointer(ptr: ptr, action: action)
        })

        ForEach(array.indices, id: \.self) { i in
            array[i]
        }
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

// MARK: Content view

struct ContentView: View {
    @ObservedObject var appState = AppState()

    var body: some View {
        appState.render(self.appState.model)
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

