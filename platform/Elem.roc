interface Elem
  exposes [
    Elem,
    hStack,
    text,
    vStack,
  ]
  imports []

Elem : [
    HStackElem (List Elem),
    TextElem { text : Str },
    VStackElem (List Elem),
]

text : Str -> Elem
text = \str ->
    TextElem {text : str}

vStack : List Elem -> Elem
vStack = \elems ->
    VStackElem elems

hStack : List Elem -> Elem
hStack = \elems ->
    HStackElem elems