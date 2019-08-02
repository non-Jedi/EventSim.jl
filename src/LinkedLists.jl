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

export List, Node, next, prev, firstnode, lastnode

import Base: push!, insert!, iterate, eltype, length, getindex, setindex!,
    @propagate_inbounds, show

const MIndex = Union{Int,Nothing}

"""
    List{T}()

Create a doubly-linked list.

`List` implements the iterable interface. You can also use `firstnode`
and `lastnode` to get `Node` instances to use directly.
"""
mutable struct List{T}
    data::Vector{T}
    next::Vector{MIndex}
    prev::Vector{MIndex}
    firstind::MIndex
    lastind::MIndex
end#struct
List{T}() where T = List{T}(T[], MIndex[], MIndex[], nothing, nothing)
length(l::List) = length(l.data)

@propagate_inbounds function show(io::IO, l::List{T}) where T
    print(io, "List{", T, "}(")
    for i in collect(l)[1:end-1]
        print(io, i, ", ")
    end#for
    print(io, l.data[l.lastind], ')')
end#function

@propagate_inbounds function iterate(l::List)
    l.firstind === nothing && return
    (l.data[l.firstind], l.firstind)
end#function

@propagate_inbounds function iterate(l::List, i::Int)
    nextindex = l.next[i]
    nextindex === nothing && return
    (l.data[nextindex], nextindex)
end#function

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

"""
Represents a Node in a linked list.

Value can be accessed with `node[]`. Move through the list using
`next` and `prev`. Modify the list using `insert!`. `Node`s should not
be created directly but accessed by using `firstnode` or `lastnode` on
a `List`.
"""
struct Node{T}
    list::List{T}
    index::Int
end#struct

show(io::IO, n::Node) = print(io, "Node(", n[], ')')

@propagate_inbounds getindex(x::Node) = x.list.data[x.index]
@propagate_inbounds function setindex!(node::Node{T}, x::T) where T
    node.list.data[node.index] = x
    node
end#function

"""
    next(node)

Get the next node in a list.

Returns nothing if node was last node in list.
"""
@propagate_inbounds function next(x::Node)
    nextindex = x.list.next[x.index]
    nextindex === nothing && return
    Node(x.list, nextindex)
end#function

"""
    prev(node)

Get the previous node in a list.

Returns nothing if node was the first node in list.
"""
@propagate_inbounds function prev(x::Node)
    previndex = x.list.prev[x.index]
    previndex === nothing && return
    Node(x.list, previndex)
end#function

"""
    firstnode(list)

Get the first `Node` in `list`.

Returns nothing if list is empty.
"""
@propagate_inbounds function firstnode(l::List)
    l.firstind === nothing && return
    Node(l, l.firstind)
end#function

"""
    lastnode(list)

Get the last `Node` in `list`.

Returns nothing if list is empty.
"""
@propagate_inbounds function lastnode(l::List)
    l.lastind === nothing && return
    Node(l, l.lastind)
end#function

"""
    insert!(node, item)

Insert an `item` in the list `node` belongs to just before `node`.

This operation takes constant time. It returns the original `node`.
"""
@propagate_inbounds function insert!(node::Node{T}, item::T) where T
    prevnode_index = node.list.prev[node.index]
    # Create new node
    push!(node.list.data, item)
    push!(node.list.prev, prevnode_index)
    push!(node.list.next, node.index)
    newnode_index = length(node.list.data)
    # Update following node
    node.list.prev[node.index] = newnode_index
    # Update the preceding node
    if prevnode_index === nothing
        node.list.firstind = newnode_index
    else
        node.list.next[prevnode_index] = newnode_index
    end#if
    node
end#function

end#module
