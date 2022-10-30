app "calculator-swiftui-app"
    packages { pf: "platform/main.roc" }
    imports [pf.Elem.{ Elem }]
    provides [program] to pf

# MODEL

Model : { text : Str, val : I64 }

init : Str -> Model
init = \a -> { text : a |> Str.concat " - hello I am init", val : 0 }

# UPDATE

Msg : [
    Increment,
    Decrement,
]

update : Model -> Model
update = \model ->
     { model & text : "+1 \(model.text)" }

# RENDER

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

# PROGRAM

program = { init, update, render }