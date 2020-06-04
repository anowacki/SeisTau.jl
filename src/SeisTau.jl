"""
# SeisTau

SeisTau integrates the [TauPy](https://github.com/anowacki/TauPy.jl) and
[Seis](https://github.com/anowacki/Seis.jl) packages, allowing one to easily
use seismic travel time predictions for 1D Earth models with `Seis.Trace`s,
`Seis.Event`s and `Seis.Station`s.
"""
module SeisTau

import Seis
using Seis: AbstractTrace, GeogEvent, GeogStation, distance_deg, picks
import TauPy

export
    path,
    travel_time,
    travel_times

"""
    add_pick!(t, p::TauPy.Phase, name=p.name) -> (time, name)

Add a travel time pick to the `Trace` `t` from a `TauPy.Phase` arrival.

The pick name will be taken from the phase name by default.
"""
Seis.add_pick!(t::AbstractTrace, p::Union{TauPy.Phase,TauPy.PhaseGeog},
    name=p.name) = add_pick!(t, p.time, name)

"""
    add_picks!(t, phase; model="iasp91", exact=false, sphere=false)

Add travel time picks to the trace `t` for the 1D Earth `model`, for arrivals
with a name matching `phase`.

If `exact` is `true`, only phases which are an exact match for `phase` will
be added.  If `sphere` is `true`, then assume the Earth is spherical.

Available models are: $(TauPy.available_models()).
"""
function Seis.add_picks!(t::AbstractTrace, phase::AbstractString="ttall";
        model="iasp91", exact=false, sphere=false)
    _check_headers_taup(t)
    arrivals = travel_time(t, phase; model=model, sphere=sphere)
    for arr in arrivals
        exact && arr.name != phase && continue
        Seis.add_pick!(t, arr.time, arr.name)
    end
    t.picks
end

"""
    path(t, phase="all"; model="iasp91", exact=false, kwargs...) -> phases::Vector{TauPy.PhaseGeog}

Return ray paths for the geometry specified in the `Trace` t for the 1D Earth `model`,
for arrivals with a name matching `phase`.

If `exact` is `true`, then only return phases whose names are an exact match for `phase`.

    path(event, station, phase="ttall"; kwargs...)

Compute paths for individual `event`s and `station`s instead of taking
these from a `Trace`.

Available models are: $(TauPy.available_models()).

Note that TauPy only computes geographic paths for a spherical Earth.
"""
function path(evt::GeogEvent, sta::GeogStation, phase="ttall";
        model="iasp91", exact=false, kwargs...)
    _check_headers_taup(evt, sta)
    arrivals = TauPy.path(evt.lon, evt.lat, evt.dep, sta.lon, sta.lat, phase; model=model, kwargs...)
    exact && filter!(arr -> arr.name == phase, arrivals)
    arrivals
end

path(t::AbstractTrace, phase="ttall"; kwargs...) = path(t.evt, t.sta, phase; kwargs...)

"""
    travel_time(t, phase="ttall"; model="iasp91", sphere=false) -> phases::Vector{TauPy.Phase}

Return travel times for the geometry specified in the `Trace` `t` for the 1D
Earth `model`, for arrivals with a name matching `phase`.

If `exact` is `true`, then only return phases whose names are an exact match for `phase`.

    travel_time(event, station, phase="all"; kwargs...)

Compute travel times for individual `event`s and `station`s instead of taking
these from a `Trace`.

Available models are: $(TauPy.available_models()).
"""
travel_time(t::AbstractTrace, phase="ttall"; kwargs...) = travel_time(t.evt, t.sta, phase; kwargs...)

function travel_time(evt::GeogEvent, sta::GeogStation, phase::AbstractString="ttall";
        model="iasp91", exact=false, sphere=false, kwargs...)
    _check_headers_taup(evt, sta)
    arrivals = TauPy.travel_time(evt.dep, distance_deg(evt, sta, sphere=sphere), phase; model=model, kwargs...)
    exact && filter!(arr -> arr.name == phase, arrivals)
    arrivals
end

"""
    travel_times(t; model="iasp91", sphere=false) -> ::Vector{Vector{TauPy.Phase}}

Return the list of `TauPy.Phase`s associated with each travel time pick in `t`.
"""
travel_times(t::AbstractTrace; model::AbstractString="iasp91", sphere=false) =
    [travel_time(t, name; model=model, sphere=sphere)
     for (_, name) in picks(t) if name !== missing && occursin(r"^[psPS]", name)]

"Throw an error if a Trace doesn't contain the right headers to call TauPy.travel_time."
_check_headers_taup(evt::GeogEvent, sta::GeogStation) = any(ismissing,
    (evt.lon, evt.lat, evt.dep, sta.lon, sta.lat)) &&
    throw(ArgumentError("Insufficient information in trace to compute travel times." *
                        "  (Need: evt.lon, evt.lat, evt.dep, sta.lon and sta.lat)")) ||
    nothing

_check_headers_taup(t::AbstractTrace) = _check_headers_taup(t.evt, t.sta)

end # module
