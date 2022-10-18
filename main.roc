app "calculator-swiftui-app"
    packages { pf: "platform/main.roc" }
    imports [pf.Elem.{ TextElem }]
    provides [main] to pf

main : Str -> TextElem
main = \a -> Elem.text "Roc <3 \(a)!"
