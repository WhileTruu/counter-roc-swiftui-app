interface Elem
  exposes [
    Elem,
    text,
    vStack,
  ]
  imports []

Elem : [
    TextElem { text : Str },
    VStackElem (List Elem),
]

text : Str -> Elem
text = \str ->
    TextElem {text : str}

vStack : List Elem -> Elem
vStack = \elems ->
    VStackElem elems