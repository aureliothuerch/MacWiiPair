// Dumps Objective-C classes/methods from system frameworks via the public
// runtime API. Usage: swift tools/dump-classes.swift <substring> [<substring>...]
import Foundation
import ObjectiveC

for fw in ["IOBluetooth", "CoreBluetooth"] {
    dlopen("/System/Library/Frameworks/\(fw).framework/\(fw)", RTLD_NOW)
}

let patterns = CommandLine.arguments.dropFirst().map { $0.lowercased() }

func methods(of cls: AnyClass, prefix: String) {
    var n: UInt32 = 0
    guard let ms = class_copyMethodList(cls, &n) else { return }
    defer { free(ms) }
    for i in 0..<Int(n) {
        let m = ms[i]
        let sel = NSStringFromSelector(method_getName(m))
        let enc = method_getTypeEncoding(m).map { String(cString: $0) } ?? "?"
        print("  \(prefix)\(sel)  \(enc)")
    }
}

// Enumerate class *names* per image (never touching unrelated class objects).
var seen = Set<String>()
for probe in ["IOBluetoothDevice", "CBPeripheral"] {
    guard let c = NSClassFromString(probe), let img = class_getImageName(c) else { continue }
    var n: UInt32 = 0
    guard let names = objc_copyClassNamesForImage(img, &n) else { continue }
    defer { free(names) }
    for i in 0..<Int(n) {
        let name = String(cString: names[i])
        if patterns.contains(where: { name.lowercased().contains($0) }) { seen.insert(name) }
    }
}
for name in seen.sorted() {
    guard let cls = NSClassFromString(name) else { continue }
    let sup = class_getSuperclass(cls).map { String(cString: class_getName($0)) } ?? "-"
    print("@interface \(name) : \(sup)")
    if let meta = object_getClass(cls) { methods(of: meta, prefix: "+") }
    methods(of: cls, prefix: "-")
}
