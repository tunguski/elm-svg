module Draw exposing
    ( Shape, svg, toSvg, group
    , rect, square, circle, ellipse, line, polygon, polyline, path, text
    , fill, noFill, stroke, strokeWidth, opacity, fillOpacity, dashed, rounded
    , move, rotate, scale, transform
    , onClick, onMouseOver, onMouseOut, onMouseDown
    , withChild, withChildren
    )

{-| A small, composable vocabulary for **general-purpose SVG drawing** — not charts. Build a
[`Shape`](#Shape) from a primitive, pipe it through style and transform modifiers, and drop a list
of them onto a [`svg`](#svg) canvas:

    Draw.svg 120 120
        [ Draw.circle 60 60 50 |> Draw.fill "#ffd166"
        , Draw.circle 45 50 6 |> Draw.fill "#073b4c"
        , Draw.circle 75 50 6 |> Draw.fill "#073b4c"
        , Draw.path (smile |> Path.toString) |> Draw.stroke "#073b4c" |> Draw.strokeWidth 4
        ]

Shapes carry plain SVG attributes, so they compose with [`Path`](Path) for curves, [`Animate`](Animate)
for motion (via [`withChild`](#withChild)), and the event handlers here for interactivity. Colours
are inline (the backend doesn't bind `class`).

@docs Shape, svg, toSvg, group
@docs rect, square, circle, ellipse, line, polygon, polyline, path, text
@docs fill, noFill, stroke, strokeWidth, opacity, fillOpacity, dashed, rounded
@docs move, rotate, scale, transform
@docs onClick, onMouseOver, onMouseOut, onMouseDown
@docs withChild, withChildren

-}

import Html.Events as HE
import Svg exposing (Svg)
import Svg.Attributes as SA


{-| A styled, positioned SVG element (and any children/animations attached to it). -}
type Shape msg
    = Shape
        { make : List (Svg.Attribute msg) -> List (Svg msg) -> Svg msg
        , attrs : List (Svg.Attribute msg)
        , kids : List (Svg msg)
        , xf : List String
        }


prim : (List (Svg.Attribute msg) -> List (Svg msg) -> Svg msg) -> List (Svg.Attribute msg) -> Shape msg
prim make attrs =
    Shape { make = make, attrs = attrs, kids = [], xf = [] }


{-| Render a shape to an `Svg` node. -}
toSvg : Shape msg -> Svg msg
toSvg (Shape s) =
    s.make
        (s.attrs
            ++ (if List.isEmpty s.xf then
                    []

                else
                    [ SA.transform (String.join " " s.xf) ]
               )
        )
        s.kids


{-| A drawing canvas of the given width and height (a `viewBox`-sized `<svg>`). -}
svg : Float -> Float -> List (Shape msg) -> Svg msg
svg w h shapes =
    Svg.svg
        [ SA.viewBox ("0 0 " ++ n w ++ " " ++ n h), SA.width (n w), SA.height (n h) ]
        (List.map toSvg shapes)


{-| Group shapes into one (so they can be moved, rotated or styled together). -}
group : List (Shape msg) -> Shape msg
group shapes =
    Shape { make = Svg.g, attrs = [], kids = List.map toSvg shapes, xf = [] }



-- PRIMITIVES -----------------------------------------------------------------


{-| A rectangle at `(x, y)` of the given width and height. -}
rect : Float -> Float -> Float -> Float -> Shape msg
rect x y w h =
    prim Svg.rect [ SA.x (n x), SA.y (n y), SA.width (n w), SA.height (n h) ]


{-| A square at `(x, y)`. -}
square : Float -> Float -> Float -> Shape msg
square x y side =
    rect x y side side


{-| A circle of radius `r` centred at `(cx, cy)`. -}
circle : Float -> Float -> Float -> Shape msg
circle cx cy r =
    prim Svg.circle [ SA.cx (n cx), SA.cy (n cy), SA.r (n r) ]


{-| An ellipse centred at `(cx, cy)` with radii `rx`/`ry`. -}
ellipse : Float -> Float -> Float -> Float -> Shape msg
ellipse cx cy rx ry =
    prim Svg.ellipse [ SA.cx (n cx), SA.cy (n cy), SA.rx (n rx), SA.ry (n ry) ]


{-| A line from `(x1, y1)` to `(x2, y2)` (black, 1px by default). -}
line : Float -> Float -> Float -> Float -> Shape msg
line x1 y1 x2 y2 =
    prim Svg.line [ SA.x1 (n x1), SA.y1 (n y1), SA.x2 (n x2), SA.y2 (n y2), SA.stroke "black", SA.strokeWidth "1" ]


{-| A filled polygon through the points. -}
polygon : List ( Float, Float ) -> Shape msg
polygon pts =
    prim Svg.polygon [ SA.points (points pts) ]


{-| An open polyline through the points (no fill, black stroke by default). -}
polyline : List ( Float, Float ) -> Shape msg
polyline pts =
    prim Svg.polyline [ SA.points (points pts), SA.fill "none", SA.stroke "black", SA.strokeWidth "1" ]


{-| A `<path>` from a `d` string — pair with [`Path`](Path). Outlined (no fill) by default. -}
path : String -> Shape msg
path d =
    prim Svg.path [ SA.d d, SA.fill "none", SA.stroke "black", SA.strokeWidth "1" ]


{-| A text label anchored at `(x, y)`. -}
text : Float -> Float -> String -> Shape msg
text x y str =
    Shape { make = Svg.text_, attrs = [ SA.x (n x), SA.y (n y) ], kids = [ Svg.text str ], xf = [] }



-- STYLE ----------------------------------------------------------------------


addAttr : Svg.Attribute msg -> Shape msg -> Shape msg
addAttr a (Shape s) =
    Shape { s | attrs = s.attrs ++ [ a ] }


{-| Set the fill colour. -}
fill : String -> Shape msg -> Shape msg
fill c =
    addAttr (SA.fill c)


{-| Remove the fill (`fill="none"`). -}
noFill : Shape msg -> Shape msg
noFill =
    addAttr (SA.fill "none")


{-| Set the stroke colour. -}
stroke : String -> Shape msg -> Shape msg
stroke c =
    addAttr (SA.stroke c)


{-| Set the stroke width. -}
strokeWidth : Float -> Shape msg -> Shape msg
strokeWidth w =
    addAttr (SA.strokeWidth (n w))


{-| Set the overall opacity (0–1). -}
opacity : Float -> Shape msg -> Shape msg
opacity o =
    addAttr (SA.opacity (n o))


{-| Set the fill opacity (0–1). -}
fillOpacity : Float -> Shape msg -> Shape msg
fillOpacity o =
    addAttr (SA.fillOpacity (n o))


{-| Make the stroke dashed with the given `stroke-dasharray` pattern, e.g. `"4 3"`. -}
dashed : String -> Shape msg -> Shape msg
dashed pattern =
    addAttr (SA.strokeDasharray pattern)


{-| Round a rectangle's corners by the given radius. -}
rounded : Float -> Shape msg -> Shape msg
rounded r =
    addAttr (SA.rx (n r))



-- TRANSFORMS -----------------------------------------------------------------


addXf : String -> Shape msg -> Shape msg
addXf x (Shape s) =
    Shape { s | xf = s.xf ++ [ x ] }


{-| Translate the shape by `(dx, dy)`. -}
move : Float -> Float -> Shape msg -> Shape msg
move dx dy =
    addXf ("translate(" ++ n dx ++ "," ++ n dy ++ ")")


{-| Rotate the shape `degrees` about the pivot `(cx, cy)`. -}
rotate : Float -> Float -> Float -> Shape msg -> Shape msg
rotate degrees cx cy =
    addXf ("rotate(" ++ n degrees ++ "," ++ n cx ++ "," ++ n cy ++ ")")


{-| Scale the shape by `(sx, sy)`. -}
scale : Float -> Float -> Shape msg -> Shape msg
scale sx sy =
    addXf ("scale(" ++ n sx ++ "," ++ n sy ++ ")")


{-| Append a raw SVG `transform` token (e.g. `"skewX(20)"`). -}
transform : String -> Shape msg -> Shape msg
transform raw =
    addXf raw



-- INTERACTIVITY --------------------------------------------------------------


{-| Send a message when the shape is clicked. -}
onClick : msg -> Shape msg -> Shape msg
onClick msg =
    addAttr (HE.onClick msg)


{-| Send a message when the pointer enters the shape. -}
onMouseOver : msg -> Shape msg -> Shape msg
onMouseOver msg =
    addAttr (HE.onMouseOver msg)


{-| Send a message when the pointer leaves the shape. -}
onMouseOut : msg -> Shape msg -> Shape msg
onMouseOut msg =
    addAttr (HE.onMouseOut msg)


{-| Send a message when the pointer is pressed on the shape. -}
onMouseDown : msg -> Shape msg -> Shape msg
onMouseDown msg =
    addAttr (HE.onMouseDown msg)



-- CHILDREN -------------------------------------------------------------------


{-| Attach a child node — chiefly an [`Animate`](Animate) animation, which lives inside the element
it animates. -}
withChild : Svg msg -> Shape msg -> Shape msg
withChild k (Shape s) =
    Shape { s | kids = s.kids ++ [ k ] }


{-| Attach several child nodes. -}
withChildren : List (Svg msg) -> Shape msg -> Shape msg
withChildren ks (Shape s) =
    Shape { s | kids = s.kids ++ ks }



-- HELPERS --------------------------------------------------------------------


points : List ( Float, Float ) -> String
points pts =
    String.join " " (List.map (\( x, y ) -> n x ++ "," ++ n y) pts)


n : Float -> String
n f =
    if toFloat (round f) == f && abs f < 1.0e12 then
        String.fromInt (round f)

    else
        String.fromFloat (toFloat (round (f * 1000)) / 1000)
