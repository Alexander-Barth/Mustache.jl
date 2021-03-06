VERSION >= v"0.4.0-dev+6521" && __precompile__(true)
module Mustache

using Compat

include("utils.jl")
include("tokens.jl")
include("scanner.jl")
include("context.jl")
include("writer.jl")
include("parse.jl")

export @mt_str, @mt_mstr, render, render_from_file

"""

Macro to comile simple parsing outside of loops
use as mt"{{a}} and {{b}}", say

"""
macro mt_str(s)
    parse(s)
end

macro mt_mstr(s)
    parse(s)
end

"""

Render a set of tokens with a view, using optional `io` object to print or store.

Arguments
---------

* `io::IO`: Optional `IO` object.

* `tokens`: Either Mustache tokens, or a string to parse into tokens

* `view`: A view provides a context to look up unresolved symbols
  demarcated by mustache braces. A view may be specified by a
  dictionary, a module, a composite type, a vector, or keyword
  arguments.

"""
function render(io::IO, tokens::MustacheTokens, view)
    _writer = Writer()
    render(io, _writer, tokens, view)
end
function render(io::IO, tokens::MustacheTokens; kwargs...)
    d = Dict(kwargs) # [k => v for (k,v) in kwargs]
    render(io, tokens, d)
end

render(tokens::MustacheTokens, view) = sprint(io -> render(io, tokens, view))
render(tokens::MustacheTokens; kwargs...) = sprint(io -> render(io, tokens; kwargs...))

## Exported call without first parsing tokens via mt"literal"
##
## @param template a string containing the template for expansion
## @param view a Dict, Module, CompositeType, DataFrame holding variables for expansion
function render(io::IO, template::AbstractString, view)
    _writer = Writer()
    render(io, _writer, parse(template), view)
end
function render(io::IO, template::AbstractString; kwargs...)
    _writer = Writer()
    view = Dict(kwargs) # [k => v for (k,v) in kwargs]
    render(io, _writer, parse(template), view)
end
render(template::AbstractString, view) = sprint(io -> render(io, template, view))
render(template::AbstractString; kwargs...) = sprint(io -> render(io, template; kwargs...))

## Dict for storing parsed templates
TEMPLATES = Dict{AbstractString, MustacheTokens}()

## Load template from file
function template_from_file(filepath)
    f = open(readstring, filepath)
    tpl = parse(f)
#    f = open(filepath)
#    tpl = parse(readstring(f))
#    close(f)
    return tpl
end

"""

Renders a template from `filepath` and `view`. If it has seen the file
before then it finds the compiled `MustacheTokens` in `TEMPLATES` rather
than calling `parse` a second time.

"""
function render_from_file(filepath, view)
    if haskey(TEMPLATES, filepath)
        render(TEMPLATES[filepath], view)
    else
        try
            tpl = template_from_file(filepath)
            TEMPLATES[filepath] = tpl
            render(tpl, view)
        catch
            nothing
        end
    end
end
function render_from_file(filepath::AbstractString; kwargs...)
    d = Dict(kwargs) # [k => v for (k,v) in kwargs]
    render_from_file(filepath, d)
end

end
