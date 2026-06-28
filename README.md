# elm-svg

A small, **dependency-free SVG charting library** in Elm, for the
[elm-lang](https://github.com/tunguski/elm-lang) compiler.

Live site: **https://tunguski.github.io/elm-svg/** — a small **workspace** where you create and
manage your own charts (saved in your browser): name / open / search / copy / delete them, set
sharing & permissions, comment, and export their data to CSV / JSON. That whole experience comes
from the reusable [elm-workspace](https://github.com/tunguski/elm-workspace) library (vendored under
`vendor/`); the chart **document** and its live editor are this repo, drawn with `Chart` below.

One call gives you a chart:

```elm
import Chart

-- category charts: List ( String, Float )
Chart.bars Chart.defaults [ ( "Jan", 120 ), ( "Feb", 98 ), ( "Mar", 145 ) ]
Chart.line Chart.defaults temps           -- (label, value) with a zero baseline
Chart.area Chart.defaults sales           -- a line, filled to the baseline
Chart.pie Chart.defaults share            -- slices summing to the whole
Chart.donut (Chart.withInner 0.6 Chart.defaults) share

Chart.hbars Chart.defaults ranking      -- horizontal bars (long labels / rankings)
Chart.histogram Chart.defaults numbers  -- bins a raw List Float into a distribution

-- point / multi-series charts
Chart.scatter Chart.defaults points       -- raw (x, y)
Chart.bubble Chart.defaults xysize        -- List ( Float, Float, Float ) — area = size
Chart.multiLine Chart.defaults serieses   -- List ( String, List (Float, Float) ), with a legend
Chart.stackedArea Chart.defaults serieses
Chart.radar Chart.defaults axes serieses  -- spider chart over shared axes

-- segmented bars: List ( String, List ( String, Float ) ) — (category, [(series, value)])
Chart.stackedBars Chart.defaults revenue
Chart.groupedBars Chart.defaults revenue
```

Each function returns an `Svg msg` you drop straight into a page. Numeric axes draw **1·2·5
gridlines** and tick labels (X and Y); multi-series charts draw a **legend**; every mark carries a
native `<title>` **hover tooltip** (no Elm state). Line and area series can be **smoothed** into a
Catmull-Rom curve with `Chart.withCurve True`. The number-crunching — domain→pixel mapping (linear
or **log**), bounds and ticks, coordinate formatting, slicing a circle, binning a sample, blending
colours, spline smoothing — lives in separate, fully unit-tested
[`Scale`](src/Scale.elm), [`Arc`](src/Arc.elm) and [`Curve`](src/Curve.elm) modules.

## Theming

The `Config` carries a small theme. Build it through the composable constructors (never
`{ Chart.defaults | … }` — see the gotchas below):

```elm
Chart.sized 460 260
    |> Chart.darken                       -- dark theme, keeping the size
    |> Chart.withTitle "Quarterly revenue"
    |> Chart.withAxisTitles "quarter" "£k"
    |> Chart.withValues True              -- value labels on bars
    |> Chart.withGrid False               -- hide the gridlines
```

## Modules

- **`Scale`** — linear **and log** scales (`linear` / `log` / `convert` / `invert`), bounds and
  ticks (`niceBounds`, `ticks`, and the rounded `niceNum` / `niceTicks` / `niceBoundsRounded`),
  histogram `binCounts`, colour `interpolateColor`, and coordinate formatting (`num` / `point` /
  `pointsString`). No SVG, so it is exhaustively tested.
- **`Arc`** — the pie/donut maths: `slices` (values → angular slices) and `wedgePoints` /
  `ringPoints` (slices → polygon point-lists). Also pure and tested.
- **`Curve`** — `smooth` / `catmullRom`: a point list → a smooth spline sampled as points (so a
  plain `<polyline>` renders the curve). Pure and tested.
- **`Chart`** — `bars`, `hbars`, `line`, `area`, `scatter`, `bubble`, `multiLine`, `stackedArea`,
  `stackedBars`, `groupedBars`, `histogram`, `pie`, `donut`, `radar` over plain Elm data; the
  `Config` theme constructors (`sized`, `darken`, `withColor`, `withGrid`, `withValues`, `withTitle`,
  `withAxisTitles`, `withInner`, `withCurve`, `withTips`); and the building blocks (`frame`, `xAxis`,
  `legend`, `polylineOf`, `dotsOf`) for bespoke charts.

## Gotchas it bakes in

This library targets the elm-lang JS backend, and encodes a few of its quirks so you don't trip
on them:

- **`Svg.Attributes.class` is unbound**, so SVG nodes can't be styled by CSS class — every colour
  is set **inline** from the [`Config`](src/Chart.elm). Pass colours through the config.
- **A record update on a record alias imported from another module miscompiles** (the un-updated
  fields come back `undefined`). So tweak a `Config` with the provided constructors —
  `Chart.sized w h`, `Chart.darken`, `Chart.withGrid on` — which do the update *inside* `Chart`,
  rather than `{ Chart.defaults | width = … }` at your own call site. The `with*` constructors take
  a `Config` and return one, so they chain with `|>`.
- **`let` bindings are evaluated in source order, without hoisting.** A binding that is built
  eagerly (e.g. `List.indexedMap …`) may not reference a *later* binding in the same `let` — at
  evaluation time that name is still `undefined` and you get a runtime `reading 'n'` crash. Define
  helpers **above** the bindings that use them.

Pie, donut and radar areas are drawn as filled `<polyline>`s (which close themselves under `fill`),
sidestepping the unbound `<path>` element rather than relying on arc path commands.

## Use it in another project

Each elm-lang project is its own repo, so reuse is by **vendoring**: copy `src/Scale.elm`,
`src/Arc.elm` and `src/Chart.elm` into your project's source path and import `Chart`. (This is how
`elm-notebook` draws its cell charts.)

## Develop

With this repo checked out next to a built [`elm-lang`](https://github.com/tunguski/elm-lang)
(so `../../elm.sh` exists):

```sh
ELM=../../elm.sh ./test.sh     # run the headless Scale test suite
ELM=../../elm.sh ./build.sh    # compile the demo gallery → build/elm-svg.html
```

`.github/workflows/pages.yml` runs the same in CI and deploys to GitHub Pages, gated on the
tests passing.

Part of the [elm-lang](https://github.com/tunguski/elm-lang) ecosystem.
