interface Elem
  exposes [
    Elem,
    hStack,
    text,
    vStack,
    button,
  ]
  imports []

Elem msg : [
    Button { label : Str, onClick : msg },
    HStackElem (List (Elem msg)),
    TextElem { text : Str },
    VStackElem (List (Elem msg)),
]

text : Str -> Elem msg
text = \str ->
    TextElem {text : str}

vStack : List (Elem msg) -> Elem msg
vStack = \elems ->
    VStackElem elems

hStack : List (Elem msg) -> Elem msg
hStack = \elems ->
    HStackElem elems

button : { label : Str, onClick : msg } -> Elem msg
button = \{ label, onClick } ->
    Button { label : label, onClick : onClick }