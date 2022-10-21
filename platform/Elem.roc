interface Elem
  exposes [Elem, text, potatoText]
  imports []

Elem : [
    PotatoTextElem { schMext : Str, poop : F32 },
    TextElem { text : Str },
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
        PotatoTextElem { schMext : str, poop : 2 }

potatoText : Str -> Elem
potatoText = \str ->
    if Str.countGraphemes str < 5 then
        TextElem { text : str }
    else
        PotatoTextElem { schMext : str, poop : 2 }