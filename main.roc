app "counter-swiftui-app"
    packages { pf: "platform/main.roc" }
    imports [pf.Elem.{ Elem }]
    provides [program] to pf

Model : { text : Str, count : F32 }

init : Str -> Model
init = \a -> { text: a, count: 0 }

Msg : [
    Increment,
    Decrement,
]

update : Model, Msg -> Model
update = \model, msg ->
    when msg is
        Increment -> { model & count: model.count + 1 }
        Decrement -> { model & count: model.count - 1 }

view : Model -> Elem Msg
view = \model ->
    strVal = Num.toStr model.count

    Elem.vStack [
        Elem.text model.text,
        Elem.button { label: "+1", onClick: Increment },
        Elem.hStack [
            Elem.text "count: \(strVal)",
        ],
        Elem.button { label: "-1", onClick: Decrement },
    ]

program = { init, update, view }
