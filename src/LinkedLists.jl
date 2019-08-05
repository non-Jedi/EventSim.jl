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

"Efficient implementation of a doubly-linked list."
module LinkedLists

export List, pop!, popfirst!, first, last, firstindex, lastindex,
    nextindex, previndex, next, prev

import Base: eltype, length, iterate, getindex, setindex!,
    @propagate_inbounds, checkbounds, show, keys, push!, insert!,
    pop!, popfirst!, first, last, firstindex, lastindex

const MIndex = Union{Int,Nothing}

# TODO: grow List.data by page size increments using sizehint
"""
    List{T}()

Create a doubly-linked list.

`List` implements the iterable interface but can also have its items
accessed with indices.

An index into a `List` should be treated as opaque. The next item in
the list is not necessarily located at the next incremental index.
"""
mutable struct List{T}
    data::Vector{T}
    next::Vector{MIndex}
    prev::Vector{MIndex}
    removed::Vector{Int}
    firstind::MIndex
    lastind::MIndex
end#struct
# TODO: constructor from generic iterable
List{T}() where T = List{T}(T[], MIndex[], MIndex[], Int[], nothing, nothing)

eltype(::List{T}) where T = T

length(l::List) = length(l.data) - length(l.removed)

checkbounds(::Type{Bool}, l::List, i::Int) =
    i ≥ 1 && i ≤ length(l.data) && !in(i, l.removed)

@inline function getindex(l::List, i::Int)
    @boundscheck checkbounds(Bool, l, i)
    @inbounds l.data[i]
end#function

@propagate_inbounds first(l::List) =
    isempty(l) ? error("empty list has no first element") : l[l.firstind]

@propagate_inbounds last(l::List) =
    isempty(l) ? error("empty list has no last element") : l[l.lastind]

@propagate_inbounds firstindex(l::List) =
    isempty(l) ? error("empty list has no first element") : l.firstind

@propagate_inbounds lastindex(l::List) =
    isempty(l) ? error("empty list has no first element") : l.lastind

@inline function setindex!(l::List{T}, v::T, i::Int) where T
    @boundscheck checkbounds(Bool, l, i)
    @inbounds l.data[i] = v
end#function

@propagate_inbounds function show(io::IO, l::List{T}) where T
    print(io, "List{", T, "}(")
    if !isempty(l)
        for i in collect(l)[1:end-1]
            print(io, i, ", ")
        end#for
        print(io, l.data[l.lastind])
    end#if
    print(io, ')')
end#function

@propagate_inbounds function iterate(l::List, i::Union{Nothing,Int}=l.firstind)
    i === nothing && return
    (l.data[i], l.next[i])
end#function

"""
    nextindex(list, index)

Returns the index immediately following `index` in `list`.

Returns nothing if at end of `list`.
"""
@inline function nextindex(l::List, i::Int)
    @boundscheck checkbounds(Bool, l, i)
    @inbounds l.next[i]
end#function

"""
    previndex(list, index)

Returns the index immediately preceding `index` in `list`.

Returns nothing if at start of `list`.
"""
@inline function previndex(l::List, i::Int)
    @boundscheck checkbounds(Bool, l, i)
    @inbounds l.prev[i]
end#function

# TODO: add argument for specifying how many slots to advance
"""
    next(list, index)

Returns the next value from `index`.

Returns nothing if at end of `list`.
"""
function next(l::List, i::Int)
    @boundscheck checkbounds(Bool, l, i)
    @inbounds nexti = nextindex(l, i)
    @inbounds nexti === nothing ? nothing : l[nexti]
end#function

"""
    prev(list, index)

Returns the previous value from `index`.

Returns nothing if at start of `list`.
"""
function prev(l::List, i::Int)
    @boundscheck checkbounds(Bool, l, i)
    @inbounds previ = previndex(l, i)
    @inbounds previ === nothing ? nothing : l[previ]
end#function

"Simple wrapper around `List` to allow iterating through indices."
struct ListIndices{T}
    list::List{T}
end#struct

eltype(::ListIndices) = Int

length(li::ListIndices) = length(li.list)

@propagate_inbounds function iterate(li::ListIndices,
                                     i::Union{Nothing,Int}=li.list.firstind)
    i === nothing && return
    (i, li.list.next[i])
end#function

keys(l::List) = ListIndices(l)

# TODO: reuse indices in List.removed
@propagate_inbounds function push!(l::List{T}, x::T) where T
    if l.lastind === nothing
        push!(l.data, x)
        push!(l.next, nothing)
        push!(l.prev, nothing)
        l.firstind = l.lastind = 1
    else
        push!(l.data, x)
        l.next[l.lastind] = length(l.data)
        push!(l.prev, l.lastind)
        push!(l.next, nothing)
        l.lastind = length(l.data)
    end#if
    l
end#function

@inline function insert!(l::List{T}, i::Int, value::T) where T
    @boundscheck checkbounds(Bool, l, i)
    previ = l.prev[i]

    # First create new entry for inserted value
    push!(l.data, value)
    push!(l.next, i)
    push!(l.prev, previ)
    newi = length(l.data)

    # Update list at i
    l.prev[i] = newi

    # Update list at previ
    if previ === nothing
        l.firstind = newi
    else
        l.next[previ] = newi
    end#if
    l
end#function

function pop!(l::List, i::Int, default)
    checkbounds(Bool, l, i) || return default

    previ = l.prev[i]
    nexti = l.next[i]
    l.prev[i] = nothing
    l.next[i] = nothing
    push!(l.removed, i)

    if previ === nothing
        l.firstind = nexti
    else
        l.next[previ] = nexti
    end#if

    if nexti === nothing
        l.lastind = previ
    else
        l.prev[nexti] = previ
    end#if

    l[i]
end#function

struct NoDefault end
const nodefault = NoDefault()

function pop!(l::List, i)
    returnval = pop!(l, i, nodefault)
    returnval === nodefault && throw(KeyError(i))
    returnval
end#function

function pop!(l::List)
    isempty(l) && throw(ArgumentError("list must be non-empty"))
    pop!(l, l.lastind)
end#function

function popfirst!(l::List)
    isempty(l) && throw(ArgumentError("list must be non-empty"))
    pop!(l, l.firstind)
end#function

end#module
