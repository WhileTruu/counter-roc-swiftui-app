platform "swiftui-platform"
    requires { Model, Msg } { program : _ }
    exposes []
    packages {}
    imports [Elem.{ Elem }]
    provides [programForHost]

programForHost : {
    init : (Str -> Model) as Init,
    update : (Model, Msg -> Model) as Update,
    view : (Model -> Elem Msg) as View,
}
programForHost = program
