module PlotReferenceTests

export @reftest, set_reference_dir

using ReferenceTests
using Test
using Requires
using FileIO

const REFDIR = Ref("")
const TMPDIR = Ref(tempdir())
const THREASHOLD = 200

function set_reference_dir(path)
    if !isdir(path)
        @info "Create $path"
        mkdir(path)
    end
    REFDIR[] = path
end


"""
    @reftest name fig

Mark figs in example files as reference test image. Those images will
be saved as `filename-i.png` to the gobal temp dir defined in this script.
"""
macro reftest(name, fig)
    quote
        _f = $(esc(fig))
        try
            @test _save_and_compare($(esc(name)), _f)
        catch e
        end
        _f
    end
end

function _save_and_compare(name::String, fig)
    @assert !isempty(REFDIR[]) "Please set REFDIR[]!"
    refpath = joinpath(REFDIR[], name*".png")
    if !isfile(refpath)
        _save_figure(refpath, fig)
        printstyled("Unknown reference! Stored new file as $(name).png\n"; color=:red)
        return false
    else # file allready exists
        tmppath = joinpath(TMPDIR[], name*".png")
        _save_figure(tmppath, fig)
        score = compare(load(refpath), load(tmppath))
        if score > THREASHOLD
            printstyled("Test Passed\n"; color=:green)
            return true
        else
            newpath = replace(refpath, r".png$" => s"+.png")
            mv(tmppath, newpath, force=true)
            printstyled("Test Failed: stored new version as $(name)+.png\n"; color=:red)
            return false
        end
    end
end

function compare(ref, x)
    if size(ref) != size(x)
        return 0
    end
    return ReferenceTests._psnr(ref, x)
end


function _save_figure(path, fig)
    save(path, fig)
end

function __init__()
    @require Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80" begin
        import Plots
        _save_figure(path, p::Plots.Plot) = Plots.savefig(p, path)
    end
end
end
