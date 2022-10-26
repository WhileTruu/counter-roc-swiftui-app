platform "swiftui-platform"
    requires {} { program : Str -> Elem }
    exposes []
    packages {}
    imports [Elem.{ Elem }]
    provides [programForHost]

programForHost : Box Str -> Elem
programForHost = \a -> program (Box.unbox a)
