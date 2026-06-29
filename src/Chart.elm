module Chart exposing
    ( Config, defaults, dark, darken, sized, colored, palette
    , withColor, withGrid, withValues, withTitle, withAxisTitles, withInner, withCurve, withTips
    , withStep, withTrend, withFormat, withYDomain, withYTicks, withMargins
    , RefMark, withRefLine, withRefBand
    , bars, hbars, lollipop, line, scatter, scatterErr, multiLine, bubble, slope, dumbbell, pyramid, bump
    , area, stackedArea, streamgraph, stackedBars, groupedBars, percentBars, pareto
    , histogram, density, pie, donut, radar, funnel, rose, radialBars
    , boxplot, candlestick, heatmap, sparkline, waterfall, gauge, treemap, gantt, bullet
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
@docs withStep, withTrend, withFormat, withYDomain, withYTicks, withMargins
@docs RefMark, withRefLine, withRefBand


# Charts

@docs bars, hbars, lollipop, line, scatter, scatterErr, multiLine, bubble, slope, dumbbell, pyramid, bump
@docs area, stackedArea, streamgraph, stackedBars, groupedBars, percentBars, pareto
@docs histogram, density, pie, donut, radar, funnel, rose, radialBars
@docs boxplot, candlestick, heatmap, sparkline, waterfall, gauge, treemap, gantt, bullet


# Building blocks

@docs frame, xAxis, polylineOf, dotsOf, legend

-}

import Arc
import Curve
import Layout
import Scale exposing (Scale)
import Stat
import Svg exposing (Svg)
import Svg.Attributes as SA


{-| A horizontal annotation drawn behind a chart: either a reference **line** at one value, or a
shaded **band** between two. Build these with [`withRefLine`](#withRefLine) /
[`withRefBand`](#withRefBand) rather than by hand.
-}
type alias RefMark =
    { lo : Float
    , hi : Float
    , color : String
    , label : String
    , band : Bool
    }


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
    , step : Bool
    , trend : Bool
    , showTips : Bool
    , refs : List RefMark
    , format : Float -> String
    , yDomain : Maybe ( Float, Float )
    , yTicks : Int
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
    , step = False
    , trend = False
    , showTips = True
    , refs = []
    , format = Scale.num
    , yDomain = Nothing
    , yTicks = 5
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


{-| Draw line/area series as a step (stair) instead of straight segments — good for values that
hold then jump. Takes precedence over [`withCurve`](#withCurve).
-}
withStep : Bool -> Config -> Config
withStep on c =
    { c | step = on }


{-| Overlay a least-squares trend line on a [`scatter`](#scatter). -}
withTrend : Bool -> Config -> Config
withTrend on c =
    { c | trend = on }


{-| Set the number formatter for Y-axis ticks and value labels — see [`Format`](Format) for
ready-made ones (`Format.percent`, `Format.compact`, `Format.prefixed "$" …`).
-}
withFormat : (Float -> String) -> Config -> Config
withFormat f c =
    { c | format = f }


{-| Pin the Y axis to a fixed `(lo, hi)` domain instead of fitting it to the data — handy for a
consistent scale across small multiples. -}
withYDomain : Float -> Float -> Config -> Config
withYDomain lo hi c =
    { c | yDomain = Just ( lo, hi ) }


{-| Set how many Y-axis tick intervals to draw (default 5). -}
withYTicks : Int -> Config -> Config
withYTicks n c =
    { c | yTicks = Basics.max 1 n }


{-| Set the four plot margins `top right bottom left` (room for axes, labels and titles). -}
withMargins : Float -> Float -> Float -> Float -> Config -> Config
withMargins t r b l c =
    { c | top = t, right = r, bottom = b, left = l }


{-| Add a horizontal reference line at `value` (e.g. a target or threshold), labelled at the right. -}
withRefLine : Float -> String -> Config -> Config
withRefLine value label c =
    { c | refs = c.refs ++ [ { lo = value, hi = value, color = "#e8590c", label = label, band = False } ] }


{-| Add a shaded reference band between `lo` and `hi` (e.g. a tolerance zone), labelled at the right. -}
withRefBand : Float -> Float -> String -> Config -> Config
withRefBand lo hi label c =
    { c | refs = c.refs ++ [ { lo = lo, hi = hi, color = "#e8590c", label = label, band = True } ] }


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
            case c.yDomain of
                Just d ->
                    d

                Nothing ->
                    Scale.niceBoundsRounded c.yTicks (Scale.niceBounds values)
    in
    Scale.linear ( lo, hi ) ( c.top + plotH c, c.top )


{-| Like [`yScaleFor`](#yScaleFor) but scaled to the data's own min…max (no forced zero baseline) —
for distributions and prices where zero is not the reference. -}
yScaleRaw : Config -> List Float -> Scale
yScaleRaw c values =
    let
        lo =
            List.minimum values |> Maybe.withDefault 0

        hi =
            List.maximum values |> Maybe.withDefault 1

        ( a, b ) =
            case c.yDomain of
                Just d ->
                    d

                Nothing ->
                    Scale.niceBoundsRounded c.yTicks
                        (if lo == hi then
                            ( lo - 1, hi + 1 )

                         else
                            ( lo, hi )
                        )
    in
    Scale.linear ( a, b ) ( c.top + plotH c, c.top )


{-| The pixel points to stroke for a line/area series: a step (stair) if the `Config` asks, else a
smooth curve if it does, else the points unchanged. -}
linePoints : Config -> List ( Float, Float ) -> List ( Float, Float )
linePoints c pts =
    if c.step then
        stepped pts

    else
        curved c pts


stepped : List ( Float, Float ) -> List ( Float, Float )
stepped pts =
    case pts of
        first :: _ ->
            first
                :: List.concatMap
                    (\( ( _, y0 ), ( x1, y1 ) ) -> [ ( x1, y0 ), ( x1, y1 ) ])
                    (List.map2 Tuple.pair pts (List.drop 1 pts))

        [] ->
            []


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
                        [ valueLabel c cx (Basics.min y zeroY - 3) (c.format v) ]

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
    root c (frame c yS ++ (strokeLine c c.color (linePoints c pts) :: tips ++ labels))


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
            linePoints c pts
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

        trendLine =
            if c.trend then
                let
                    fit =
                        Stat.linearRegression data

                    at x =
                        ( Scale.convert xS x, Scale.convert yS (fit.slope * x + fit.intercept) )
                in
                [ strokeLine c (colorAt 1) [ at xlo, at xhi ] ]

            else
                []
    in
    root c (frame c yS ++ xAxis c xS ++ trendLine ++ dots)


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


{-| A kernel-density estimate of a raw `List Float`, drawn as a smooth filled curve — a continuous
companion to [`histogram`](#histogram). Bandwidth is chosen by Silverman's rule of thumb (via the
tested [`Stat.kde`](Stat)). -}
density : Config -> List Float -> Svg msg
density c sample =
    let
        n =
            List.length sample

        lo =
            List.minimum sample |> Maybe.withDefault 0

        hi =
            List.maximum sample |> Maybe.withDefault 1

        range =
            if hi == lo then
                1

            else
                hi - lo

        silver =
            1.06 * Stat.stdDev sample * toFloat (Basics.max 1 n) ^ (-0.2)

        h =
            if silver <= 0 then
                range * 0.1

            else
                silver

        x0 =
            lo - 2 * h

        x1 =
            hi + 2 * h

        steps =
            64

        grid =
            List.map (\i -> x0 + (x1 - x0) * toFloat i / toFloat steps) (List.range 0 steps)

        densities =
            List.map (Stat.kde h sample) grid

        xS =
            Scale.linear ( x0, x1 ) ( c.left, c.left + plotW c )

        yS =
            yScaleFor c (0 :: densities)

        pts =
            List.map2 (\gx d -> ( Scale.convert xS gx, Scale.convert yS d )) grid densities
    in
    root c (frame c yS ++ xAxis c xS ++ [ areaBand c.color (Scale.convert yS 0) pts, strokeLine c c.color pts ])


{-| A streamgraph: like [`stackedArea`](#stackedArea) but the stack flows around a centred baseline
(each x's total is split above and below the middle), giving the organic "theme river" look. Same
`(name, [(x, y)])` series; `withCurve` smooths the streams. -}
streamgraph : Config -> List ( String, List ( Float, Float ) ) -> Svg msg
streamgraph c serieses =
    let
        names =
            List.map Tuple.first serieses

        xs =
            case serieses of
                ( _, pts ) :: _ ->
                    List.map Tuple.first pts

                [] ->
                    []

        seriesYs =
            List.map (\( _, pts ) -> List.map Tuple.second pts) serieses

        totals =
            List.foldl (List.map2 (+)) (List.map (\_ -> 0) xs) seriesYs

        startLower =
            List.map (\t -> -t / 2) totals

        stepBand ys ( lower, acc ) =
            let
                upper =
                    List.map2 (+) lower ys
            in
            ( upper, acc ++ [ ( lower, upper ) ] )

        ( _, bands ) =
            List.foldl stepBand ( startLower, [] ) seriesYs

        boundaryVals =
            startLower ++ List.concatMap (\( l, u ) -> l ++ u) bands

        ( a, b ) =
            Scale.niceBoundsRounded 5 ( List.minimum boundaryVals |> Maybe.withDefault 0, List.maximum boundaryVals |> Maybe.withDefault 1 )

        ( xlo, xhi ) =
            Scale.niceBoundsRounded 5 (Scale.niceBounds xs)

        xS =
            Scale.linear ( xlo, xhi ) ( c.left, c.left + plotW c )

        yS =
            Scale.linear ( a, b ) ( c.top + plotH c, c.top )

        toPx vals =
            List.map2 (\x y -> ( Scale.convert xS x, Scale.convert yS y )) xs vals

        bandPoly i ( name, ( lower, upper ) ) =
            Svg.polyline
                [ SA.points (Scale.pointsString (curved c (toPx upper) ++ List.reverse (curved c (toPx lower))))
                , SA.fill (colorAt i)
                , SA.fillOpacity "0.85"
                , SA.stroke c.background
                , SA.strokeWidth "0.5"
                ]
                (tip c name)
    in
    root c (List.indexedMap bandPoly (List.map2 Tuple.pair names bands) ++ [ legend c names ])


{-| A population pyramid: back-to-back horizontal bars per category `(label, left, right)`, the two
sides (`leftName` / `rightName`) sharing one scale, with category labels down the centre. -}
pyramid : Config -> String -> String -> List ( String, Float, Float ) -> Svg msg
pyramid c leftName rightName data =
    let
        maxV =
            Basics.max 1.0e-9 (List.maximum (List.concatMap (\( _, l, r ) -> [ l, r ]) data) |> Maybe.withDefault 1)

        count =
            List.length data

        slot =
            plotH c / toFloat (Basics.max 1 count)

        barH =
            slot * 0.7

        gap =
            46

        midX =
            c.left + plotW c / 2

        halfW =
            (plotW c - gap) / 2

        leftEdge =
            midX - gap / 2

        rightEdge =
            midX + gap / 2

        row i ( lbl, l, r ) =
            let
                cy =
                    c.top + slot * (toFloat i + 0.5)

                ll =
                    l / maxV * halfW

                rl =
                    r / maxV * halfW
            in
            Svg.g []
                [ Svg.rect [ SA.x (Scale.num (leftEdge - ll)), SA.y (Scale.num (cy - barH / 2)), SA.width (Scale.num (Basics.max 0.5 ll)), SA.height (Scale.num barH), SA.fill (colorAt 0) ] (tip c (leftName ++ " " ++ lbl ++ ": " ++ c.format l))
                , Svg.rect [ SA.x (Scale.num rightEdge), SA.y (Scale.num (cy - barH / 2)), SA.width (Scale.num (Basics.max 0.5 rl)), SA.height (Scale.num barH), SA.fill (colorAt 1) ] (tip c (rightName ++ " " ++ lbl ++ ": " ++ c.format r))
                , Svg.text_ [ SA.x (Scale.num midX), SA.y (Scale.num (cy + 3)), SA.fill c.label, SA.fontFamily c.font, SA.fontSize (Scale.num c.fontSize), SA.textAnchor "middle" ] [ Svg.text (clip lbl) ]
                ]
    in
    root c (List.indexedMap row data ++ [ legend c [ leftName, rightName ] ])


{-| A bump chart: each series is `(name, values)` with one value per period, and the chart plots its
**rank** (1 = highest) at each period, connecting the ranks with lines. Shows how an ordering shifts
over time. -}
bump : Config -> List ( String, List Float ) -> Svg msg
bump c serieses =
    let
        names =
            List.map Tuple.first serieses

        seriesVals =
            List.map Tuple.second serieses

        nSeries =
            List.length serieses

        periods =
            List.minimum (List.map List.length seriesVals) |> Maybe.withDefault 0

        valueAt j vals =
            List.head (List.drop j vals) |> Maybe.withDefault 0

        rankOf si j =
            let
                ranked =
                    List.sortBy (\( _, v ) -> -v) (List.indexedMap (\k sv -> ( k, valueAt j sv )) seriesVals)
            in
            1 + (List.indexedMap (\pos ( k, _ ) -> ( pos, k )) ranked |> List.filter (\( _, k ) -> k == si) |> List.head |> Maybe.map Tuple.first |> Maybe.withDefault 0)

        xS =
            Scale.linear ( 0, toFloat (Basics.max 1 (periods - 1)) ) ( c.left, c.left + plotW c )

        yS =
            Scale.linear ( 1, toFloat (Basics.max 1 nSeries) ) ( c.top, c.top + plotH c )

        seriesLine si name =
            let
                pts =
                    List.map (\j -> ( Scale.convert xS (toFloat j), Scale.convert yS (toFloat (rankOf si j)) )) (List.range 0 (periods - 1))
            in
            strokeLine c (colorAt si) pts :: List.map (\p -> dot c (colorAt si) (c.dotR * 1.5) p name) pts

        periodLabels =
            List.map (\j -> valueLabel c (Scale.convert xS (toFloat j)) (c.top + plotH c + 13) (String.fromInt (j + 1))) (List.range 0 (periods - 1))

        rankLabels =
            List.map (\rk -> tickLabel c (c.left - 5) (Scale.convert yS (toFloat rk) + 3) ("#" ++ String.fromInt rk)) (List.range 1 nSeries)
    in
    root c (rankLabels ++ periodLabels ++ List.concat (List.indexedMap seriesLine names) ++ [ legend c names ])


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


{-| A box-and-whisker plot: each category is `(label, sample)` over a raw `List Float`. The box
spans the quartiles with the median marked, and whiskers reach the sample min and max (via the
tested [`Stat`](Stat) module).
-}
boxplot : Config -> List ( String, List Float ) -> Svg msg
boxplot c data =
    let
        yS =
            yScaleRaw c (List.concatMap Tuple.second data)

        count =
            List.length data

        slot =
            plotW c / toFloat (Basics.max 1 count)

        boxW =
            slot * 0.5

        box i ( lbl, sample ) =
            let
                cx =
                    c.left + slot * (toFloat i + 0.5)

                ( q1, q2, q3 ) =
                    Stat.quartiles sample

                lo =
                    List.minimum sample |> Maybe.withDefault q1

                hi =
                    List.maximum sample |> Maybe.withDefault q3

                ( yq1, yq3 ) =
                    ( Scale.convert yS q1, Scale.convert yS q3 )

                ( ylo, yhi ) =
                    ( Scale.convert yS lo, Scale.convert yS hi )

                yq2 =
                    Scale.convert yS q2

                txt =
                    lbl ++ ": min " ++ Scale.num lo ++ ", Q1 " ++ Scale.num q1 ++ ", med " ++ Scale.num q2 ++ ", Q3 " ++ Scale.num q3 ++ ", max " ++ Scale.num hi
            in
            Svg.g []
                [ axisLine c cx yhi cx ylo
                , axisLine c (cx - boxW / 4) yhi (cx + boxW / 4) yhi
                , axisLine c (cx - boxW / 4) ylo (cx + boxW / 4) ylo
                , Svg.rect
                    [ SA.x (Scale.num (cx - boxW / 2)), SA.y (Scale.num (Basics.min yq1 yq3)), SA.width (Scale.num boxW), SA.height (Scale.num (Basics.max 0.5 (abs (yq1 - yq3)))), SA.fill c.color, SA.fillOpacity "0.35", SA.stroke c.color, SA.strokeWidth "1" ]
                    (tip c txt)
                , Svg.line [ SA.x1 (Scale.num (cx - boxW / 2)), SA.y1 (Scale.num yq2), SA.x2 (Scale.num (cx + boxW / 2)), SA.y2 (Scale.num yq2), SA.stroke c.color, SA.strokeWidth "1.5" ] []
                , xLabel c count cx lbl
                ]
    in
    root c (frame c yS ++ List.indexedMap box data)


{-| An OHLC candlestick chart: each entry is `(label, open, high, low, close)`. Up days (close ≥
open) are green, down days red; the wick spans high–low, the body open–close.
-}
candlestick : Config -> List ( String, Float, Float, Float, Float ) -> Svg msg
candlestick c data =
    let
        yS =
            yScaleRaw c (List.concatMap (\( _, _, h, l, _ ) -> [ h, l ]) data)

        count =
            List.length data

        slot =
            plotW c / toFloat (Basics.max 1 count)

        bodyW =
            slot * 0.5

        candle i ( lbl, o, h, l, close ) =
            let
                cx =
                    c.left + slot * (toFloat i + 0.5)

                color =
                    if close >= o then
                        "#0f9d58"

                    else
                        "#d6336c"

                ( yo, yc ) =
                    ( Scale.convert yS o, Scale.convert yS close )

                txt =
                    lbl ++ ": O " ++ Scale.num o ++ " H " ++ Scale.num h ++ " L " ++ Scale.num l ++ " C " ++ Scale.num close
            in
            Svg.g []
                [ Svg.line [ SA.x1 (Scale.num cx), SA.y1 (Scale.num (Scale.convert yS h)), SA.x2 (Scale.num cx), SA.y2 (Scale.num (Scale.convert yS l)), SA.stroke color, SA.strokeWidth "1" ] []
                , Svg.rect
                    [ SA.x (Scale.num (cx - bodyW / 2)), SA.y (Scale.num (Basics.min yo yc)), SA.width (Scale.num bodyW), SA.height (Scale.num (Basics.max 1 (abs (yo - yc)))), SA.fill color ]
                    (tip c txt)
                , xLabel c count cx lbl
                ]
    in
    root c (frame c yS ++ List.indexedMap candle data)


{-| A heatmap of a grid of values, given the column labels, row labels and the rows themselves (each
an inner `List Float`). Cells are shaded along a ramp from the grid colour to the accent colour (via
[`Scale.interpolateColor`](Scale)); hover a cell for its value.
-}
heatmap : Config -> List String -> List String -> List (List Float) -> Svg msg
heatmap c cols rows values =
    let
        flat =
            List.concat values

        lo =
            List.minimum flat |> Maybe.withDefault 0

        hi =
            List.maximum flat |> Maybe.withDefault 1

        span =
            if hi == lo then
                1

            else
                hi - lo

        cellW =
            plotW c / toFloat (Basics.max 1 (List.length cols))

        cellH =
            plotH c / toFloat (Basics.max 1 (List.length rows))

        cell i j v =
            Svg.rect
                [ SA.x (Scale.num (c.left + cellW * toFloat j))
                , SA.y (Scale.num (c.top + cellH * toFloat i))
                , SA.width (Scale.num (cellW + 0.5))
                , SA.height (Scale.num (cellH + 0.5))
                , SA.fill (Scale.interpolateColor c.grid c.color ((v - lo) / span))
                ]
                (tip c (itemAt i rows ++ " / " ++ itemAt j cols ++ ": " ++ Scale.num v))

        cells =
            List.concat (List.indexedMap (\i rowVals -> List.indexedMap (cell i) rowVals) values)

        colLabels =
            List.indexedMap (\j name -> valueLabel c (c.left + cellW * (toFloat j + 0.5)) (c.top + plotH c + 12) (clip name)) cols

        rowLabels =
            List.indexedMap (\i name -> tickLabel c (c.left - 4) (c.top + cellH * (toFloat i + 0.5) + 3) (clip name)) rows
    in
    root c (cells ++ colLabels ++ rowLabels)


{-| A sparkline: a tiny, axis-less line that fills the whole `Config` size, with a dot on the last
point. Made for inline use in tables and dense dashboards — size it small with [`sized`](#sized).
-}
sparkline : Config -> List Float -> Svg msg
sparkline c values =
    let
        n =
            List.length values

        pad =
            2

        xS =
            Scale.linear ( 0, toFloat (Basics.max 1 (n - 1)) ) ( pad, c.width - pad )

        lo =
            List.minimum values |> Maybe.withDefault 0

        hi =
            List.maximum values |> Maybe.withDefault 1

        yS =
            Scale.linear
                (if lo == hi then
                    ( lo - 1, hi + 1 )

                 else
                    ( lo, hi )
                )
                ( c.height - pad, pad )

        pts =
            List.indexedMap (\i v -> ( Scale.convert xS (toFloat i), Scale.convert yS v )) values

        lastDot =
            case List.reverse pts of
                p :: _ ->
                    [ dot c c.color c.dotR p "" ]

                [] ->
                    []
    in
    root c (strokeLine c c.color (linePoints c pts) :: lastDot)


{-| A waterfall chart of `(label, delta)` steps: each bar floats from the running total to the new
total, green for a rise and red for a fall, with connectors between them. Good for bridging a start
value to an end value through its contributions.
-}
waterfall : Config -> List ( String, Float ) -> Svg msg
waterfall c data =
    let
        deltas =
            List.map Tuple.second data

        -- (start level, end level) for each bar, walking the running total from zero
        levels =
            Tuple.first (List.foldl (\d ( acc, t ) -> ( acc ++ [ ( t, t + d ) ], t + d )) ( [], 0 ) deltas)

        zipped =
            List.map2 Tuple.pair data levels

        yS =
            yScaleFor c (0 :: List.concatMap (\( s, e ) -> [ s, e ]) levels)

        count =
            List.length data

        slot =
            plotW c / toFloat (Basics.max 1 count)

        barW =
            slot * 0.6

        cxOf i =
            c.left + slot * (toFloat i + 0.5)

        bar i ( ( lbl, d ), ( s, e ) ) =
            let
                ys =
                    Scale.convert yS s

                ye =
                    Scale.convert yS e

                color =
                    if d >= 0 then
                        "#0f9d58"

                    else
                        "#d6336c"

                sign =
                    if d >= 0 then
                        "+"

                    else
                        ""
            in
            Svg.g []
                [ Svg.rect
                    [ SA.x (Scale.num (cxOf i - barW / 2)), SA.y (Scale.num (Basics.min ys ye)), SA.width (Scale.num barW), SA.height (Scale.num (Basics.max 0.5 (abs (ys - ye)))), SA.fill color ]
                    (tip c (lbl ++ ": " ++ sign ++ c.format d ++ " (= " ++ c.format e ++ ")"))
                , xLabel c count (cxOf i) lbl
                ]

        connector i ( _, ( _, e ) ) =
            if i < count - 1 then
                [ Svg.line [ SA.x1 (Scale.num (cxOf i + barW / 2)), SA.y1 (Scale.num (Scale.convert yS e)), SA.x2 (Scale.num (cxOf (i + 1) - barW / 2)), SA.y2 (Scale.num (Scale.convert yS e)), SA.stroke c.axis, SA.strokeWidth "1" ] [] ]

            else
                []
    in
    root c (frame c yS ++ List.concat (List.indexedMap connector zipped) ++ List.indexedMap bar zipped)


{-| A gauge (KPI dial): `value` shown as a filled arc on a half-ring scaled from `lo` to `hi`, with
the value read out in the middle. For a single headline number on a dashboard.
-}
gauge : Config -> Float -> Float -> Float -> Svg msg
gauge c lo hi value =
    let
        cx =
            c.left + plotW c / 2

        cy =
            c.top + plotH c * 0.74

        outerR =
            Basics.min (plotW c / 2 - 6) (cy - c.top - 4)

        innerR =
            outerR * 0.6

        center =
            ( cx, cy )

        startA =
            1.5 * pi

        t =
            clamp 0
                1
                (if hi == lo then
                    0

                 else
                    (value - lo) / (hi - lo)
                )

        arc color from to =
            Svg.polyline [ SA.points (Scale.pointsString (Arc.ringPoints center innerR outerR from to)), SA.fill color, SA.stroke "none" ] []
    in
    root c
        [ arc c.grid startA (startA + pi)
        , arc c.color startA (startA + t * pi)
        , Svg.text_
            [ SA.x (Scale.num cx), SA.y (Scale.num (cy - outerR * 0.12)), SA.fill c.label, SA.fontFamily c.font, SA.fontSize (Scale.num (c.fontSize * 2.2)), SA.textAnchor "middle" ]
            [ Svg.text (c.format value) ]
        , valueLabel c (cx - (outerR + innerR) / 2) (cy + 12) (c.format lo)
        , valueLabel c (cx + (outerR + innerR) / 2) (cy + 12) (c.format hi)
        ]


{-| A lollipop chart of `(label, value)` pairs — a thin stem topped with a dot. A lighter-weight
alternative to [`bars`](#bars) when the bar area would be more ink than the data needs.
-}
lollipop : Config -> List ( String, Float ) -> Svg msg
lollipop c data =
    let
        yS =
            yScaleFor c (List.map Tuple.second data)

        count =
            List.length data

        slot =
            plotW c / toFloat (Basics.max 1 count)

        zeroY =
            Scale.convert yS 0

        stem i ( lbl, v ) =
            let
                cx =
                    c.left + slot * (toFloat i + 0.5)

                y =
                    Scale.convert yS v
            in
            Svg.g []
                [ Svg.line [ SA.x1 (Scale.num cx), SA.y1 (Scale.num zeroY), SA.x2 (Scale.num cx), SA.y2 (Scale.num y), SA.stroke c.color, SA.strokeWidth "2" ] []
                , dot c c.color (c.dotR * 1.9) ( cx, y ) (lbl ++ ": " ++ c.format v)
                , xLabel c count cx lbl
                ]
    in
    root c (frame c yS ++ List.indexedMap stem data)


{-| Like [`stackedBars`](#stackedBars) but each category is normalised to 100%, so the bars compare
the *composition* of each category rather than its total. Same `(label, [(series, value)])` data.
-}
percentBars : Config -> List ( String, List ( String, Float ) ) -> Svg msg
percentBars c data =
    let
        normalize ( lbl, segs ) =
            let
                total =
                    List.sum (List.map Tuple.second segs)

                t =
                    if total == 0 then
                        1

                    else
                        total
            in
            ( lbl, List.map (\( n, v ) -> ( n, v / t * 100 )) segs )

        normed =
            List.map normalize data

        cPct =
            { c | format = \v -> Scale.num v ++ "%" }

        yS =
            Scale.linear ( 0, 100 ) ( c.top + plotH c, c.top )

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
            ( cum + v
            , acc
                ++ [ Svg.rect
                        [ SA.x (Scale.num (cx - barW / 2)), SA.y (Scale.num (Scale.convert yS (cum + v))), SA.width (Scale.num barW), SA.height (Scale.num (Basics.max 0.5 (abs (Scale.convert yS cum - Scale.convert yS (cum + v))))), SA.fill (colorAt j) ]
                        (tip c (name ++ ": " ++ Scale.num v ++ "%"))
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
    root c (frame cPct yS ++ List.indexedMap bar normed ++ [ legend c seriesNames ])


{-| A slope chart comparing each `(label, before, after)` across two periods (named `leftName` and
`rightName`): a line per item between its two values, green if it rose and red if it fell. Good for
showing rank or value changes between two points in time.
-}
slope : Config -> String -> String -> List ( String, Float, Float ) -> Svg msg
slope c leftName rightName data =
    let
        yS =
            yScaleRaw c (List.concatMap (\( _, a, b ) -> [ a, b ]) data)

        leftX =
            c.left + plotW c * 0.2

        rightX =
            c.left + plotW c * 0.8

        endText anchor x y txt =
            Svg.text_ [ SA.x (Scale.num x), SA.y (Scale.num y), SA.fill c.label, SA.fontFamily c.font, SA.fontSize (Scale.num c.fontSize), SA.textAnchor anchor ] [ Svg.text txt ]

        row ( lbl, a, b ) =
            let
                ya =
                    Scale.convert yS a

                yb =
                    Scale.convert yS b

                color =
                    if b > a then
                        "#0f9d58"

                    else if b < a then
                        "#d6336c"

                    else
                        c.axis

                txt =
                    lbl ++ ": " ++ c.format a ++ " → " ++ c.format b
            in
            Svg.g []
                [ Svg.line [ SA.x1 (Scale.num leftX), SA.y1 (Scale.num ya), SA.x2 (Scale.num rightX), SA.y2 (Scale.num yb), SA.stroke color, SA.strokeWidth (Scale.num c.stroke) ] []
                , dot c color c.dotR ( leftX, ya ) txt
                , dot c color c.dotR ( rightX, yb ) txt
                , endText "end" (leftX - 6) (ya + 3) (clip lbl)
                , endText "start" (rightX + 6) (yb + 3) (c.format b)
                ]

        headers =
            [ endText "middle" leftX (c.top - 4) leftName
            , endText "middle" rightX (c.top - 4) rightName
            ]
    in
    root c (headers ++ List.map row data)


{-| A scatter plot of `(x, y, error)` points, each with a vertical error bar spanning `y ± error`. -}
scatterErr : Config -> List ( Float, Float, Float ) -> Svg msg
scatterErr c data =
    let
        ( xlo, xhi ) =
            Scale.niceBoundsRounded 5 (Scale.niceBounds (List.map (\( x, _, _ ) -> x) data))

        xS =
            Scale.linear ( xlo, xhi ) ( c.left, c.left + plotW c )

        yS =
            yScaleFor c (List.concatMap (\( _, y, e ) -> [ y - e, y + e ]) data)

        mark ( x, y, e ) =
            let
                px =
                    Scale.convert xS x

                top =
                    Scale.convert yS (y + e)

                bot =
                    Scale.convert yS (y - e)
            in
            Svg.g []
                [ Svg.line [ SA.x1 (Scale.num px), SA.y1 (Scale.num top), SA.x2 (Scale.num px), SA.y2 (Scale.num bot), SA.stroke c.color, SA.strokeWidth "1" ] []
                , Svg.line [ SA.x1 (Scale.num (px - 3)), SA.y1 (Scale.num top), SA.x2 (Scale.num (px + 3)), SA.y2 (Scale.num top), SA.stroke c.color, SA.strokeWidth "1" ] []
                , Svg.line [ SA.x1 (Scale.num (px - 3)), SA.y1 (Scale.num bot), SA.x2 (Scale.num (px + 3)), SA.y2 (Scale.num bot), SA.stroke c.color, SA.strokeWidth "1" ] []
                , dot c c.color c.dotR ( px, Scale.convert yS y ) ("(" ++ Scale.num x ++ ", " ++ Scale.num y ++ " ± " ++ Scale.num e ++ ")")
                ]
    in
    root c (frame c yS ++ xAxis c xS ++ List.map mark data)


{-| A treemap of `(label, value)` pairs: nested rectangles whose areas are proportional to the
values (largest first), tiled by the pure [`Layout`](Layout) module. Cells big enough are labelled;
hover any cell for its value.
-}
treemap : Config -> List ( String, Float ) -> Svg msg
treemap c data =
    let
        sorted =
            List.sortBy (\( _, v ) -> -v) data

        rects =
            Layout.treemap ( c.left, c.top, plotW c, plotH c ) (List.map Tuple.second sorted)

        border =
            if c.background == "none" then
                "#ffffff"

            else
                c.background

        cell i ( ( lbl, v ), ( x, y, w, h ) ) =
            Svg.g []
                [ Svg.rect
                    [ SA.x (Scale.num x), SA.y (Scale.num y), SA.width (Scale.num w), SA.height (Scale.num h), SA.fill (colorAt i), SA.stroke border, SA.strokeWidth "1" ]
                    (tip c (lbl ++ ": " ++ c.format v))
                , if w > 34 && h > 14 then
                    Svg.text_
                        [ SA.x (Scale.num (x + 4)), SA.y (Scale.num (y + 13)), SA.fill "#ffffff", SA.fontFamily c.font, SA.fontSize (Scale.num c.fontSize) ]
                        [ Svg.text (clip lbl) ]

                  else
                    Svg.text ""
                ]
    in
    root c (List.indexedMap cell (List.map2 Tuple.pair sorted rects))


{-| A funnel chart of `(label, value)` stages: centred bars whose width tracks each stage's value,
narrowing down the page. Tooltips show each stage's share of the first. Good for conversion flows.
-}
funnel : Config -> List ( String, Float ) -> Svg msg
funnel c data =
    let
        values =
            List.map Tuple.second data

        maxV =
            Basics.max 1.0e-9 (List.maximum values |> Maybe.withDefault 1)

        first =
            Basics.max 1.0e-9 (List.head values |> Maybe.withDefault maxV)

        count =
            List.length data

        rowH =
            plotH c / toFloat (Basics.max 1 count)

        barH =
            rowH * 0.74

        cx =
            c.left + plotW c / 2

        stage i ( lbl, v ) =
            let
                w =
                    plotW c * (v / maxV)

                y =
                    c.top + rowH * toFloat i + (rowH - barH) / 2
            in
            Svg.g []
                [ Svg.rect
                    [ SA.x (Scale.num (cx - w / 2)), SA.y (Scale.num y), SA.width (Scale.num w), SA.height (Scale.num barH), SA.fill (colorAt i) ]
                    (tip c (lbl ++ ": " ++ c.format v ++ " (" ++ Scale.num (v / first * 100) ++ "% of first)"))
                , Svg.text_
                    [ SA.x (Scale.num cx), SA.y (Scale.num (y + barH * 0.64)), SA.fill "#ffffff", SA.fontFamily c.font, SA.fontSize (Scale.num c.fontSize), SA.textAnchor "middle" ]
                    [ Svg.text (clip lbl ++ "  " ++ c.format v) ]
                ]
    in
    root c (List.indexedMap stage data)


{-| A Gantt chart of `(label, start, end)` tasks: a horizontal bar per task spanning its interval on
a shared time axis, with the task labels down the left. -}
gantt : Config -> List ( String, Float, Float ) -> Svg msg
gantt c data =
    let
        lo =
            List.minimum (List.map (\( _, s, _ ) -> s) data) |> Maybe.withDefault 0

        hi =
            List.maximum (List.map (\( _, _, e ) -> e) data) |> Maybe.withDefault 1

        xS =
            Scale.linear
                (if lo == hi then
                    ( lo, lo + 1 )

                 else
                    ( lo, hi )
                )
                ( c.left, c.left + plotW c )

        count =
            List.length data

        slot =
            plotH c / toFloat (Basics.max 1 count)

        barH =
            slot * 0.6

        bar i ( lbl, s, e ) =
            let
                cy =
                    c.top + slot * (toFloat i + 0.5)

                x0 =
                    Scale.convert xS s

                x1 =
                    Scale.convert xS e
            in
            Svg.g []
                [ Svg.rect
                    [ SA.x (Scale.num (Basics.min x0 x1)), SA.y (Scale.num (cy - barH / 2)), SA.width (Scale.num (Basics.max 1 (abs (x1 - x0)))), SA.height (Scale.num barH), SA.fill (colorAt i) ]
                    (tip c (lbl ++ ": " ++ c.format s ++ "–" ++ c.format e))
                , tickLabel c (c.left - 5) (cy + 3) (clip lbl)
                ]
    in
    root c (xAxis c xS ++ [ axisLine c c.left c.top c.left (c.top + plotH c) ] ++ List.indexedMap bar data)


{-| A dumbbell (range) chart of `(label, low, high)` rows: a connecting bar between a low dot and a
high dot per category, with a low/high legend. Good for comparing two values or showing a range. -}
dumbbell : Config -> List ( String, Float, Float ) -> Svg msg
dumbbell c data =
    let
        ( lo, hi ) =
            Scale.niceBoundsRounded 5 (Scale.niceBounds (List.concatMap (\( _, l, h ) -> [ l, h ]) data))

        xS =
            Scale.linear ( lo, hi ) ( c.left, c.left + plotW c )

        count =
            List.length data

        slot =
            plotH c / toFloat (Basics.max 1 count)

        row i ( lbl, low, high ) =
            let
                cy =
                    c.top + slot * (toFloat i + 0.5)

                xl =
                    Scale.convert xS low

                xh =
                    Scale.convert xS high
            in
            Svg.g []
                [ Svg.line [ SA.x1 (Scale.num xl), SA.y1 (Scale.num cy), SA.x2 (Scale.num xh), SA.y2 (Scale.num cy), SA.stroke c.axis, SA.strokeWidth "2" ] []
                , dot c (colorAt 0) (c.dotR * 1.6) ( xl, cy ) (lbl ++ " low: " ++ c.format low)
                , dot c (colorAt 1) (c.dotR * 1.6) ( xh, cy ) (lbl ++ " high: " ++ c.format high)
                , tickLabel c (c.left - 5) (cy + 3) (clip lbl)
                ]
    in
    root c
        (xAxis c xS
            ++ [ axisLine c c.left c.top c.left (c.top + plotH c) ]
            ++ List.indexedMap row data
            ++ [ legend c [ "low", "high" ] ]
        )


{-| A Pareto chart of `(label, value)` pairs: bars sorted largest-first against the left axis, with
a cumulative-percentage line against a right (0–100%) axis — the classic "80/20" view. -}
pareto : Config -> List ( String, Float ) -> Svg msg
pareto c data =
    let
        sorted =
            List.sortBy (\( _, v ) -> -v) data

        values =
            List.map Tuple.second sorted

        total =
            Basics.max 1.0e-9 (List.sum values)

        count =
            List.length sorted

        yS =
            yScaleFor c values

        yS2 =
            Scale.linear ( 0, 100 ) ( c.top + plotH c, c.top )

        slot =
            plotW c / toFloat (Basics.max 1 count)

        barW =
            slot * 0.64

        right =
            c.left + plotW c

        cumPct =
            Tuple.first (List.foldl (\v ( acc, run ) -> ( acc ++ [ (run + v) / total * 100 ], run + v )) ( [], 0 ) values)

        cxOf i =
            c.left + slot * (toFloat i + 0.5)

        bar i ( lbl, v ) =
            Svg.g []
                [ Svg.rect
                    [ SA.x (Scale.num (cxOf i - barW / 2)), SA.y (Scale.num (Scale.convert yS v)), SA.width (Scale.num barW), SA.height (Scale.num (Basics.max 0.5 (Scale.convert yS 0 - Scale.convert yS v))), SA.fill c.color ]
                    (tip c (lbl ++ ": " ++ c.format v))
                , xLabel c count (cxOf i) lbl
                ]

        linePts =
            List.indexedMap (\i p -> ( cxOf i, Scale.convert yS2 p )) cumPct

        rightTick p =
            Svg.text_
                [ SA.x (Scale.num (right + 4)), SA.y (Scale.num (Scale.convert yS2 p + 3)), SA.fill (colorAt 1), SA.fontFamily c.font, SA.fontSize (Scale.num c.fontSize), SA.textAnchor "start" ]
                [ Svg.text (Scale.num p ++ "%") ]
    in
    root c
        (frame c yS
            ++ [ axisLine c right c.top right (c.top + plotH c) ]
            ++ List.map rightTick [ 0, 25, 50, 75, 100 ]
            ++ List.indexedMap bar sorted
            ++ (strokeLine c (colorAt 1) linePts :: List.map (\p -> dot c (colorAt 1) c.dotR p "") linePts)
        )


{-| A polar-area (rose / Nightingale) chart of `(label, value)` slices: equal angles, but each
slice's **radius** tracks its value. A legend names the slices. -}
rose : Config -> List ( String, Float ) -> Svg msg
rose c data =
    let
        maxV =
            Basics.max 1.0e-9 (List.maximum (List.map Tuple.second data) |> Maybe.withDefault 1)

        n =
            List.length data

        center =
            ( c.left + plotW c / 2, c.top + plotH c / 2 )

        maxR =
            Basics.min (plotW c) (plotH c) / 2 * 0.9

        step =
            if n == 0 then
                Arc.tau

            else
                Arc.tau / toFloat n

        slice i ( lbl, v ) =
            let
                start =
                    step * toFloat i
            in
            Svg.polyline
                [ SA.points (Scale.pointsString (Arc.wedgePoints center (maxR * (v / maxV)) start (start + step)))
                , SA.fill (colorAt i)
                , SA.fillOpacity "0.75"
                , SA.stroke c.background
                , SA.strokeWidth "1"
                ]
                (tip c (lbl ++ ": " ++ c.format v))
    in
    root c (List.indexedMap slice data ++ [ legend c (List.map Tuple.first data) ])


{-| A radial bar chart of `(label, value)` pairs: concentric arcs, one ring per category, each arc's
sweep proportional to its value over a 270° track (reuses [`Arc`](Arc)). A legend names the rings. -}
radialBars : Config -> List ( String, Float ) -> Svg msg
radialBars c data =
    let
        maxV =
            Basics.max 1.0e-9 (List.maximum (List.map Tuple.second data) |> Maybe.withDefault 1)

        n =
            List.length data

        center =
            ( c.left + plotW c / 2, c.top + plotH c / 2 )

        outerR =
            Basics.min (plotW c) (plotH c) / 2 * 0.94

        unit =
            outerR / toFloat (Basics.max 1 n)

        ringW =
            unit * 0.78

        sweepMax =
            1.5 * pi

        bar i ( lbl, v ) =
            let
                rOuter =
                    outerR - toFloat i * unit

                rInner =
                    rOuter - ringW
            in
            Svg.g []
                [ Svg.polyline [ SA.points (Scale.pointsString (Arc.ringPoints center rInner rOuter 0 sweepMax)), SA.fill c.grid, SA.stroke "none" ] []
                , Svg.polyline [ SA.points (Scale.pointsString (Arc.ringPoints center rInner rOuter 0 (v / maxV * sweepMax))), SA.fill (colorAt i), SA.stroke "none" ] (tip c (lbl ++ ": " ++ c.format v))
                ]
    in
    root c (List.indexedMap bar data ++ [ legend c (List.map Tuple.first data) ])


{-| A bullet chart (Stephen Few's compact KPI): a measure bar for `value` over qualitative `bands`
(ascending thresholds within `0…max`, shaded grid→axis), with a tick marking the `target`. -}
bullet : Config -> { value : Float, target : Float, max : Float, bands : List Float } -> Svg msg
bullet c spec =
    let
        maxV =
            Basics.max 1.0e-9 spec.max

        xS =
            Scale.linear ( 0, maxV ) ( c.left, c.left + plotW c )

        midY =
            c.top + plotH c / 2

        trackH =
            plotH c * 0.5

        top_ =
            midY - trackH / 2

        edges =
            0 :: (spec.bands ++ [ maxV ])

        pairs =
            List.map2 Tuple.pair edges (List.drop 1 edges)

        nz =
            Basics.max 1 (List.length pairs - 1)

        zone i ( lo, hi ) =
            Svg.rect
                [ SA.x (Scale.num (Scale.convert xS lo)), SA.y (Scale.num top_), SA.width (Scale.num (Basics.max 0.5 (Scale.convert xS hi - Scale.convert xS lo))), SA.height (Scale.num trackH), SA.fill (Scale.interpolateColor c.grid c.axis (toFloat i / toFloat nz)) ]
                []
    in
    root c
        (List.indexedMap zone pairs
            ++ [ Svg.rect
                    [ SA.x (Scale.num c.left), SA.y (Scale.num (midY - trackH * 0.18)), SA.width (Scale.num (Basics.max 0.5 (Scale.convert xS spec.value - c.left))), SA.height (Scale.num (trackH * 0.36)), SA.fill c.color ]
                    (tip c ("value " ++ c.format spec.value ++ " / target " ++ c.format spec.target))
               , Svg.line
                    [ SA.x1 (Scale.num (Scale.convert xS spec.target)), SA.y1 (Scale.num (top_ - 2)), SA.x2 (Scale.num (Scale.convert xS spec.target)), SA.y2 (Scale.num (top_ + trackH + 2)), SA.stroke c.label, SA.strokeWidth "2.5" ]
                    []
               , Svg.text_
                    [ SA.x (Scale.num (Scale.convert xS spec.value + 4)), SA.y (Scale.num (midY + 3)), SA.fill c.label, SA.fontFamily c.font, SA.fontSize (Scale.num c.fontSize), SA.textAnchor "start" ]
                    [ Svg.text (c.format spec.value) ]
               , valueLabel c c.left (top_ + trackH + 13) (c.format 0)
               , valueLabel c (c.left + plotW c) (top_ + trackH + 13) (c.format maxV)
               ]
        )



-- BUILDING BLOCKS ------------------------------------------------------------


{-| The plot furniture for a chart with the given Y scale: gridlines, tick labels, the Y axis, a
zero baseline (only when zero is in range), any reference marks and titles set on the `Config`.
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

        dLo =
            Basics.min yS.d0 yS.d1

        dHi =
            Basics.max yS.d0 yS.d1

        zeroLine =
            if 0 >= dLo && 0 <= dHi then
                [ axisLine c left zeroY right zeroY ]

            else
                []

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
                ++ [ tickLabel c (left - 5) (y + 3) (c.format v) ]

        tickVals =
            case c.yDomain of
                Just ( lo, hi ) ->
                    Scale.ticks c.yTicks ( lo, hi )

                Nothing ->
                    Scale.niceTicks c.yTicks ( yS.d0, yS.d1 )
    in
    List.concatMap gridFor tickVals
        ++ refMarks c yS
        ++ [ axisLine c left c.top left (c.top + plotH c) ]
        ++ zeroLine
        ++ titles c


{-| The reference lines and bands set on the `Config`, drawn across the plot at their Y values. -}
refMarks : Config -> Scale -> List (Svg msg)
refMarks c yS =
    let
        left =
            c.left

        right =
            c.left + plotW c

        draw r =
            if r.band then
                let
                    y0 =
                        Scale.convert yS r.hi

                    y1 =
                        Scale.convert yS r.lo
                in
                [ Svg.rect
                    [ SA.x (Scale.num left)
                    , SA.y (Scale.num (Basics.min y0 y1))
                    , SA.width (Scale.num (right - left))
                    , SA.height (Scale.num (abs (y1 - y0)))
                    , SA.fill r.color
                    , SA.fillOpacity "0.1"
                    ]
                    []
                , refLabel c (right - 3) (Basics.min y0 y1 + 9) r.color r.label
                ]

            else
                let
                    y =
                        Scale.convert yS r.lo
                in
                [ Svg.line
                    [ SA.x1 (Scale.num left), SA.y1 (Scale.num y), SA.x2 (Scale.num right), SA.y2 (Scale.num y), SA.stroke r.color, SA.strokeWidth "1", SA.strokeDasharray "4 3" ]
                    []
                , refLabel c (right - 3) (y - 3) r.color r.label
                ]
    in
    List.concatMap draw c.refs


refLabel : Config -> Float -> Float -> String -> String -> Svg msg
refLabel c x y color txt =
    Svg.text_
        [ SA.x (Scale.num x), SA.y (Scale.num y), SA.fill color, SA.fontFamily c.font, SA.fontSize (Scale.num c.fontSize), SA.textAnchor "end" ]
        [ Svg.text txt ]


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


itemAt : Int -> List String -> String
itemAt i xs =
    List.head (List.drop i xs) |> Maybe.withDefault ""


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
