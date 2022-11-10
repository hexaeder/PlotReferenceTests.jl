# PlotReferenceTests

[![Build Status](https://github.com/hexaeder/PlotReferenceTests.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/hexaeder/PlotReferenceTests.jl/actions/workflows/CI.yml?query=branch%3Amain)

This is an experimental & opinionated package for fast and easy reference testing of plots.

## Motivation
When developing model libraries, it is quit common to write small test simulations and observe the plots of trajectories to check if the model is doing the right stuff. The idea of this package is to streamline the process of making those toy models into unit tests. Saving the actual trajectories for reference testing is tedious because the data is not interpretable by humans. If the test fails, it is hard to say if the *solver details* changed or the *model behavior* changed. To check the model behavior you need to plot those results - so why not just compare plots in the first place?

## Usage
Add `PlotReferenceTests` to your test dependencies of `MyPkg`. You can specify the folder where the references are stored using

```julia
using PlotReferenceTests
set_reference_dir(MyPkg) # uses MyPkg.jl/assets/ or
set_reference_dir(custompath)
```

Now you're good to go: just copy your toy model into a `@testset` and annotated your plots with
``` julia
@reftest "my_testplot" plot(sol)
```

This will create a new file `$assets/my_testplot.png` on first call. Whenever this line is called again it will create a new plot in a temporary directory and compare to the stored version: 
- If they match, great!
- If they don't match it will create `$assets/my_testplot+.png` alongside the original file. Fire up your image viewer of choice and compare both files side by side.

You can "accept" the new version by replacing the reference picture with the `+`-picture and commit the new reference. Interactively, you can get around the tedious renaming of the files by calling `refup()` (the last one), `refup(plotname)` or `refup(:all)`. 

The `@reftest` macro works with `Plots.jl` and `Makie.jl` plots. It will always return the plot object so you can just execute the line and observe the plot notebook-style while debugging.

## Future Plans
- Maybe make passing an explicit plot name optional and create a name automatically based on the module/filename and a number. However this breaks interactive, notebook style, line-by-line execution of your test code because the will be evaluated in `Main` and you don't now the file.
- Integrate with `Literate.jl` example scripts or maybe even "normal" `Documenter.jl` examples. Reference testing of your plots in the docs is a powerful way to make sure the docs are fine.
