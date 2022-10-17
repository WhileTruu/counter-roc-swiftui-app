platform "swiftui-platform"
    requires {} { main : Str -> Str }
    exposes []
    packages {}
    imports []
    provides [mainForHost]

mainForHost : Box Str -> Str
mainForHost = \a -> main (Box.unbox a)

