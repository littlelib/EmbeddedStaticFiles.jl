# EmbeddedStaticFiles.jl
Create local, relocatable assets by embedding files into your package as julia code.

# How it works
- It basically encodes your static files to base64 format, turn them as julia strings, and save them as julia code files. They are retrieved in-memory when you load the wrapper julia module.

# When to use
- It can be used as a **RELOCATABLE** and **LOCAL** asset storage. Currently, there's no other way of achieving them both; using @\_\_DIR\_\_ for local files will create a package that's non-relocatable when compiled as a sysimage or an executable, and the Artifacts system doesn't support local files. If your files are small, and serving them via separate servers seems to be an overkill, EmbeddedStaticFiles.jl may as well do the job.

# Disclaimer
- It is meant to be used for small files only, e.g. some files which are a few megabytes at tops. **Beware that it is highly memory-inefficient!** It stores some bloated version of your file from the start, as it is base64 encoded. And since you're likely to use the decoded version, there would be least 2 copies of your file on the memory - the embedded base64-encoded file that's stored, and the decoded file that you'll use. This is a huge memory bloat, and definitely a footgun if you embed gigabytes of files.
- Julia seem to have a maximum length of code it can parse, and embedding a very large file, e.g. more than 3 GB, will break the julia parser. (I've tried it and seen it happen)
- It only supports static files. You won't be able to create new files nor modify the existing ones in runtime.

# Usage
## Installation
```julia
using Pkg
# Use git for installation, as it is currently not on the julia package registry.
Pkg.add("https://github.com/JuliaServices/ConcurrentUtilities.jl.git")
```
## Example scenario
Let's assume there's a simple julia package in `~/SimplePackage`. It would be nice to have a few template html/js/css files as assets, which are located in `~/data` as `index.html`, `main.js`, and `main.css`. You want the assets to be stored in `~/SimplePackage/src/static_files`. You want the file handler(wrapping julia module)'s name to be "File".

```julia
julia> using EmbeddedStaticFiles
julia> pwd()
"/home/some_user/SimplePackage"
# Create the FileHandleBuilder. Default values: handler_name="File", entries=Dict(), out_dir="./static_files"
julia> filehandle_builder=FileHandleBuilder(handler_name="File", entries=Dict(), out_dir="./src/static_files")
# push!(FileHandleBuilder, arbitrary_key_name, path_to_file)
julia> push!(filehandle_builder, "index_html", "../data/index.html")
julia> push!(filehandle_builder, "main_js", "../data/main.js")
julia> push!(filehandle_builder, "main_css", "../data/main.css")
# In case you pushed a wrong entry to the FileHandleBuilder
julia> push!(filehandle_builder, "maybe a cat", "walked over the keyboard")
julia> delete!(filehandle_builder, "maybe a cat")
# Create the encoded files and the wrapper module
julia> embed(filehandle_builder)
```

This will create the encoded files in `~/SimplePackage/src/static_files/data` as `index_html.jl`, `main_js.jl`, and `main_css.jl`. The wrapper module to call them will be located as `~/SimplePackage/src/static/file_handle.jl`.

Now, if you're to use the files in SimplePackage, simply include the `file_handle.jl`
```julia
#~/SimplePackage/src/SimplePackage.jl
module SimplePackage
...
include("static_files/file_handle.jl")
#Now you can call the embedded files via MODULE_NAME.get(key_name)
File.get("index_html") # Give you the content of your file as an U8 array.
```



