"""
# SeisTau

SeisTau integrates the [TauPy](https://github.com/anowacki/TauPy.jl) and
[Seis](ttps://github.com/anowacki/Seis.jl) packages, allowing one to easily
use seismic travel time predictions for 1D Earth models with `Seis.Trace`s.
"""
module SeisTau

import Seis
import Seis: AbstractTrace, distance_deg
import TauPy

export travel_time

"""
    add_pick!(t, p::TauPy.Phase, name=p.name) -> (time, name)

Add a travel time pick to the `Trace` `t` from a `TauPy.Phase` arrival.

The pick name will be taken from the phase name by default.
"""
Seis.add_pick!(t::AbstractTrace, p::Union{TauPy.Phase,TauPy.PhaseGeog},
    name=p.name) = add_pick!(t, p.time, name)

"""
    add_picks!(t, phase; model="iasp91", exact=false)

Add travel time picks to the trace `t` for the 1D Earth `model`, for arrivals
with a name matching `phase`.

If `exact` is `true`, only phases which are an exact match for `phase` will
be added.

Available models are: $(TauPy.available_models()).
"""
function Seis.add_picks!(t::AbstractTrace, phase::AbstractString="ttall"; model="iasp91", exact=false)
    _check_headers_taup(t)
    arrivals = travel_time(t, phase; model=model)
    for arr in arrivals
        exact && arr.name != phase && continue
        Seis.add_pick!(t, arr.time, arr.name)
    end
    t.picks
end

"""
    path(t, phase="all"; model="iasp91", kwargs...) -> phases::Vector{TauPy.PhaseGeog}

Return ray paths for the geometry specified in the `Trace` t for the 1D Earth `model`,
for arrivals with a name matching `phase`.

Available models are: $(TauPy.available_models()).
"""
function path(t::AbstractTrace, phase; model="iasp91", kwargs...)
    _check_headers_taup(t)
    TauPy.path(t.evt.lon, t.evt.lat, t.evt.dep, t.sta.lon, t.sta.lat, phase; model=model, kwargs...)
end

"""
    travel_time(t, phase="all"; model="iasp91") -> phases::Vector{TauPy.Phase}

Return travel times for the geometry specified in the `Trace` `t` for the 1D
Earth `model`, for arrivals with a name matching `phase`.

Available models are: $(TauPy.available_models()).
"""
function travel_time(t::AbstractTrace, phase::AbstractString; model="iasp91", kwargs...)
    _check_headers_taup(t)
    TauPy.travel_time(t.evt.dep, distance_deg(t), phase; model=model, kwargs...)
end

"""
    travel_time(t, model="iasp91") -> ::Vector{Vector{TauPy.Phase}}

Return the list of `TauPy.Phase`s associated with each travel time pick in `t`.
"""
travel_time(t::AbstractTrace; model::AbstractString="iasp91") =
    [travel_time(t, name; model=model) for (_, name) in picks(t) if name[1] in ("p", "s", "P", "S")]

"Throw an error if a Trace doesn't contain the right headers to call TauPy.travel_time."
_check_headers_taup(t::AbstractTrace) = any(ismissing,
    (t.evt.lon, t.evt.lat, t.evt.dep, t.sta.lon, t.sta.lat)) &&
    throw(ArgumentError("Insufficient information in trace to compute travel times." *
                        "  (Need: evt.lon, evt.lat, evt.dep, sta.lon and sta.lat)")) ||
    nothing


end # module
