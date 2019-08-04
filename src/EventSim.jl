# This file is part of EventSim.jl.
#
# EventSim.jl is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# EventSim.jl is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.

# * EventSim.jl

module EventSim

export Simulation, now, schedule!, schedule_after!, occur!, run!

include("LinkedLists.jl")

using .LinkedLists, Observables

import Base: show

# ** Datastructures

"""
    Event(time)

Represents an event that occurs at `time`.

If field `status` is `Observable(true)`, the event has already
occurred.
"""
struct Event
    time::Float64
    status::Observable{Bool}
end#struct
Event(t, s::Bool=false) = Event(convert(Float64, t), Observable(s))

show(io::IO, e::Event) = print(io, "Event(", e.time, ", ", e.status[], ")")

mutable struct Simulation
    calendar::List{Event}
    pos::Int
end#struct

function Simulation(t=0)
    calendar = List{Event}()
    push!(calendar, Event(t))
    Simulation(calendar, firstindex(calendar))
end#function

# ** Scheduling

"""
    now(sim)

Return the current time in `sim`.
"""
now(sim::Simulation) = sim.calendar[sim.pos].time

"""
    findt(calendar, t)

Returns the `calendar` index immediately following `t`.

If `t` is larger than any currently scheduled time, returns
nothing. This is a linear-time operation.
"""
function findt(calendar::List{Event}, t)
    @inbounds for i in eachindex(calendar)
        if t ≤ calendar[i].time
            return i
        end#if
    end#for
    return
end#function

# Callbacks on observables should expect the value of the observable
# as an argument. EventSim api single argument of sim: f(sim)
fwrapper(f, sim, args...) = _ -> f(sim, args...)

"""
    schedule!(f, sim, t)

Schedules `f` to run in `sim` at time `t`.

Returns an `Event` which will have it's `status` toggled to
`Observable(true)` when `f` executes.

If the current simulation time is already past `t`, `Event.status[]`
will immediately be toggled to `true`, and `f` will immediately
execute.

`f` should be a function that takes a simulation object as a first and
only argument.
"""
function schedule!(f, sim::Simulation, t, fargs...)
    event = Event(t)
    on(fwrapper(f, sim, fargs...), event.status)
    if t <= now(sim)
        occur!(event)
    else
        pos = findt(sim.calendar, t)
        if pos === nothing
            push!(sim.calendar, event)
        else
            insert!(sim.calendar, pos, event)
        end#if
    end#if
    event
end#function

"""
    schedule_after!(f, sim, Δt)

Schedules `f` to run in `sim` after `Δt` time units have elapsed.
"""
schedule_after!(f, sim::Simulation, Δt) = schedule!(f, sim, now(sim) + Δt)

# ** Running

"""
    occur!(event)

Make an `event` occur and run all associated callbacks.
"""
occur!(event::Event) = event.status[] = true

"""
    run(sim, t)

Run `sim` until time `t`.
"""
function run!(sim::Simulation, t)
    if now(sim) < t
        endofsim = schedule!(_ -> nothing, sim, t)
        @inbounds while sim.calendar[sim.pos] != endofsim
            occur!(sim.calendar[sim.pos])
            sim.pos = nextindex(sim.calendar, sim.pos)
        end#while
    end#if
    sim
end#function

# ** End module

end#module
