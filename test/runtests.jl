using SortedIteratorProducts
using Test
using Base.Iterators
using StatsBase

@testset "SortedIteratorProducts.jl" begin
    @testset "IteratorSize" begin
        @test Base.IteratorSize(SortedIteratorProduct(sum)) == Base.HasLength()
        @test Base.IteratorSize(SortedIteratorProduct(sum, cycle(1:4))) == Base.IsInfinite()
        @test Base.IteratorSize(SortedIteratorProduct(sum, 1:4, 1:7)) == Base.HasLength()
        @test Base.IteratorSize(SortedIteratorProduct(sum, cycle(1:4), 1:7)) != Base.HasLength()
        @test Base.IteratorSize(SortedIteratorProduct(sum, cycle(1:4), 1:0)) != Base.IsInfinite()
    end

    @testset "eltype" begin
        @test eltype(SortedIteratorProduct(sum)) == Tuple{}
        @test eltype(SortedIteratorProduct(sum, cycle(1:4))) == Tuple{Int}
        @test eltype(SortedIteratorProduct(sum, 1:4, 1:7)) == Tuple{Int, Int}
        @test eltype(SortedIteratorProduct(sum, cycle(1:4), 1:7)) == Tuple{Int, Int}
        @test eltype(SortedIteratorProduct(sum, cycle(1:4), 1:0)) == Tuple{Int, Int}
    end

    @testset "length" begin
        @test length(SortedIteratorProduct(sum)) == 1
        @test_throws MethodError length(SortedIteratorProduct(sum, cycle(1:4)))
        @test length(SortedIteratorProduct(sum, 1:4, 1:7)) == 4*7
        @test_throws MethodError length(SortedIteratorProduct(sum, cycle(1:4), 1:7))
        @test_broken length(SortedIteratorProduct(sum, cycle(1:4), 1:0)) == 0
    end

    function validate(x, n, by, iters...)
        y = collect(product(iters...))
        z = setdiff(y, x)

        @test issorted(x; by=sum)
        @test length(x) == n
        @test x ⊆ y
        @test allunique(x) || !allunique(y)

        cmy = countmap(y)
        cmx = countmap(x)
        @test all(e -> cmx[e] ≤ cmy[e], x) # TODO use this test

        @test all(by(a) ≤ by(b) for a in x for b in z)
    end

    @testset "end to end" begin
        x = collect(take(SortedIteratorProduct(sum, 1:4, 1:7), 10)) # is this block helpful?
        validate(x, 10, sum, 1:4, 1:7)
        y = collect(take(SortedIteratorProduct(sum, 1:4, 1:7), 30))
        validate(y, 28, sum, 1:4, 1:7)
        z = collect(SortedIteratorProduct(sum, 1:4, 1:7))
        validate(z, 28, sum, 1:4, 1:7)

        x = collect(take(SortedIteratorProduct(sum, 1:4, 1:3:21), 10))
        validate(x, 10, sum, 1:4, 1:3:21)
        y = collect(take(SortedIteratorProduct(sum, 1:4, 1:3:21), 30))
        validate(y, 28, sum, 1:4, 1:3:21)
        z = collect(SortedIteratorProduct(sum, 1:4, 1:3:21))
        validate(z, 28, sum, 1:4, 1:3:21)

        @test y == z # stable! (TODO more thorough tests)

        for i in SortedIteratorProduct(sum, 1:4, 1:3:22)
            nothing
        end
    end

    @testset "inf times zero" begin
        x = SortedIteratorProduct(sum, repeated(8), 1:0)
        @test iterate(x) === nothing
        @test_broken length(x) == 0
        @test_broken isempty(collect(x))
    end

    @testset "duplicate elements" begin
        x = collect(take(SortedIteratorProduct(sum, [1,3,3,3,5], 1:3:1000), 10))
        validate(x, 10, sum, [1,3,3,3,5], 1:3:1000)
        y = collect(take(SortedIteratorProduct(sum, [1,3,3,3,5], 1:2:1000), 1729))
        validate(y, 1729, sum, [1,3,3,3,5], 1:2:1000)
    end
end

#= TODO test
iteration on infinite
unknown size
fancy orders
what happens when by is not nondecreasing is not satisfied
performance
=#



### TODO move to CachedIterators.jl or somesuch
@testset "CachedIterators.jl" begin
    y = SortedIteratorProducts.cached(x^2 for x in 1:typemax(Int))
    @test y[10] == 100
    @test y[1] == 1
    @test y[5] == 25
    @test y[11] == 121
    @test_throws BoundsError y[0]
    @test_throws BoundsError y[-4]
    @test_throws MethodError y[2.5]
end
