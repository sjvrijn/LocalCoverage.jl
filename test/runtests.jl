using LocalCoverage, Test
import Pkg

Pkg.activate("./DummyPackage/")

const pkg = "DummyPackage"      # we test the package with a dummy created for this purpose

table_header = r"Filename\s+.\s+Lines\s+.\s+Hit\s+.\s+Miss\s+.\s+%"
table_line = r"(?<!\/|\\\\)src(\/|\\\\)DummyPackage.jl?\s+.\s+\d+\s+.\s+\d+\s+.\s+\d+\s+.\s+\d+%"
table_footer = r"TOTAL\s+.\s+\d+\s+.\s+\d+\s+.\s+\d+\s+.\s+\d+%"

covdir = normpath(joinpath(@__DIR__, "DummyPackage", "coverage"))

clean_coverage(pkg)
@test isdir(LocalCoverage.pkgdir(pkg))
lcovtrace = joinpath(covdir, "lcov.info")
@test !isfile(lcovtrace)

cov = generate_coverage(pkg)

xmltrace = joinpath(covdir,"lcov.xml")
write_lcov_to_xml(xmltrace, lcovtrace)
open(xmltrace, "r") do io
    header = readline(io)
    doctype = readline(io)
    @test header == """<?xml version="1.0" encoding="UTF-8"?>"""
    @test startswith(doctype, "<!DOCTYPE coverage")
end


buffer = IOBuffer()
show(buffer, cov)
table = String(take!(buffer))
println(table)
@test !isnothing(match(table_header, table))
@test !isnothing(match(table_line, table))
@test !isnothing(match(table_footer, table))

if !isnothing(Sys.which("genhtml"))
    mktempdir() do dir
        html_coverage(pkg, dir = dir)
        @test isfile(joinpath(dir, "index.html"))
    end
end

@test isfile(lcovtrace)
rm(covdir, recursive = true)

@info "Printing coverage infomation for visual debugging"
show(stdout, cov)
show(IOContext(stdout, :print_gaps => true), cov)

@test LocalCoverage.find_gaps([nothing, 0, 0, 0, 2, 3, 0, nothing, 0, 3, 0, 6, 2]) ==
    [2:4, 7:7, 9:9, 11:11]
