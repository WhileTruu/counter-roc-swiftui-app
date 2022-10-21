app "calculator-swiftui-app"
    packages { pf: "platform/main.roc" }
    imports [pf.Elem.{ Elem }]
    provides [main] to pf

main : Str -> Elem
main = \a -> Elem.text "\(a)"
