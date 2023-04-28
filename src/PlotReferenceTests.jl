module PlotReferenceTests

export @reftest, set_reference_dir, refup

using ReferenceTests
using Test
using Requires
using FileIO

const REFDIR = Ref("")
const TMPDIR = Ref(tempdir())
const THREASHOLD = 200
const LAST = Ref("")

function set_reference_dir(path)
    if !isdir(path)
        @info "Create $path"
        mkdir(path)
    end
    REFDIR[] = path
end
function set_reference_dir(mod::Module, dir="assets")
    path = joinpath(pkgdir(mod), dir)
    set_reference_dir(path)
end

"""
    @reftest name fig

Mark figs in example files as reference test image. Those images will
be saved as `filename-i.png` to the gobal temp dir defined in this script.
"""
macro reftest(name, fig)
    quote
        _f = $(esc(fig))
        result = _save_and_compare($(esc(name)), _f)
        if _intestset()
            @test result
        end
        _f
    end
end

_intestset() = Test.get_testset() !== Test.FallbackTestSet()

function _save_and_compare(name::String, fig)
    @assert !isempty(REFDIR[]) "Please set REFDIR[]!"
    refpath = joinpath(REFDIR[], name*".png")
    if !isfile(refpath)
        _save_figure(refpath, fig)
        printstyled("Unknown reference! Stored new file as $(name).png\n"; color=:yellow)
        return false
    else # file allready exists
        tmppath = joinpath(TMPDIR[], name*".png")
        _save_figure(tmppath, fig)
        score = compare(load(refpath), load(tmppath))
        newversion = replace(refpath, r".png$" => s"+.png")
        if score > THREASHOLD
            _intestset() || printstyled("Test Passed"; color=:green, bold=true)
            # remove the tmp file
            rm(tmppath)
            # if the test succeds, delete the newversion if it was there
            if isfile(newversion)
                printstyled(": Remove conflicting version $(name)+.png"; color=:green, bold=true)
                rm(newversion)
            end
            println()
            return true
        else
            LAST[] = name
            if isfile(newversion) && compare(load(newversion), load(tmppath)) > THREASHOLD
                printstyled("Test Failed: Created same $(name)+.png again! Call `refup()` to accept.\n"; color=:yellow, bold=true)
            else
                mv(tmppath, newversion, force=true)
                printstyled("Test Failed: stored new version as $(name)+.png. Call `refup()` to accept.\n"; color=:red, bold=true)
            end
            return false
        end
    end
end

refup() = isempty(LAST[]) ? error("Don't now which reference to update.") : refup(LAST[])

function refup(name::AbstractString)
    @assert !isempty(REFDIR[]) "Please set REFDIR[]!"
    old = joinpath(REFDIR[], name*".png")
    new = joinpath(REFDIR[], name*"+.png")
    @assert isfile(old) "There is no file for $name.png"
    @assert isfile(new) "There is no file for $name+.png"
    rm(old)
    mv(new, old)
    printstyled("Replaced $name.png with $name+.png!\n"; color=:green, bold=true)
end

function refup(s::Symbol)
    if s===:all
        map(readdir(REFDIR[])) do f
            m = match(r"^(.+)\+.png$", f)
            if !isnothing(m)
                refup(only(m.captures))
            end
        end
    else
        error("Invalid argument $s")
    end
    nothing
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
        _save_figure(path, p::Plots.Plot) = Plots.savefig(p, path)
    end
end
end
