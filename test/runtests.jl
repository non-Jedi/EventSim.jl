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

# * EventSim.jl testing

using Test, EventSim, Observables
using EventSim.LinkedLists

# ** LinkedLists.jl

# TODO: linked list testing...
@testset "linked list" begin
    @testset "iterable interface and indexing" begin
        v = [1, 2, 3, 2, 4, 5, 100, -3, 532]
        l = List{Int}()
        @test_throws ErrorException firstindex(l)
        @test_throws ErrorException lastindex(l)
        for i in v
            push!(l, i)
        end#for
        for (i, j) in zip(v, l)
            @test i == j
        end#for
        @test last(v) == last(l)
        @test first(v) == first(l)
        @test l[firstindex(l)] == first(l)
        @test l[lastindex(l)] == last(l)
        @test l[nextindex(l, firstindex(l))] == v[2]
        @test l[previndex(l, lastindex(l))] == v[end-1]
        @test next(l, firstindex(l)) == v[2]
        @test prev(l, lastindex(l)) == v[end-1]

        l[end] = 427
        @test last(l) == 427

        @test length(eachindex(l)) == length(v) == length(collect(eachindex(l)))
    end#@testset
    @testset "list mutation" begin
        v = [1, 2, 3, 2, 4, 5, 100, -3, 532]
        l = List{Int}()
        @test_throws ArgumentError pop!(l)
        for i in v
            push!(l, i)
        end#for

        push!(l, 750)
        @test length(l) == length(v) + 1
        @test last(l) == 750

        insert!(l, firstindex(l), -1000)
        @test length(l) == length(v) + 2
        @test first(l) == -1000
        @test next(l, firstindex(l)) == first(v)

        @test pop!(l) == 750
        @test length(l) == length(v) + 1
        @test last(l) == last(v)

        @test popfirst!(l) == -1000
        @test length(l) == length(v)
        @test all(l .== v)

        insert!(l, previndex(l, lastindex(l)), 9543)
        @test length(l) == length(v) + 1
        @test prev(l, previndex(l, lastindex(l))) == 9543
        @test last(l) == last(v)
        @test prev(l, lastindex(l)) == v[end-1]
        @test next(l, previndex(l, previndex(l, lastindex(l)))) == v[end-1]
        @test next(l, previndex(l, previndex(l, previndex(l, lastindex(l))))) == 9543

        @test pop!(l, previndex(l, lastindex(l))) == v[end-1]
        @test length(l) == length(v)
        @test last(l) == last(v)
        @test prev(l, lastindex(l)) == 9543
        @test prev(l, previndex(l, lastindex(l))) == v[end-2]
        @test next(l, previndex(l, previndex(l, lastindex(l)))) == 9543

        @test pop!(l, 99999, missing) === missing
    end#@testset
end#@testset

# ** Scheduling

@testset "schedule!" begin
    sim = Simulation()
    toggle_check = Observable(0)
    f(_) = toggle_check[] = 1
    g(_) = toggle_check[] = 2
    h(_) = toggle_check[] = 3

    event1 = schedule!(f, sim, 5)
    event2 = schedule!(g, sim, 7)
    event3 = schedule!(f, sim, 18.0)
    event4 = schedule!(h, sim, 12)

    @test length(sim.calendar) == 5
    @test toggle_check[] == 0

    node = firstindex(sim.calendar)
    sim.calendar[node].status[] = true
    @test sim.calendar[node] != event1
    @test toggle_check[] == 0

    node = nextindex(sim.calendar, node)
    sim.calendar[node].status[] = true
    @test sim.calendar[node] == event1
    @test toggle_check[] == 1

    node = nextindex(sim.calendar, node)
    sim.calendar[node].status[] = true
    @test sim.calendar[node] == event2
    @test toggle_check[] == 2

    node = nextindex(sim.calendar, node)
    sim.calendar[node].status[] = true
    @test sim.calendar[node] == event4
    @test toggle_check[] == 3

    node = nextindex(sim.calendar, node)
    sim.calendar[node].status[] = true
    @test sim.calendar[node] == event3
    @test toggle_check[] == 1
end#@testset

# ** Running

@testset "running" begin
    sim = Simulation()
    watcher = Observable(0)
    f1(_) = watcher[] = 1
    t1(_) = @test watcher[] == 1
    f2(_) = watcher[] = 2
    t2(_) = @test watcher[] == 2
    f3(_) = watcher[] = 3
    t3(_) = @test watcher[] == 3

    e1 = schedule!(f1, sim, 2)
    e2 = schedule!(f2, sim, 0.2)
    e3 = schedule!(f1, sim, 500)
    e4 = schedule!(f3, sim, 11)
    e5 = schedule!(f2, sim, 6)
    e6 = schedule!(f3, sim, 50)
    e7 = schedule!(f2, sim, 60)

    e8 = schedule!(t1, sim, 2.01)
    e9 = schedule!(t2, sim, 0.201)
    e10 = schedule!(t1, sim, 500.01)
    e11 = schedule!(t3, sim, 11.01)
    e12 = schedule!(t2, sim, 6.01)
    e13 = schedule!(t3, sim, 50.01)
    e14 = schedule!(t2, sim, 60.01)

    run!(sim, 400)
    @test now(sim) ≈ 400
    @test !e3.status[]
    @test !e10.status[]
    @test e1.status[]
    @test e2.status[]
    @test e7.status[]
    @test e12.status[]
    @test e14.status[]

    run!(sim, 600)
    @test now(sim) ≈ 600
    @test e3.status[]
    @test e10.status[]
end#@testset
