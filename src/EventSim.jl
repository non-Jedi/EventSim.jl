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
    pos::Node{Event}
end#struct

function Simulation(t=0)
    calendar = List{Event}()
    push!(calendar, Event(t))
    Simulation(calendar, firstnode(calendar))
end#function

# ** Scheduling

"""
    now(sim)

Return the current time in `sim`.
"""
now(sim::Simulation) = sim.pos[].time

"""
    findt(calendar, t)

Returns the `Node{Event}` immediately following `t`.

If `t` is larger than any currently scheduled time, returns
nothing. This is a linear-time operation.
"""
function findt(calendar::List{Event}, t)
    node = firstnode(calendar)
    while true
        if node === nothing
            return node
        elseif t <= node[].time
            return node
        end#if
        node = next(node)
    end#while
end#function

# Callbacks on observables should expect the value of the observable
# as an argument. EventSim api expects "thunks": f()
fwrapper(f) = _ -> f()

"""
    schedule!(f, sim, t)

Schedules `f` to run in `sim` at time `t`.

Returns an `Event` which will have it's `status` toggled to
`Observable(true)` when `f` executes.

If the current simulation time is already past `t`, `Event.status[]`
will immediately be toggled to `true`, and `f` will immediately
execute.
"""
function schedule!(f, sim::Simulation, t)
    event = Event(t)
    on(fwrapper(f), event.status)
    if t <= sim.pos[].time
        event.status[] = true
    else
        node = findt(sim.calendar, t)
        if node === nothing
            push!(sim.calendar, event)
        else
            insert!(node, event)
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
        endofsim = schedule!(Nothing, sim, t)
        while sim.pos !== nothing && sim.pos[] != endofsim
            occur!(sim.pos[])
            sim.pos = next(sim.pos)
        end#while
    end#if
    sim
end#function

# ** End module

end#module
