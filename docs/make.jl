using SortedIteratorProducts
using Documenter

DocMeta.setdocmeta!(SortedIteratorProducts, :DocTestSetup, :(using SortedIteratorProducts); recursive=true)

makedocs(;
    modules=[SortedIteratorProducts],
    authors="Lilith Hafner <Lilith.Hafner@gmail.com> and contributors",
    repo="https://github.com/LilithHafner/SortedIteratorProducts.jl/blob/{commit}{path}#{line}",
    sitename="SortedIteratorProducts.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://LilithHafner.github.io/SortedIteratorProducts.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/LilithHafner/SortedIteratorProducts.jl",
    devbranch="main",
)
