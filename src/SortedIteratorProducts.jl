module SortedIteratorProducts

using DataStructures: BinaryHeap

export SortedIteratorProduct

struct SortedIteratorProduct{T<:Tuple, F<:Function}
    sources::T
    by::F
end

"""
    SortedIteratorProduct(by::Function, iterators...)

Construct an iterator over the cartesian product of `iterators` that is sorted according to
`by`. `by` must be non-decreasing over the indices of `iterators`.

For example, if there are two iterators `a` and `b`, then
`by(first(a), first(b)) ≤ by(first(a), second(b))` where `second(b)` is the second element
of `b`.

```jldoctest
julia> using ..SortedIteratorProducts, Base.Iterators

julia> A = Iterators.Count(1, 1);

julia> B = Iterators.Count(3, 2);

julia> x = SortedIteratorProduct(sum, A, B);

julia> collect(take(x, 6))
6-element Vector{Tuple{Int64, Int64}}:
 (1, 3)
 (2, 3)
 (3, 3)
 (1, 5)
 (4, 3)
 (2, 5)

julia> x = SortedIteratorProduct(((b,a),) -> b^a, B, A);

julia> collect(take(x, 6))
6-element Vector{Tuple{Int64, Int64}}:
 (3, 1)
 (5, 1)
 (7, 1)
 (9, 1)
 (3, 2)
 (11, 1)
```
"""
function SortedIteratorProduct(by::Function, iterators...)
    sources = cached.(iterators)
    SortedIteratorProduct(sources, by)
end

lookup(sip, x) = tuple((s[i] for (s, i) in zip(sip.sources, x))...)
function Base.iterate(sip::SortedIteratorProduct)
    all(x -> checkbounds(Bool, x, 1), sip.sources) || return nothing
    one = map(_->1, sip.sources)
    iterate(sip, (Set((one,)), BinaryHeap(Base.By(x -> (sip.by(lookup(sip, x)), reverse(x))), [one])))
end
function Base.iterate(sip::SortedIteratorProduct, (set, heap))
    isempty(heap) && return nothing
    indices = pop!(heap)

    for i in eachindex(indices)
        new = ntuple(j -> indices[j] + (j == i), length(indices))
        if checkbounds(Bool, sip.sources[i], indices[i]+1) && new ∉ set
            push!(set, new)
            push!(heap, new)
        end
    end
    lookup(sip, indices), (set, heap)
end
Base.collect(sip::SortedIteratorProduct) = sort!(vec(collect(Base.Iterators.product(sip.sources...))); by=sip.by)

function multiply(i1::Base.IteratorSize, i2::Base.IteratorSize)
    (i1, i2) isa NTuple{2, Base.IsInfinite} && return Base.IsInfinite()
    (i1, i2) isa NTuple{2, Union{Base.HasLength, Base.HasShape}} && return Base.HasLength()
    Base.SizeUnknown()
end

function Base.IteratorSize(::Type{SortedIteratorProduct{T, F}}) where {T, F}
    mapreduce(Base.IteratorSize, multiply, fieldtypes(T))
end
Base.IteratorSize(::Type{SortedIteratorProduct{Tuple{}, F}}) where F = Base.HasLength()
Base.length(sip::SortedIteratorProduct) = prod(length, sip.sources, init=1)

Base.IteratorEltype(::Type{SortedIteratorProduct}) = Base.HasEltype()
Base.eltype(::Type{SortedIteratorProduct{T, F}}) where {T, F} = Tuple{eltype.(fieldtypes(T))...}



### TODO move to CachedIterators.jl or somesuch
struct Cached{T, C <: AbstractVector{T}, S}
    cache::C
    source::S
end
cached(iterator) = Cached(eltype(iterator)[], Base.Iterators.Stateful(iterator))
cached(x::AbstractArray) = x

Base.eltype(::Type{Cached{T}}) where T = T
Base.firstindex(x::Cached) = firstindex(x.cache)

function Base.checkbounds(::Type{Bool}, x::Cached, i::Integer)
    i < firstindex(x.cache) && return false
    while i > lastindex(x.cache)
        isempty(x.source) && return false
        push!(x.cache, popfirst!(x.source))
    end
    true
end

function Base.getindex(x::Cached, i::Integer)
    checkbounds(Bool, x, i) # @inbounds not allowed
    x.cache[i]
end

Base.iterate(x::Cached, i::Integer=firstindex(x)) = checkbounds(Bool, x, i) ? (x[i], i + 1) : nothing
Base.IteratorSize(::Type{Cached{T, C, S}}) where {T, C, S} = Base.IteratorSize(S)
Base.length(x::Cached) = length(x.cache) + length(x.source)
Base.eltype(::Type{<:Cached{T}}) where T = T

end
