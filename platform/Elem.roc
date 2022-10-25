interface Elem
  exposes [
    Elem,
    text,
    potatoText,
    vStack,
  ]
  imports []

Elem : [
    PotatoTextElem { schMext : Str },
    TextElem { text : Str },
    VStackElem (List Elem),
    XTextElem { ext : Str },
    XXTextElem { sext : Str },
]

text : Str -> Elem
text = \str ->
    if Str.countGraphemes str > 5 then
        XTextElem { ext : str }
    else if Str.countGraphemes str == 4 then
        TextElem {text : str}
    else if Str.countGraphemes str == 3 then
        XXTextElem {sext : str}
    else
        PotatoTextElem { schMext : str }

potatoText : Str -> Elem
potatoText = \str ->
    if Str.countGraphemes str < 5 then
        TextElem { text : str }
    else
        PotatoTextElem { schMext : str }

vStack : List Elem -> Elem
vStack = \elems ->
    VStackElem elems