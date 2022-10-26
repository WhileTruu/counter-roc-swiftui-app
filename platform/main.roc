platform "swiftui-platform"
    requires { Model } { program : _ }
    exposes []
    packages {}
    imports [Elem.{ Elem }]
    provides [programForHost]

programForHost : {
    init : (Str -> Model) as Init,
    render : (Model -> Elem) as Render,
}
programForHost = program


