using PlotReferenceTests
using Test

function last_test_failed()
    set = Test.get_testset()
    if set isa Test.FallbackTestSet
        true
    else
        pop!(set.results) isa Test.Fail
    end
end

@testset "Plots.jl Tests" begin
    import Plots

    assets = joinpath(dirname(@__DIR__), "plots_assets")
    isdir(assets) && rm(assets, recursive=true)
    set_reference_dir(assets)

    # crate new asset
    f = @reftest "plot" Plots.plot([1,2,3],[1,2,3])
    @test last_test_failed()
    @test f isa Plots.Plot

    # check correct plot
    f = @reftest "plot" Plots.plot([1,2,3],[1,2,3])
    @test f isa Plots.Plot

    # check false plot
    f = @reftest "plot" Plots.plot([1,2,3],[1,2,4])
    @test last_test_failed()
    @test f isa Plots.Plot
    @test isfile(joinpath(assets, "plot+.png"))

    rm(assets, recursive=true)
end

@testset "Makie.jl Tests" begin
    import CairoMakie, GLMakie
    import CairoMakie: Makie

    assets = joinpath(dirname(@__DIR__), "makie_assets")
    isdir(assets) && rm(assets, recursive=true)
    set_reference_dir(assets)

    for backend in [CairoMakie, GLMakie]
        backend.activate!()

        # crate new asset
        f = @reftest repr(backend) Makie.plot([1,2,3],[1,2,3])
        @test last_test_failed()
        @test f isa Makie.FigureAxisPlot

        # check correct plot
        f = @reftest repr(backend) Makie.plot([1,2,3],[1,2,3])
        @test f isa Makie.FigureAxisPlot

        # check false plot
        f = @reftest repr(backend) Makie.plot([1,2,3],[1,2,4])
        @test last_test_failed()
        @test f isa Makie.FigureAxisPlot
        @test isfile(joinpath(assets, repr(backend)*"+.png"))
    end

    rm(assets, recursive=true)
end
