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

using Test, EventSim, Observables
using EventSim.LinkedLists

@testset "linked list" begin
    l = List{Int}()
    v = [5, 6, 7, 2, 19, -5, 0, -350]
    for i in v
        push!(l, i)
    end#for
    for (i, j) in zip(l, v)
        @test i == j
    end#for
    @test length(l) == length(v)
    @testset "node" begin
        n1 = firstnode(l)
        n2 = next(n1)
        n3 = next(n2)
        n4 = next(n3)
        insert!(n4, 6)
        insert!(n3, -1)
        @test prev(n4) == next(n3)
        @test prev(n3) == next(n2)
        @test length(l) == length(v) + 2
        @test prev(n4)[] == 6
        @test next(n2)[] == -1
        insert!(n1, -2000)
        @test firstnode(l) == prev(n1)
        @test prev(n1)[] == -2000
        @test length(l) == length(v) + 3
        n1[] = 9000
        @test n1[] == 9000
        @test prev(n2)[] == 9000
    end#@testset
end#@testset

@testset "schedule!" begin
    sim = Simulation()
    toggle_check = Observable(0)
    f() = (toggle_check[] = 1)
    g() = (toggle_check[] = 2)
    h() = (toggle_check[] = 3)

    event1 = schedule!(f, sim, 5)
    event2 = schedule!(g, sim, 7)
    event3 = schedule!(f, sim, 18.0)
    event4 = schedule!(h, sim, 12)

    @test length(sim.calendar) == 5
    @test toggle_check[] == 0

    node = firstnode(sim.calendar)
    node[].status[] = true
    @test node[] != event1
    @test toggle_check[] == 0

    node = next(node)
    node[].status[] = true
    @test node[] == event1
    @test toggle_check[] == 1

    node = next(node)
    node[].status[] = true
    @test node[] == event2
    @test toggle_check[] == 2

    node = next(node)
    node[].status[] = true
    @test node[] == event4
    @test toggle_check[] == 3

    node = next(node)
    node[].status[] = true
    @test node[] == event3
    @test toggle_check[] == 1
end#@testset
