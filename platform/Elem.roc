interface Elem
  exposes [Elem, text]
  imports []

Elem : [ TextElem { text : Str } ]

text : Str -> Elem
text = \str ->
    TextElem { text : str }
