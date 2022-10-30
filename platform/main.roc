platform "swiftui-platform"
    requires { Model, Msg } { program : _ }
    exposes []
    packages {}
    imports [Elem.{ Elem }]
    provides [programForHost]

programForHost : {
    init : (Str -> Model) as Init,
    update : (Model -> Model) as Update,
    render : (Model -> Elem Msg) as Render,
}
programForHost = program


