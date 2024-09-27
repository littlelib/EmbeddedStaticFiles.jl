module EmbeddedStaticFiles

using Base, Base64

export FileHandleBuilder, embed

@kwdef mutable struct FileHandleBuilder
    handler_name::String="File"
    entries::Dict{String, String}=Dict()
    out_dir::String="./static_files"
end

Base.push!(builder::FileHandleBuilder, entry::Pair)=push!(builder.entries, entry)
Base.push!(builder::FileHandleBuilder, entry1, entry2)=push!(builder, string(entry1)=>string(entry2))
Base.push!(builder::FileHandleBuilder, entry::Tuple)=push!(builder, string(entry|>first)=>string(entry|>last))

Base.delete!(builder::FileHandleBuilder, entry)=delete!(builder.entries, entry|>string)

function embed(builder::FileHandleBuilder)
    mkpath(foldl(joinpath, [builder.out_dir, "data"]))
    for entry in builder.entries
        key, file_path=entry
        open(file_path, "r") do file
            encoded_content=read(file)|>base64encode
            open(foldl(joinpath, [builder.out_dir, "data", "$key.jl"]), "w") do file
                write(file, "const var\"$key\"=\"$encoded_content\"")
            end
        end
    end
    open(joinpath(builder.out_dir, "file_handle.jl"), "w") do file
        keys=map(x->first(x), builder.entries|>collect)
        imports="using Base64"
        includes=map(keys) do key
            "include(\"$(foldl(joinpath, ["data", key])).jl\")"
        end|>
        x->join(x, "\n")
        file_handle=map(keys) do key
            "\"$key\"=>var\"$key\""
        end|>
        x->join(x, ",")|>
        x->"const FILE_HANDLE=[$x]|>Dict"
        functions=
"""function get(key)
    FILE_HANDLE[key]|>base64decode
end
"""
        partial_code=join([imports,includes,file_handle, functions], "\n\n")
        full_code=
"""module $(builder.handler_name)

$(partial_code)

end
"""
        write(file, full_code)
    end
end

end # module EmbeddedStaticFiles
