app "calculator-swiftui-app"
    packages { pf: "platform/main.roc" }
    imports [pf.Elem.{ Elem }]
    provides [program] to pf

Model : { text : Str, val : I64 }

init : Str -> Model
init = \a -> { text : a |> Str.concat " - hello I am init", val : 0 }

Msg : [
    Increment,
    Decrement,
]

render : Model -> Elem Msg
render = \model ->
    strVal = Num.toStr model.val
    Elem.vStack [
        Elem.button { label : "+1", onClick : Increment },
        Elem.hStack [
            Elem.text "value: ",
            Elem.text "\(model.text) \(strVal)",
            Elem.text "YEA BOIII",
        ],
        Elem.button { label : "-1", onClick : Decrement },
    ]

update : Model, Msg -> Model
update = \model, msg ->
    when msg is
        Increment -> { model & text : "+1 \(model.text)" }
        Decrement -> { model & text : "-1 \(model.text)" }

program = { init, update, render }