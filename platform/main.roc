platform "swiftui-platform"
    requires {} { main : Str -> TextElem }
    exposes []
    packages {}
    imports [Elem.{ TextElem }]
    provides [mainForHost]

mainForHost : Box Str -> TextElem
mainForHost = \a -> main (Box.unbox a)

