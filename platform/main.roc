platform "swiftui-platform"
    requires {} { main : Str -> Elem }
    exposes []
    packages {}
    imports [Elem.{ Elem }]
    provides [mainForHost]

mainForHost : Box Str -> Elem
mainForHost = \a -> main (Box.unbox a)

