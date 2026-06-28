module Chart exposing
    ( Config, defaults, dark, darken, sized, colored, palette
    , withColor, withGrid, withValues, withTitle, withAxisTitles, withInner, withCurve, withTips
    , bars, hbars, line, scatter, multiLine, bubble
    , area, stackedArea, stackedBars, groupedBars
    , histogram, pie, donut, radar
    , frame, xAxis, polylineOf, dotsOf, legend
    )

{-| Small, dependency-free SVG charts.

Each chart is one call — `Chart.bars Chart.defaults data` — returning an `Svg` you drop into a
page. Data is plain Elm: a category chart is a `List ( String, Float )` (label, value); a scatter
or a line series is a `List ( Float, Float )` (x, y); a multi-series chart is a list of named
series. Colours come from the [`Config`](#Config), applied inline (the JS backend does not bind
`Svg.Attributes.class`, so SVG nodes are styled by attribute, not CSS). The number-crunching lives
in [`Scale`](Scale) and [`Arc`](Arc).

The `Config` carries a small **theme** — accent colour, axis/grid/label colours, background, font,
and toggles for gridlines, value labels and titles. Because the JS backend miscompiles a record
update on an alias imported from another module, build a `Config` only through the constructors
here ([`sized`](#sized), [`dark`](#dark), [`withGrid`](#withGrid), …), never `{ Chart.defaults | … }`
at the call site.


# Config

@docs Config, defaults, dark, darken, sized, colored, palette
@docs withColor, withGrid, withValues, withTitle, withAxisTitles, withInner, withCurve, withTips


# Charts

@docs bars, hbars, line, scatter, multiLine, bubble
@docs area, stackedArea, stackedBars, groupedBars
@docs histogram, pie, donut, radar


# Building blocks

@docs frame, xAxis, polylineOf, dotsOf, legend

-}

import Arc
import Curve
import Scale exposing (Scale)
import Svg exposing (Svg)
import Svg.Attributes as SA


{-| How a chart looks: dimensions, margins, the theme colours/fonts, and a handful of toggles. -}
type alias Config =
    { width : Float
    , height : Float
    , top : Float
    , right : Float
    , bottom : Float
    , left : Float
    , color : String
    , axis : String
    , label : String
    , grid : String
    , background : String
    , font : String
    , fontSize : Float
    , dotR : Float
    , stroke : Float
    , inner : Float
    , showXLabels : Bool
    , showGrid : Bool
    , showValues : Bool
    , curve : Bool
    , showTips : Bool
    , title : String
    , xTitle : String
    , yTitle : String
    }


{-| A reasonable default config (380×200, one accent colour, light theme, gridlines on). -}
defaults : Config
defaults =
    { width = 380
    , height = 200
    , top = 16
    , right = 14
    , bottom = 28
    , left = 40
    , color = "#5b6ef5"
    , axis = "#9aa7bd"
    , label = "#61708a"
    , grid = "#e7ecf4"
    , background = "none"
    , font = "system-ui, sans-serif"
    , fontSize = 9
    , dotR = 2.6
    , stroke = 2
    , inner = 0.58
    , showXLabels = True
    , showGrid = True
    , showValues = False
    , curve = False
    , showTips = True
    , title = ""
    , xTitle = ""
    , yTitle = ""
    }


{-| A dark theme: light marks on a slate background. -}
dark : Config
dark =
    darken defaults


{-| Recolour any config with the dark theme, keeping its size, margins and toggles — composes with
[`sized`](#sized).
-}
darken : Config -> Config
darken c =
    { c
        | color = "#7c93ff"
        , axis = "#46506a"
        , label = "#9aa7bd"
        , grid = "#2b3145"
        , background = "#171b26"
    }


{-| `defaults` resized. Build config changes **here**, inside the module that owns the `Config`
alias — the elm-lang JS backend miscompiles a record update on a record alias imported from
another module (the un-updated fields come back `undefined`), so callers should reach for these
constructors rather than `{ Chart.defaults | width = … }` at their own site.
-}
sized : Float -> Float -> Config
sized w h =
    { defaults | width = w, height = h }


{-| `defaults` with a different mark colour (see [`sized`](#sized) on why this lives here). -}
colored : String -> Config
colored color =
    { defaults | color = color }


{-| Set the accent (mark) colour, keeping every other field — composes with [`sized`](#sized). -}
withColor : String -> Config -> Config
withColor color c =
    { c | color = color }


{-| Turn horizontal gridlines on (default) or off. -}
withGrid : Bool -> Config -> Config
withGrid on c =
    { c | showGrid = on }


{-| Show the value above each bar. -}
withValues : Bool -> Config -> Config
withValues on c =
    { c | showValues = on }


{-| Add a chart title, drawn top-left. -}
withTitle : String -> Config -> Config
withTitle t c =
    { c | title = t }


{-| Label the X and Y axes. -}
withAxisTitles : String -> String -> Config -> Config
withAxisTitles x y c =
    { c | xTitle = x, yTitle = y }


{-| The donut hole as a fraction of the radius (`0` = a solid pie). -}
withInner : Float -> Config -> Config
withInner f c =
    { c | inner = clamp 0 0.95 f }


{-| Draw line/area series as a smooth [`Curve`](Curve) instead of straight segments. -}
withCurve : Bool -> Config -> Config
withCurve on c =
    { c | curve = on }


{-| Turn the native `<title>` hover tooltips on (default) or off. -}
withTips : Bool -> Config -> Config
withTips on c =
    { c | showTips = on }


{-| A small qualitative colour palette for multi-series charts. -}
palette : List String
palette =
    [ "#5b6ef5", "#e8590c", "#0f9d58", "#c2410c", "#7c3aed", "#0891b2", "#d6336c", "#65a30d" ]


plotW : Config -> Float
plotW c =
    c.width - c.left - c.right


plotH : Config -> Float
plotH c =
    c.height - c.top - c.bottom


{-| The X scale for `count` evenly-spaced category positions (centres of slots). -}
indexScale : Config -> Int -> Scale
indexScale c count =
    Scale.linear ( 0, toFloat (Basics.max 1 (count - 1)) ) ( c.left, c.left + plotW c )


yScaleFor : Config -> List Float -> Scale
yScaleFor c values =
    let
        ( lo, hi ) =
            Scale.niceBoundsRounded 5 (Scale.niceBounds values)
    in
    Scale.linear ( lo, hi ) ( c.top + plotH c, c.top )


root : Config -> List (Svg msg) -> Svg msg
root c children =
    -- NB: Svg.Attributes.class is unbound in the elm-lang JS backend, so SVG nodes carry no
    -- classes — every colour is set inline via the Config. Width/height give the svg its size.
    Svg.svg
        [ SA.viewBox ("0 0 " ++ Scale.num c.width ++ " " ++ Scale.num c.height)
        , SA.width (Scale.num c.width)
        , SA.height (Scale.num c.height)
        ]
        (background c ++ children)


background : Config -> List (Svg msg)
background c =
    if c.background == "none" then
        []

    else
        [ Svg.rect
            [ SA.x "0", SA.y "0", SA.width (Scale.num c.width), SA.height (Scale.num c.height), SA.fill c.background ]
            []
        ]



-- HIGH-LEVEL CHARTS ----------------------------------------------------------


{-| A bar chart of `(label, value)` pairs. -}
bars : Config -> List ( String, Float ) -> Svg msg
bars c data =
    let
        values =
            List.map Tuple.second data

        yS =
            yScaleFor c values

        count =
            List.length data

        slot =
            plotW c / toFloat (Basics.max 1 count)

        barW =
            slot * 0.64

        zeroY =
            Scale.convert yS 0

        bar i ( lbl, v ) =
            let
                cx =
                    c.left + slot * (toFloat i + 0.5)

                y =
                    Scale.convert yS v

                value =
                    if c.showValues then
                        [ valueLabel c cx (Basics.min y zeroY - 3) (Scale.num v) ]

                    else
                        []
            in
            Svg.g []
                ([ Svg.rect
                    [ SA.x (Scale.num (cx - barW / 2))
                    , SA.y (Scale.num (Basics.min y zeroY))
                    , SA.width (Scale.num barW)
                    , SA.height (Scale.num (Basics.max 0.5 (abs (zeroY - y))))
                    , SA.fill c.color
                    ]
                    (tip c (lbl ++ ": " ++ Scale.num v))
                 , xLabel c count cx lbl
                 ]
                    ++ value
                )
    in
    root c (frame c yS ++ List.indexedMap bar data)


{-| A line chart of `(label, value)` pairs (X is the category index). -}
line : Config -> List ( String, Float ) -> Svg msg
line c data =
    let
        values =
            List.map Tuple.second data

        yS =
            yScaleFor c values

        xS =
            indexScale c (List.length data)

        count =
            List.length data

        pts =
            List.indexedMap (\i ( _, v ) -> ( Scale.convert xS (toFloat i), Scale.convert yS v )) data

        labels =
            List.indexedMap (\i ( lbl, _ ) -> xLabel c count (Scale.convert xS (toFloat i)) lbl) data

        tips =
            -- NB: elm-lang's JS backend evaluates let bindings in source order without hoisting,
            -- and List.indexedMap runs eagerly — so any helper used here must be defined ABOVE.
            List.indexedMap
                (\i ( lbl, v ) -> dot c c.color c.dotR ( Scale.convert xS (toFloat i), Scale.convert yS v ) (lbl ++ ": " ++ Scale.num v))
                data
    in
    root c (frame c yS ++ (strokeLine c c.color (curved c pts) :: tips ++ labels))


{-| An area chart of `(label, value)` pairs: a line with the region down to the baseline filled. -}
area : Config -> List ( String, Float ) -> Svg msg
area c data =
    let
        values =
            List.map Tuple.second data

        yS =
            yScaleFor c values

        xS =
            indexScale c (List.length data)

        count =
            List.length data

        zeroY =
            Scale.convert yS 0

        pts =
            List.indexedMap (\i ( _, v ) -> ( Scale.convert xS (toFloat i), Scale.convert yS v )) data

        labels =
            List.indexedMap (\i ( lbl, _ ) -> xLabel c count (Scale.convert xS (toFloat i)) lbl) data

        tips =
            List.indexedMap
                (\i ( lbl, v ) -> dot c c.color c.dotR ( Scale.convert xS (toFloat i), Scale.convert yS v ) (lbl ++ ": " ++ Scale.num v))
                data

        shape =
            curved c pts
    in
    root c
        (frame c yS
            ++ (areaBand c.color zeroY shape
                    :: strokeLine c c.color shape
                    :: tips
                    ++ labels
               )
        )


{-| A scatter plot of `(x, y)` points. -}
scatter : Config -> List ( Float, Float ) -> Svg msg
scatter c data =
    let
        ( xlo, xhi ) =
            Scale.niceBoundsRounded 5 (Scale.niceBounds (List.map Tuple.first data))

        xS =
            Scale.linear ( xlo, xhi ) ( c.left, c.left + plotW c )

        yS =
            yScaleFor c (List.map Tuple.second data)

        dots =
            List.map
                (\( x, y ) -> dot c c.color c.dotR ( Scale.convert xS x, Scale.convert yS y ) ("(" ++ Scale.num x ++ ", " ++ Scale.num y ++ ")"))
                data
    in
    root c (frame c yS ++ xAxis c xS ++ dots)


{-| Several named `(x, y)` line series, each in a palette colour, with a legend. -}
multiLine : Config -> List ( String, List ( Float, Float ) ) -> Svg msg
multiLine c serieses =
    let
        allX =
            List.concatMap (\( _, pts ) -> List.map Tuple.first pts) serieses

        allY =
            List.concatMap (\( _, pts ) -> List.map Tuple.second pts) serieses

        ( xlo, xhi ) =
            Scale.niceBoundsRounded 5 (Scale.niceBounds allX)

        xS =
            Scale.linear ( xlo, xhi ) ( c.left, c.left + plotW c )

        yS =
            yScaleFor c allY

        place pts =
            List.map (\( x, y ) -> ( Scale.convert xS x, Scale.convert yS y )) pts

        draw i ( _, pts ) =
            strokeLine c (colorAt i) (curved c (place pts))
    in
    root c
        (frame c yS
            ++ xAxis c xS
            ++ List.indexedMap draw serieses
            ++ [ legend c (List.map Tuple.first serieses) ]
        )


{-| Several named series stacked into filled bands (each point list shares its X positions). -}
stackedArea : Config -> List ( String, List ( Float, Float ) ) -> Svg msg
stackedArea c serieses =
    let
        xs =
            case serieses of
                ( _, pts ) :: _ ->
                    List.map Tuple.first pts

                [] ->
                    []

        -- running cumulative Y per X position, bottom band first
        stack ( _, pts ) ( prev, acc ) =
            let
                ys =
                    List.map Tuple.second pts

                cum =
                    List.map2 (+) (pad prev ys) ys
            in
            ( cum, acc ++ [ List.map2 Tuple.pair xs cum ] )

        ( topband, bands ) =
            List.foldl stack ( [], [] ) serieses

        allY =
            topband

        ( xlo, xhi ) =
            Scale.niceBoundsRounded 5 (Scale.niceBounds xs)

        xS =
            Scale.linear ( xlo, xhi ) ( c.left, c.left + plotW c )

        yS =
            yScaleFor c (0 :: allY)

        zeroY =
            Scale.convert yS 0

        place pts =
            List.map (\( x, y ) -> ( Scale.convert xS x, Scale.convert yS y )) pts

        -- draw from the top band down so lower bands paint over the baseline gap
        draw i band =
            areaBand (colorAt i) zeroY (curved c (place band))
    in
    root c
        (frame c yS
            ++ xAxis c xS
            ++ List.reverse (List.indexedMap draw bands)
            ++ [ legend c (List.map Tuple.first serieses) ]
        )


{-| Bars split into stacked segments. Each category is `(label, [(series, value)])`; the series in
the first category fix the colour and legend order.
-}
stackedBars : Config -> List ( String, List ( String, Float ) ) -> Svg msg
stackedBars c data =
    let
        totals =
            List.map (\( _, segs ) -> List.sum (List.map Tuple.second segs)) data

        yS =
            yScaleFor c (0 :: totals)

        count =
            List.length data

        slot =
            plotW c / toFloat (Basics.max 1 count)

        barW =
            slot * 0.64

        seriesNames =
            case data of
                ( _, segs ) :: _ ->
                    List.map Tuple.first segs

                [] ->
                    []

        seg cx ( j, ( name, v ) ) ( cum, acc ) =
            let
                yTop =
                    Scale.convert yS (cum + v)

                yBot =
                    Scale.convert yS cum
            in
            ( cum + v
            , acc
                ++ [ Svg.rect
                        [ SA.x (Scale.num (cx - barW / 2))
                        , SA.y (Scale.num yTop)
                        , SA.width (Scale.num barW)
                        , SA.height (Scale.num (Basics.max 0.5 (abs (yBot - yTop))))
                        , SA.fill (colorAt j)
                        ]
                        (tip c (name ++ ": " ++ Scale.num v))
                   ]
            )

        bar i ( lbl, segs ) =
            let
                cx =
                    c.left + slot * (toFloat i + 0.5)

                ( _, rects ) =
                    List.foldl (seg cx) ( 0, [] ) (List.indexedMap Tuple.pair segs)
            in
            Svg.g [] (rects ++ [ xLabel c count cx lbl ])
    in
    root c (frame c yS ++ List.indexedMap bar data ++ [ legend c seriesNames ])


{-| Bars split into side-by-side groups (same data shape as [`stackedBars`](#stackedBars)). -}
groupedBars : Config -> List ( String, List ( String, Float ) ) -> Svg msg
groupedBars c data =
    let
        allValues =
            List.concatMap (\( _, segs ) -> List.map Tuple.second segs) data

        yS =
            yScaleFor c (0 :: allValues)

        count =
            List.length data

        slot =
            plotW c / toFloat (Basics.max 1 count)

        groupW =
            slot * 0.7

        zeroY =
            Scale.convert yS 0

        seriesNames =
            case data of
                ( _, segs ) :: _ ->
                    List.map Tuple.first segs

                [] ->
                    []

        n =
            Basics.max 1 (List.length seriesNames)

        subW =
            groupW / toFloat n

        sub cx ( j, ( name, v ) ) =
            let
                x =
                    cx - groupW / 2 + toFloat j * subW

                y =
                    Scale.convert yS v
            in
            Svg.rect
                [ SA.x (Scale.num (x + subW * 0.1))
                , SA.y (Scale.num (Basics.min y zeroY))
                , SA.width (Scale.num (subW * 0.8))
                , SA.height (Scale.num (Basics.max 0.5 (abs (zeroY - y))))
                , SA.fill (colorAt j)
                ]
                (tip c (name ++ ": " ++ Scale.num v))

        bar i ( lbl, segs ) =
            let
                cx =
                    c.left + slot * (toFloat i + 0.5)
            in
            Svg.g [] (List.map (sub cx) (List.indexedMap Tuple.pair segs) ++ [ xLabel c count cx lbl ])
    in
    root c (frame c yS ++ List.indexedMap bar data ++ [ legend c seriesNames ])


{-| A pie chart of `(label, value)` slices, with a legend. -}
pie : Config -> List ( String, Float ) -> Svg msg
pie c data =
    pieDonut c 0 data


{-| A donut chart — a pie with a hole sized by [`withInner`](#withInner). -}
donut : Config -> List ( String, Float ) -> Svg msg
donut c data =
    pieDonut c c.inner data


pieDonut : Config -> Float -> List ( String, Float ) -> Svg msg
pieDonut c innerFrac data =
    let
        cx =
            c.left + plotW c / 2

        cy =
            c.top + plotH c / 2

        radius =
            Basics.min (plotW c) (plotH c) / 2 * 0.92

        center =
            ( cx, cy )

        slice i ( ( lbl, v ), slc ) =
            let
                pts =
                    if innerFrac <= 0 then
                        Arc.wedgePoints center radius slc.start slc.end

                    else
                        Arc.ringPoints center (radius * innerFrac) radius slc.start slc.end
            in
            Svg.polyline
                [ SA.points (Scale.pointsString pts)
                , SA.fill (colorAt i)
                , SA.stroke c.background
                , SA.strokeWidth "1"
                ]
                (tip c (lbl ++ ": " ++ Scale.num v ++ " (" ++ Scale.num (slc.fraction * 100) ++ "%)"))

        paired =
            List.map2 Tuple.pair data (Arc.slices (List.map Tuple.second data))
    in
    root c
        (List.indexedMap slice paired
            ++ [ legend c (List.map Tuple.first data) ]
        )


{-| A horizontal bar chart of `(label, value)` pairs — categories down the left, values along the
bottom. Good for long category labels or rankings.
-}
hbars : Config -> List ( String, Float ) -> Svg msg
hbars c data =
    let
        ( lo, hi ) =
            Scale.niceBoundsRounded 5 (Scale.niceBounds (List.map Tuple.second data))

        xS =
            Scale.linear ( lo, hi ) ( c.left, c.left + plotW c )

        count =
            List.length data

        slot =
            plotH c / toFloat (Basics.max 1 count)

        barH =
            slot * 0.62

        zeroX =
            Scale.convert xS 0

        bottomY =
            c.top + plotH c

        bar i ( lbl, v ) =
            let
                cy =
                    c.top + slot * (toFloat i + 0.5)

                x =
                    Scale.convert xS v
            in
            Svg.g []
                [ Svg.rect
                    [ SA.x (Scale.num (Basics.min x zeroX))
                    , SA.y (Scale.num (cy - barH / 2))
                    , SA.width (Scale.num (Basics.max 0.5 (abs (x - zeroX))))
                    , SA.height (Scale.num barH)
                    , SA.fill c.color
                    ]
                    (tip c (lbl ++ ": " ++ Scale.num v))
                , tickLabel c (c.left - 5) (cy + 3) (clip lbl)
                ]
    in
    root c
        (xAxis c xS
            ++ [ axisLine c c.left c.top c.left bottomY
               , axisLine c zeroX c.top zeroX bottomY
               ]
            ++ List.indexedMap bar data
        )


{-| A bubble chart of `(x, y, size)` points: x/y give position, **area** encodes size, and colour
runs a sequential ramp from the first to the second palette colour (via
[`Scale.interpolateColor`](Scale)).
-}
bubble : Config -> List ( Float, Float, Float ) -> Svg msg
bubble c data =
    let
        xs =
            List.map (\( x, _, _ ) -> x) data

        ys =
            List.map (\( _, y, _ ) -> y) data

        sizes =
            List.map (\( _, _, s ) -> s) data

        ( xlo, xhi ) =
            Scale.niceBoundsRounded 5 (Scale.niceBounds xs)

        xS =
            Scale.linear ( xlo, xhi ) ( c.left, c.left + plotW c )

        yS =
            yScaleFor c ys

        maxS =
            Basics.max 1.0e-9 (List.maximum sizes |> Maybe.withDefault 1)

        maxR =
            Basics.min (plotW c) (plotH c) / 8

        bubbleOf ( x, y, s ) =
            let
                t =
                    Basics.max 0 s / maxS
            in
            Svg.circle
                [ SA.cx (Scale.num (Scale.convert xS x))
                , SA.cy (Scale.num (Scale.convert yS y))
                , SA.r (Scale.num (sqrt t * maxR))
                , SA.fill (Scale.interpolateColor (colorAt 0) (colorAt 1) t)
                , SA.fillOpacity "0.65"
                ]
                (tip c ("(" ++ Scale.num x ++ ", " ++ Scale.num y ++ ") · " ++ Scale.num s))
    in
    root c (frame c yS ++ xAxis c xS ++ List.map bubbleOf data)


{-| A histogram of a raw `List Float`: values are split into equal-width bins (about √n of them) and
each bin drawn as a bar.
-}
histogram : Config -> List Float -> Svg msg
histogram c values =
    let
        bins =
            clamp 1 30 (round (sqrt (toFloat (List.length values))))

        ( ( lo, hi ), counts ) =
            Scale.binCounts bins values

        xS =
            Scale.linear ( lo, hi ) ( c.left, c.left + plotW c )

        yS =
            yScaleFor c (0 :: List.map toFloat counts)

        zeroY =
            Scale.convert yS 0

        binW =
            (hi - lo) / toFloat (Basics.max 1 bins)

        bar i cnt =
            let
                x0 =
                    Scale.convert xS (lo + binW * toFloat i)

                x1 =
                    Scale.convert xS (lo + binW * toFloat (i + 1))

                y =
                    Scale.convert yS (toFloat cnt)
            in
            Svg.rect
                [ SA.x (Scale.num x0)
                , SA.y (Scale.num y)
                , SA.width (Scale.num (Basics.max 0.5 (x1 - x0 - 1)))
                , SA.height (Scale.num (Basics.max 0 (zeroY - y)))
                , SA.fill c.color
                ]
                (tip c (Scale.num (lo + binW * toFloat i) ++ "–" ++ Scale.num (lo + binW * toFloat (i + 1)) ++ ": " ++ String.fromInt cnt))
    in
    root c (frame c yS ++ xAxis c xS ++ List.indexedMap bar counts)


{-| A radar (spider) chart: `axes` names the spokes and each series is `(name, values)` with one
value per axis (in axis order). Values share a single 0…max radial scale; each series is a
translucent polygon, with a legend.
-}
radar : Config -> List String -> List ( String, List Float ) -> Svg msg
radar c axes serieses =
    let
        n =
            List.length axes

        center =
            ( c.left + plotW c / 2, c.top + plotH c / 2 )

        radius =
            Basics.min (plotW c) (plotH c) / 2 * 0.74

        maxV =
            Basics.max 1.0e-9 (List.maximum (List.concatMap Tuple.second serieses) |> Maybe.withDefault 1)

        angleOf i =
            toFloat i / toFloat (Basics.max 1 n) * Arc.tau

        rings =
            List.map
                (\f -> ringLoop c.grid (List.indexedMap (\i _ -> Arc.pointOnCircle center (radius * f) (angleOf i)) axes))
                [ 0.25, 0.5, 0.75, 1.0 ]

        spokes =
            List.indexedMap
                (\i _ ->
                    let
                        ( ex, ey ) =
                            Arc.pointOnCircle center radius (angleOf i)
                    in
                    axisLine c (Tuple.first center) (Tuple.second center) ex ey
                )
                axes

        labels =
            List.indexedMap
                (\i name ->
                    let
                        ( lx, ly ) =
                            Arc.pointOnCircle center (radius + 10) (angleOf i)
                    in
                    Svg.text_
                        [ SA.x (Scale.num lx), SA.y (Scale.num ly), SA.fill c.label, SA.fontFamily c.font, SA.fontSize (Scale.num c.fontSize), SA.textAnchor "middle" ]
                        [ Svg.text (clip name) ]
                )
                axes

        poly i ( _, vals ) =
            Svg.polyline
                [ SA.points (Scale.pointsString (closeLoop (List.indexedMap (\j v -> Arc.pointOnCircle center (radius * (Basics.max 0 v / maxV)) (angleOf j)) vals)))
                , SA.fill (colorAt i)
                , SA.fillOpacity "0.12"
                , SA.stroke (colorAt i)
                , SA.strokeWidth (Scale.num c.stroke)
                ]
                []
    in
    root c
        (rings
            ++ spokes
            ++ labels
            ++ List.indexedMap poly serieses
            ++ [ legend c (List.map Tuple.first serieses) ]
        )



-- BUILDING BLOCKS ------------------------------------------------------------


{-| The plot furniture for a chart with the given Y scale: gridlines, tick labels, the Y axis, a
zero baseline and any titles set on the `Config`.
-}
frame : Config -> Scale -> List (Svg msg)
frame c yS =
    let
        left =
            c.left

        right =
            c.left + plotW c

        zeroY =
            Scale.convert yS 0

        tickVals =
            Scale.niceTicks 5 ( yS.d0, yS.d1 )

        gridFor v =
            let
                y =
                    Scale.convert yS v
            in
            (if c.showGrid then
                [ gridLine c left y right y ]

             else
                []
            )
                ++ [ tickLabel c (left - 5) (y + 3) (Scale.num v) ]
    in
    List.concatMap gridFor tickVals
        ++ [ axisLine c left c.top left (c.top + plotH c)
           , axisLine c left zeroY right zeroY
           ]
        ++ titles c


{-| A numeric X axis for a chart with the given X scale: 1·2·5 vertical gridlines, tick labels along
the bottom, and the baseline axis. Pair with [`frame`](#frame) for charts whose X is a real number
(scatter, multi-line) rather than a category.
-}
xAxis : Config -> Scale -> List (Svg msg)
xAxis c xS =
    let
        bottomY =
            c.top + plotH c

        gridFor v =
            let
                x =
                    Scale.convert xS v
            in
            (if c.showGrid then
                [ gridLine c x c.top x bottomY ]

             else
                []
            )
                ++ [ valueLabel c x (bottomY + 13) (Scale.num v) ]
    in
    List.concatMap gridFor (Scale.niceTicks 5 ( xS.d0, xS.d1 ))
        ++ [ axisLine c c.left bottomY (c.left + plotW c) bottomY ]


titles : Config -> List (Svg msg)
titles c =
    let
        chartTitle =
            if c.title == "" then
                []

            else
                [ Svg.text_
                    [ SA.x (Scale.num c.left), SA.y (Scale.num (c.top - 6)), SA.fill c.label, SA.fontFamily c.font, SA.fontSize (Scale.num (c.fontSize + 2)) ]
                    [ Svg.text c.title ]
                ]

        xTitle =
            if c.xTitle == "" then
                []

            else
                [ Svg.text_
                    [ SA.x (Scale.num (c.left + plotW c / 2)), SA.y (Scale.num (c.height - 2)), SA.fill c.label, SA.fontFamily c.font, SA.fontSize (Scale.num c.fontSize), SA.textAnchor "middle" ]
                    [ Svg.text c.xTitle ]
                ]

        yTitle =
            if c.yTitle == "" then
                []

            else
                [ Svg.text_
                    [ SA.x (Scale.num (c.left - 32)), SA.y (Scale.num (c.top - 6)), SA.fill c.label, SA.fontFamily c.font, SA.fontSize (Scale.num c.fontSize) ]
                    [ Svg.text c.yTitle ]
                ]
    in
    chartTitle ++ xTitle ++ yTitle


{-| A legend: a colour swatch and name per series, stacked at the top-right of the plot. -}
legend : Config -> List String -> Svg msg
legend c names =
    let
        x =
            c.left + plotW c - 8

        row i name =
            let
                y =
                    c.top + 2 + toFloat i * (c.fontSize + 4)
            in
            Svg.g []
                [ Svg.rect
                    [ SA.x (Scale.num (x - 9)), SA.y (Scale.num y), SA.width "9", SA.height "9", SA.fill (colorAt i) ]
                    []
                , Svg.text_
                    [ SA.x (Scale.num (x - 13)), SA.y (Scale.num (y + 8)), SA.fill c.label, SA.fontFamily c.font, SA.fontSize (Scale.num c.fontSize), SA.textAnchor "end" ]
                    [ Svg.text (clip name) ]
                ]
    in
    if List.length names <= 1 then
        Svg.text ""

    else
        Svg.g [] (List.indexedMap row names)


{-| A `<polyline>` through pixel points, in the given colour. -}
polylineOf : String -> List ( Float, Float ) -> Svg msg
polylineOf color pts =
    Svg.polyline
        [ SA.points (Scale.pointsString pts)
        , SA.fill "none"
        , SA.stroke color
        , SA.strokeWidth "2"
        ]
        []


closeLoop : List ( Float, Float ) -> List ( Float, Float )
closeLoop pts =
    pts ++ List.take 1 pts


ringLoop : String -> List ( Float, Float ) -> Svg msg
ringLoop color pts =
    Svg.polyline
        [ SA.points (Scale.pointsString (closeLoop pts))
        , SA.fill "none"
        , SA.stroke color
        , SA.strokeWidth "1"
        ]
        []


{-| A `<circle>` dot at each pixel point, in the given colour. -}
dotsOf : String -> List ( Float, Float ) -> List (Svg msg)
dotsOf color pts =
    List.map
        (\( x, y ) ->
            Svg.circle
                [ SA.cx (Scale.num x), SA.cy (Scale.num y), SA.r "2.6", SA.fill color ]
                []
        )
        pts


strokeLine : Config -> String -> List ( Float, Float ) -> Svg msg
strokeLine c color pts =
    Svg.polyline
        [ SA.points (Scale.pointsString pts)
        , SA.fill "none"
        , SA.stroke color
        , SA.strokeWidth (Scale.num c.stroke)
        ]
        []


{-| A circle of the given radius and colour, carrying an optional hover tooltip. -}
dot : Config -> String -> Float -> ( Float, Float ) -> String -> Svg msg
dot c color r ( x, y ) txt =
    Svg.circle
        [ SA.cx (Scale.num x), SA.cy (Scale.num y), SA.r (Scale.num r), SA.fill color ]
        (tip c txt)


{-| An SVG `<title>` child, which browsers show as a native hover tooltip — nothing to wire up, and
no Elm state. Empty when tooltips are off or there is nothing to say.
-}
tip : Config -> String -> List (Svg msg)
tip c txt =
    if c.showTips && txt /= "" then
        [ Svg.title [] [ Svg.text txt ] ]

    else
        []


{-| Smooth a pixel-point list into a curve when the `Config` asks for it, else pass it through. -}
curved : Config -> List ( Float, Float ) -> List ( Float, Float )
curved c pts =
    if c.curve then
        Curve.smooth pts

    else
        pts


areaBand : String -> Float -> List ( Float, Float ) -> Svg msg
areaBand color zeroY pts =
    let
        ends =
            case ( List.head pts, List.head (List.reverse pts) ) of
                ( Just ( x0, _ ), Just ( x1, _ ) ) ->
                    [ ( x1, zeroY ), ( x0, zeroY ) ]

                _ ->
                    []
    in
    Svg.polyline
        [ SA.points (Scale.pointsString (pts ++ ends))
        , SA.fill color
        , SA.fillOpacity "0.16"
        , SA.stroke "none"
        ]
        []


axisLine : Config -> Float -> Float -> Float -> Float -> Svg msg
axisLine c x1 y1 x2 y2 =
    Svg.line
        [ SA.x1 (Scale.num x1)
        , SA.y1 (Scale.num y1)
        , SA.x2 (Scale.num x2)
        , SA.y2 (Scale.num y2)
        , SA.stroke c.axis
        , SA.strokeWidth "1"
        ]
        []


gridLine : Config -> Float -> Float -> Float -> Float -> Svg msg
gridLine c x1 y1 x2 y2 =
    Svg.line
        [ SA.x1 (Scale.num x1)
        , SA.y1 (Scale.num y1)
        , SA.x2 (Scale.num x2)
        , SA.y2 (Scale.num y2)
        , SA.stroke c.grid
        , SA.strokeWidth "1"
        ]
        []


tickLabel : Config -> Float -> Float -> String -> Svg msg
tickLabel c x y txt =
    Svg.text_
        [ SA.x (Scale.num x), SA.y (Scale.num y), SA.fill c.label, SA.fontFamily c.font, SA.fontSize (Scale.num c.fontSize), SA.textAnchor "end" ]
        [ Svg.text txt ]


valueLabel : Config -> Float -> Float -> String -> Svg msg
valueLabel c x y txt =
    Svg.text_
        [ SA.x (Scale.num x), SA.y (Scale.num y), SA.fill c.label, SA.fontFamily c.font, SA.fontSize (Scale.num (c.fontSize - 0.5)), SA.textAnchor "middle" ]
        [ Svg.text txt ]


xLabel : Config -> Int -> Float -> String -> Svg msg
xLabel c count cx lbl =
    if c.showXLabels && count <= 16 then
        Svg.text_
            [ SA.x (Scale.num cx)
            , SA.y (Scale.num (c.height - c.bottom + 13))
            , SA.fill c.label
            , SA.fontFamily c.font
            , SA.fontSize (Scale.num c.fontSize)
            , SA.textAnchor "middle"
            ]
            [ Svg.text (clip lbl) ]

    else
        Svg.text ""


pad : List Float -> List Float -> List Float
pad prev target =
    -- pad/truncate `prev` to the length of `target` with zeros, so List.map2 (+) covers every point
    let
        zeros =
            List.map (\_ -> 0) target
    in
    List.map2 (\_ a -> a) target (prev ++ zeros)


clip : String -> String
clip s =
    if String.length s > 9 then
        String.left 8 s ++ "…"

    else
        s


colorAt : Int -> String
colorAt i =
    case List.drop (modBy (List.length palette) i) palette of
        c :: _ ->
            c

        [] ->
            "#5b6ef5"
