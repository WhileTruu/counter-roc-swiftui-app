app "calculator-swiftui-app"
    packages { pf: "platform/main.roc" }
    imports [pf.Elem.{ Elem }]
    provides [program] to pf

Model : { text : Str }

init : Str -> Model
init = \a -> { text : a |> Str.concat " - hello I am init" }

render : Model -> Elem
render = \model ->
    Elem.vStack [
        Elem.hStack [
            Elem.text "\(model.text)",
            Elem.text "\(model.text)",
            Elem.text "YEA BOIII",
        ],
        Elem.hStack [
            Elem.text "\(model.text)",
            Elem.text "\(model.text)",
            Elem.text "YEA BOIII",
        ],
    ]

program = { init, render }