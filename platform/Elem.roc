interface Elem
  exposes [TextElem, text]
  imports []

TextElem : [ TextElem { text : Str } ]

text : Str -> TextElem
text = \str ->
    TextElem { text : str }
