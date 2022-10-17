app "calculator-swiftui-app"
    packages { pf: "platform/main.roc" }
    imports []
    provides [main] to pf

main = \a -> "Roc <3 \(a)!"
