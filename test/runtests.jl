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

using Test, EventSim
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

