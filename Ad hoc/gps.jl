### A Pluto.jl notebook ###
# v0.18.1

using Markdown
using InteractiveUtils

# ╔═╡ ae93dec4-aa36-11ec-3f1a-8332a0276b8d
begin
using Primes
using DataFrames
using Queryverse
using VegaLite
end

# ╔═╡ 7e1248c4-912e-4c52-91c3-d22d3dc35181
showhidebutton = html"""
<style>
body.hide-all-code pluto-input {display: none !important;}
</style>

<button onClick="document.body.classList.toggle('hide-all-code')">Show/hide all code</button> 

<script>
document.body.classList.add('hide-all-code')
</script>

"""

# ╔═╡ 9bc8ea38-cf0b-4ee1-b22e-fb6ff15637ad
md"# Gaussian Primes Spirals"

# ╔═╡ f7369057-8e79-4384-baaa-c127be359da2
html"""<style>
main {
    max-width: 1000px;
    align-self: center;
  
}
"""

# ╔═╡ 718bb8ad-8fe5-4cc5-b2b0-3bedb9894c88
begin
	# Determine if a complex integer z is a gaussian prime or not
	function gaussian_prime(z::Complex{Int64})
	  a = real(z)
	  b = imag(z)
	  if z == 0
	    return false
	  elseif a != 0 && b != 0
	    modulus_z_squared = abs2(z) |> Int
	    tv = isprime(modulus_z_squared) && (mod(modulus_z_squared, 4) != 3)
	    return tv
	  elseif a == 0 || b == 0
	    modulus_z = abs(z) |> Int
	    tv =  (isprime(modulus_z)) && (mod(modulus_z, 4) == 3)
	    return tv
	  end
	end
	md"This function determines if a complex integer z is a gaussian prime or not."
end



# ╔═╡ 1e77c48b-964c-464a-90b9-b8824ba6f7c3
begin
	# Get all gaussian primes in the range of n units up/down/left/right from z
	function gaussian_prime_list(z::Complex{Int64}, n::Int64)
	  my_list = Complex{Int64}[]
	  x = real(z)
	  y = imag(z)
	  for a = x - n:x + n, b = y - n:y + n
	    complex_num = a + b * im
	    push!(my_list, complex_num)
	  end
	  return filter(gaussian_prime, my_list)
	end
	md"Get all gaussian primes in the range of n units up/down/left/right from z."
end

# ╔═╡ 70805663-76a9-494c-b4e8-be072e117fa6
begin
	# Keeps track of the span, position, mode {1, i, -1, -i}, primes (enclosed area) path and movements along the gaussian spiral
	mutable struct Spiral
	  span::Complex{Int64}
	  position::Complex{Int64}
	  mode::Complex{Int64}
	  primes::Vector{Complex{Int64}}
	  path::Vector{Complex{Int64}}
	  movements::Int64 
	end

	# Create a spiral object from just the span (complex prime) and extent n
	function Spiral(span::Complex{Int64}, n)
	  return Spiral(span, span, 1 + 0im, gaussian_prime_list(span, n), [span], 0)
	end

	md"Define the struct spiral and default method."
end

# ╔═╡ 18bef514-8bfd-435d-9119-72ef4da89a68
begin
	# A function to move one integer unit along the Gaussian prime spiral
	function update!(s::Spiral)
	  s.position = s.position + s.mode
	  if s.position in s.primes
	    s.mode = s.mode * im
	  end
	  s.path = push!(s.path, s.position)
	  s.movements = s.movements + 1
	  return nothing
	end
	md"A function to move one integer unit along the Gaussian prime spiral."
end

# ╔═╡ ddb193b6-eeb9-423a-a5f3-9be8553841c7
begin
	# Transverse the path along the gaussian spiral, ie. return to the spanning prime
	function transverse!(s::Spiral)
	    update!(s)
	    while true
	        if s.position == s.span
	            break
	        end
	        update!(s)
	    end
	    return nothing
	end
	md"Transverse the path along the gaussian spiral, ie. return to the spanning prime"
end

# ╔═╡ cf5e6093-c757-4e6a-9f4e-b3a68d4b289d
begin
	# Function to display the spiral
	function display(s::Spiral)
	    # Create some arrays to create a dataframe
	    ar1 = 0:s.movements # get the movements
	    ar2 = s.path # Get the transverse path
	    ar3 = gaussian_prime.(s.path) # Get indicator if path elements are prime
	    
	    num_type(x) = ifelse(x == true, "prime", "composite")
	
	    # Create base dataframe for plotting
	    df = DataFrame(Movements = ar1, Points = ar2, Class = ar3)
	
	    # Get all data
	    all_data = df |> 
	    @mutate(Real_Axis = real.(_.Points)) |>
	    @mutate(Imaginary_Axis = imag.(_.Points)) |>
	    @mutate(Class = num_type.(_.Class)) |> DataFrame
	
	    # Get just primes
	    only_primes = all_data |> @filter(_.Class == "prime") |> DataFrame
	    
	    # Create Vegalite plot
	    my_plot =
	    @vlplot(
	        title = "Gaussian Prime Spiral",
	        height = 700,
	        width = 700
	    ) +
	    @vlplot(
	        data = all_data,
	        mark = {:line, color = "black", opacity = 1.0},
	        x = {"Real_Axis:q", title = "Real Axis; Span = $(s.span); Movements = $(s.movements)"},
	        y = {"Imaginary_Axis:q", title = "Imaginary Axis" },
	        order = "Movements:o" 
	        
	    ) +
	    @vlplot(
	        data = only_primes,
	        mark = {:circle, color = "red", opacity = 0.5},
	        x = "Real_Axis:q",
	        y = "Imaginary_Axis:q"
	    ) 
	    return my_plot
	end
	md"Function to display the spiral"
end

# ╔═╡ 7945ce8a-ca4d-4c22-9bc4-459dce201b45
md"## Function Usage
1. Create the Spiral object
2. Transverse the Spiral object
3. Display the Spiral object
"

# ╔═╡ f34e5252-01bb-48da-ae1e-70dffda974c4
begin
	# Create a Spiral object
	s = Spiral(5 + 23im, 300)
	md"Create Spiral Object"
end

# ╔═╡ 839cb83a-0c2c-4605-a328-78cc04ac110d
begin
	# Transverse the spiral object
	transverse!(s)
	md"Transverse the Spiral object"
end

# ╔═╡ 0809bf6b-5deb-41da-8143-7161be183c95
md"Display the Spiral object"

# ╔═╡ b5a55b98-e822-4d61-9ed3-d2d8de29fb5d
display(s)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
Primes = "27ebfcd6-29c5-5fa9-bf4b-fb8fc14df3ae"
Queryverse = "612083be-0b0f-5412-89c1-4e7c75506a58"
VegaLite = "112f6efa-9a02-5b7d-90c0-432ed331239a"

[compat]
DataFrames = "~1.3.2"
Primes = "~0.5.1"
Queryverse = "~0.7.0"
VegaLite = "~2.6.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.7.1"
manifest_format = "2.0"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[deps.Arrow]]
deps = ["CategoricalArrays", "Dates"]
git-tree-sha1 = "c86df6ed41b3bd192d663e5e0e7cac0d11fd4375"
uuid = "69666777-d1a9-59fb-9406-91d4454c9d45"
version = "0.2.4"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BinaryProvider]]
deps = ["Libdl", "Logging", "SHA"]
git-tree-sha1 = "ecdec412a9abc8db54c0efc5548c64dfce072058"
uuid = "b99e7846-7c00-51b0-8f62-c81ae34c0232"
version = "0.5.10"

[[deps.CEnum]]
git-tree-sha1 = "215a9aa4a1f23fbd05b92769fdd62559488d70e9"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.4.1"

[[deps.CSVFiles]]
deps = ["CodecZlib", "DataValues", "FileIO", "HTTP", "IterableTables", "IteratorInterfaceExtensions", "TableShowUtils", "TableTraits", "TableTraitsUtils", "TextParse"]
git-tree-sha1 = "d4dd66b73d3c811daa67587980bf45a179d16983"
uuid = "5d742f6a-9f54-50ce-8119-2520741973ca"
version = "1.0.1"

[[deps.CategoricalArrays]]
deps = ["DataAPI", "Future", "JSON", "Missings", "Printf", "Statistics", "StructTypes", "Unicode"]
git-tree-sha1 = "2ac27f59196a68070e132b25713f9a5bbc5fa0d2"
uuid = "324d7699-5711-5eae-9e2f-1d82baa6b597"
version = "0.8.3"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "9950387274246d08af38f6eef8cb5480862a435f"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.14.0"

[[deps.ChangesOfVariables]]
deps = ["ChainRulesCore", "LinearAlgebra", "Test"]
git-tree-sha1 = "bf98fa45a0a4cee295de98d4c1462be26345b9a1"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.2"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "ded953804d019afa9a3f98981d99b33e3db7b6da"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.0"

[[deps.CodecZstd]]
deps = ["CEnum", "TranscodingStreams", "Zstd_jll"]
git-tree-sha1 = "849470b337d0fa8449c21061de922386f32949d9"
uuid = "6b39b394-51ab-5f42-8807-6242bab2b4c2"
version = "0.7.2"

[[deps.Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "96b0bc6c52df76506efc8a441c6cf1adcb1babc4"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.42.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[deps.Conda]]
deps = ["Downloads", "JSON", "VersionParsing"]
git-tree-sha1 = "6e47d11ea2776bc5627421d59cdcc1296c058071"
uuid = "8f4d0f93-b110-5947-807f-2305c1781a2d"
version = "1.7.0"

[[deps.ConstructionBase]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f74e9d5388b8620b4cee35d4c5a618dd4dc547f4"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.3.0"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "cc70b17275652eb47bc9e5f81635981f13cea5c8"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.9.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "Future", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrettyTables", "Printf", "REPL", "Reexport", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "ae02104e835f219b8930c7664b8012c93475c340"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.3.2"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "3daef5523dd2e769dad2365274f760ff5f282c7d"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.11"

[[deps.DataTables]]
deps = ["DataValues", "ReadOnlyArrays", "TableShowUtils", "TableTraitsUtils"]
git-tree-sha1 = "9b069372a767fc6142feecc8e6d737d1b1de4711"
uuid = "743a1d0a-8ebc-4f23-814b-50d006366bc6"
version = "0.1.0"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.DataValues]]
deps = ["DataValueInterfaces", "Dates"]
git-tree-sha1 = "d88a19299eba280a6d062e135a43f00323ae70bf"
uuid = "e7dc6d0d-1eca-5fa6-8ad6-5aecde8b7ea5"
version = "0.4.13"

[[deps.DataVoyager]]
deps = ["DataValues", "Electron", "FilePaths", "IterableTables", "IteratorInterfaceExtensions", "JSON", "TableTraits", "Test", "URIParser", "VegaLite"]
git-tree-sha1 = "159f1d3f07225a59dd4edb8ad15e607fefac9543"
uuid = "5721bf48-af8e-5845-8445-c9e18126e773"
version = "1.0.2"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "b19534d1895d702889b219c382a6e18010797f0b"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.6"

[[deps.DoubleFloats]]
deps = ["GenericLinearAlgebra", "LinearAlgebra", "Polynomials", "Printf", "Quadmath", "Random", "Requires", "SpecialFunctions"]
git-tree-sha1 = "4c3bfdb3369bfe4fa61695b520237af97f8d6196"
uuid = "497a8b3b-efae-58df-a0af-a86822472b78"
version = "1.1.27"

[[deps.Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[deps.Electron]]
deps = ["Base64", "FilePaths", "JSON", "Pkg", "Sockets", "URIParser", "UUIDs"]
git-tree-sha1 = "a53025d3eabe23659065b3c5bba7b4ffb1327aa0"
uuid = "a1bb12fb-d4d1-54b4-b10a-ee7951ef7ad3"
version = "3.1.2"

[[deps.ExcelFiles]]
deps = ["DataValues", "Dates", "ExcelReaders", "FileIO", "IterableTables", "IteratorInterfaceExtensions", "Printf", "PyCall", "TableShowUtils", "TableTraits", "TableTraitsUtils", "XLSX"]
git-tree-sha1 = "f3e5f4279d77b74bf6aef2b53562f771cc5a0474"
uuid = "89b67f3b-d1aa-5f6f-9ca4-282e8d98620d"
version = "1.0.0"

[[deps.ExcelReaders]]
deps = ["DataValues", "Dates", "PyCall", "Test"]
git-tree-sha1 = "6f9db420dd362bd5bcea3a0f6dabf8bda587fec3"
uuid = "c04bee98-12a5-510c-87df-2a230cb6e075"
version = "0.11.0"

[[deps.EzXML]]
deps = ["Printf", "XML2_jll"]
git-tree-sha1 = "0fa3b52a04a4e210aeb1626def9c90df3ae65268"
uuid = "8f5d6c58-4d21-5cfd-889c-e3ad7ee6a615"
version = "1.1.0"

[[deps.FeatherFiles]]
deps = ["Arrow", "DataValues", "FeatherLib", "FileIO", "IterableTables", "IteratorInterfaceExtensions", "TableShowUtils", "TableTraits", "TableTraitsUtils", "Test"]
git-tree-sha1 = "a2f2b57b23be259d7839bebae2b8f7bba4851a9b"
uuid = "b675d258-116a-5741-b937-b79f054b0542"
version = "0.8.1"

[[deps.FeatherLib]]
deps = ["Arrow", "CategoricalArrays", "Dates", "FlatBuffers", "Mmap", "Random"]
git-tree-sha1 = "a3d0c5ca2f08bc8fae4394775f371f8e032149ab"
uuid = "409f5150-fb84-534f-94db-80d1e10f57e1"
version = "0.2.0"

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "80ced645013a5dbdc52cf70329399c35ce007fae"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.13.0"

[[deps.FilePaths]]
deps = ["FilePathsBase", "MacroTools", "Reexport", "Requires"]
git-tree-sha1 = "919d9412dbf53a2e6fe74af62a73ceed0bce0629"
uuid = "8fc22ac5-c921-52a6-82fd-178b2807b824"
version = "0.8.3"

[[deps.FilePathsBase]]
deps = ["Compat", "Dates", "Mmap", "Printf", "Test", "UUIDs"]
git-tree-sha1 = "129b104185df66e408edd6625d480b7f9e9823a0"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.18"

[[deps.FlatBuffers]]
deps = ["Parameters", "Test"]
git-tree-sha1 = "8582924ac52011d08da9cf1e67f13a71dbbc2594"
uuid = "53afe959-3a16-52fa-a8da-cf864710bae9"
version = "0.5.4"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.GenericLinearAlgebra]]
deps = ["LinearAlgebra", "Printf", "Random", "libblastrampoline_jll"]
git-tree-sha1 = "67bf18c8c2548e4a61ed918dfb567e65997e0f00"
uuid = "14197337-ba66-59df-a3e3-ca00e7dcff7a"
version = "0.3.0"

[[deps.HTTP]]
deps = ["Base64", "Dates", "IniFile", "Logging", "MbedTLS", "NetworkOptions", "Sockets", "URIs"]
git-tree-sha1 = "0fa77022fe4b511826b39c894c90daf5fce3334a"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "0.9.17"

[[deps.IniFile]]
git-tree-sha1 = "f550e6e32074c939295eb5ea6de31849ac2c9625"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.1"

[[deps.InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "61feba885fac3a407465726d0c330b3055df897f"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.1.2"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "91b5dcf362c5add98049e6c29ee756910b03051d"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.3"

[[deps.InvertedIndices]]
git-tree-sha1 = "bee5f1ef5bf65df56bdd2e40447590b272a5471f"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.1.0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "7fd44fd4ff43fc60815f8e764c0f352b83c49151"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.1"

[[deps.IterableTables]]
deps = ["DataValues", "IteratorInterfaceExtensions", "Requires", "TableTraits", "TableTraitsUtils"]
git-tree-sha1 = "70300b876b2cebde43ebc0df42bc8c94a144e1b4"
uuid = "1c8ee90f-4401-5389-894e-7a04a3dc0f4d"
version = "1.0.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

[[deps.JSONSchema]]
deps = ["HTTP", "JSON", "URIs"]
git-tree-sha1 = "2f49f7f86762a0fbbeef84912265a1ae61c4ef80"
uuid = "7d188eb4-7ad8-530c-ae41-71a32a6d4692"
version = "0.3.4"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "42b62845d70a619f063a7da093d995ec8e15e778"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+1"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "58f25e56b706f95125dcb796f39e1fb01d913a71"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.10"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "3d3e902b31198a27340d0bf00d6ac452866021cf"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.9"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "Random", "Sockets"]
git-tree-sha1 = "1c38e51c3d08ef2278062ebceade0e46cefc96fe"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.0.3"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[deps.MemPool]]
deps = ["DataStructures", "Distributed", "Mmap", "Random", "Serialization", "Sockets", "Test"]
git-tree-sha1 = "d52799152697059353a8eac1000d32ba8d92aa25"
uuid = "f9f48841-c794-520a-933b-121f7ba6ed94"
version = "0.2.0"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "f8c673ccc215eb50fcadb285f522420e29e69e1c"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "0.4.5"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[deps.MutableArithmetics]]
deps = ["LinearAlgebra", "SparseArrays", "Test"]
git-tree-sha1 = "ba8c0f8732a24facba709388c74ba99dcbfdda1e"
uuid = "d8a4904e-b15c-11e9-3269-09a3773c0cb0"
version = "1.0.0"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[deps.NodeJS]]
deps = ["Pkg"]
git-tree-sha1 = "905224bbdd4b555c69bb964514cfa387616f0d3a"
uuid = "2bd173c7-0d6d-553b-b6af-13a54713934c"
version = "1.3.0"

[[deps.Nullables]]
git-tree-sha1 = "8f87854cc8f3685a60689d8edecaa29d2251979b"
uuid = "4d1e1d77-625e-5b40-9113-a560ec7a8ecd"
version = "1.0.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.Parameters]]
deps = ["OrderedCollections", "UnPack"]
git-tree-sha1 = "34c0e9ad262e5f7fc75b10a9952ca7692cfc5fbe"
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.3"

[[deps.Parquet]]
deps = ["CodecZlib", "CodecZstd", "Dates", "MemPool", "ProtoBuf", "Snappy", "Thrift"]
git-tree-sha1 = "3dc3ed38c932f5e00d75a5af354438c6b80d973d"
uuid = "626c502c-15b0-58ad-a749-f091afb673ae"
version = "0.4.0"

[[deps.ParquetFiles]]
deps = ["DataValues", "FileIO", "IterableTables", "IteratorInterfaceExtensions", "Parquet", "TableShowUtils", "TableTraits", "Test"]
git-tree-sha1 = "7b4414214f41e2ae7844ea827bfd4ec7ae71e749"
uuid = "46a55296-af5a-53b0-aaa0-97023b66127f"
version = "0.2.0"

[[deps.Parsers]]
deps = ["Dates"]
git-tree-sha1 = "85b5da0fa43588c75bb1ff986493443f821c70b7"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.2.3"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[deps.Polynomials]]
deps = ["LinearAlgebra", "MutableArithmetics", "RecipesBase"]
git-tree-sha1 = "0107e2f7f90cc7f756fee8a304987c574bbd7583"
uuid = "f27b6e38-b328-58d1-80ce-0feddd5e7a45"
version = "3.0.0"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "db3a23166af8aebf4db5ef87ac5b00d36eb771e2"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.0"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "d3538e7f8a790dc8903519090857ef8e1283eecd"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.2.5"

[[deps.PrettyTables]]
deps = ["Crayons", "Formatting", "Markdown", "Reexport", "Tables"]
git-tree-sha1 = "dfb54c4e414caa595a1f2ed759b160f5a3ddcba5"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "1.3.1"

[[deps.Primes]]
git-tree-sha1 = "984a3ee07d47d401e0b823b7d30546792439070a"
uuid = "27ebfcd6-29c5-5fa9-bf4b-fb8fc14df3ae"
version = "0.5.1"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.ProtoBuf]]
git-tree-sha1 = "51b74991da46594fb411a715e7e092bef50b99ff"
uuid = "3349acd9-ac6a-5e09-bcdb-63829b23a429"
version = "0.8.0"

[[deps.PyCall]]
deps = ["Conda", "Dates", "Libdl", "LinearAlgebra", "MacroTools", "Serialization", "VersionParsing"]
git-tree-sha1 = "1fc929f47d7c151c839c5fc1375929766fb8edcc"
uuid = "438e738f-606a-5dbb-bf0a-cddfbfd45ab0"
version = "1.93.1"

[[deps.Quadmath]]
deps = ["Printf", "Random", "Requires"]
git-tree-sha1 = "5a8f74af8eae654086a1d058b4ec94ff192e3de0"
uuid = "be4d8f0f-7fa4-5f49-b795-2f01399ab2dd"
version = "0.5.5"

[[deps.Query]]
deps = ["DataValues", "IterableTables", "MacroTools", "QueryOperators", "Statistics"]
git-tree-sha1 = "a66aa7ca6f5c29f0e303ccef5c8bd55067df9bbe"
uuid = "1a8c2f83-1ff3-5112-b086-8aa67b057ba1"
version = "1.0.0"

[[deps.QueryOperators]]
deps = ["DataStructures", "DataValues", "IteratorInterfaceExtensions", "TableShowUtils"]
git-tree-sha1 = "911c64c204e7ecabfd1872eb93c49b4e7c701f02"
uuid = "2aef5ad7-51ca-5a8f-8e88-e75cf067b44b"
version = "0.9.3"

[[deps.Queryverse]]
deps = ["CSVFiles", "DataFrames", "DataTables", "DataValues", "DataVoyager", "ExcelFiles", "FeatherFiles", "FileIO", "IterableTables", "ParquetFiles", "Query", "Reexport", "StatFiles", "VegaLite"]
git-tree-sha1 = "c9654374d9c5bd053c3f286b4c41a0f2b3fe161e"
uuid = "612083be-0b0f-5412-89c1-4e7c75506a58"
version = "0.7.0"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.ReadOnlyArrays]]
deps = ["SparseArrays", "Test"]
git-tree-sha1 = "65f17072a35c2be7ac8941aeeae489013212e71f"
uuid = "988b38a3-91fc-5605-94a2-ee2116b3bd83"
version = "0.1.1"

[[deps.ReadStat]]
deps = ["DataValues", "Dates", "ReadStat_jll"]
git-tree-sha1 = "f8652515b68572d3362ee38e32245249413fb2d7"
uuid = "d71aba96-b539-5138-91ee-935c3ee1374c"
version = "1.1.1"

[[deps.ReadStat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "afd287b1031406b3ec5d835a60b388ceb041bb63"
uuid = "a4dc8951-f1cc-5499-9034-9ec1c3e64557"
version = "1.1.5+0"

[[deps.RecipesBase]]
git-tree-sha1 = "6bf3f380ff52ce0832ddd3a2a7b9538ed1bcca7d"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.2.1"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Setfield]]
deps = ["ConstructionBase", "Future", "MacroTools", "Requires"]
git-tree-sha1 = "fca29e68c5062722b5b4435594c3d1ba557072a3"
uuid = "efcf1570-3423-57d1-acb7-fd33fddbac46"
version = "0.7.1"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.Snappy]]
deps = ["BinaryProvider", "Libdl", "Random", "Test"]
git-tree-sha1 = "25620a91907972a05863941d6028791c2613888e"
uuid = "59d4ed8c-697a-5b28-a4c7-fe95c22820f9"
version = "0.3.0"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "b3363d7460f7d098ca0912c69b082f75625d7508"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.0.1"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SpecialFunctions]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "5ba658aeecaaf96923dce0da9e703bd1fe7666f9"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.1.4"

[[deps.StatFiles]]
deps = ["DataValues", "FileIO", "IterableTables", "IteratorInterfaceExtensions", "ReadStat", "TableShowUtils", "TableTraits", "TableTraitsUtils", "Test"]
git-tree-sha1 = "28466ea10caec61c476a262172319d2edf248187"
uuid = "1463e38c-9381-5320-bcd4-4134955f093a"
version = "0.8.0"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StructTypes]]
deps = ["Dates", "UUIDs"]
git-tree-sha1 = "d24a825a95a6d98c385001212dc9020d609f2d4f"
uuid = "856f2bd8-1eba-4b0a-8007-ebc267875bd4"
version = "1.8.1"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[deps.TableShowUtils]]
deps = ["DataValues", "Dates", "JSON", "Markdown", "Test"]
git-tree-sha1 = "14c54e1e96431fb87f0d2f5983f090f1b9d06457"
uuid = "5e66a065-1f0a-5976-b372-e0b8c017ca10"
version = "0.2.5"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.TableTraitsUtils]]
deps = ["DataValues", "IteratorInterfaceExtensions", "Missings", "TableTraits"]
git-tree-sha1 = "78fecfe140d7abb480b53a44f3f85b6aa373c293"
uuid = "382cd787-c1b6-5bf2-a167-d5b971a19bda"
version = "1.0.2"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "5ce79ce186cc678bbb5c5681ca3379d1ddae11a1"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.7.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TextParse]]
deps = ["CodecZlib", "DataStructures", "Dates", "DoubleFloats", "Mmap", "Nullables", "WeakRefStrings"]
git-tree-sha1 = "eb1f4fb185c8644faa2d18d14c72f2c24412415f"
uuid = "e0df1984-e451-5cb5-8b61-797a481e67e3"
version = "1.0.2"

[[deps.Thrift]]
deps = ["BinaryProvider", "Distributed", "Sockets"]
git-tree-sha1 = "c3dd01c6067985a77fef761839203838ac12825b"
uuid = "8d9c9c80-f77e-5080-9541-c6f69d204e22"
version = "0.6.2"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "216b95ea110b5972db65aa90f88d8d89dcb8851c"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.6"

[[deps.URIParser]]
deps = ["Unicode"]
git-tree-sha1 = "53a9f49546b8d2dd2e688d216421d050c9a31d0d"
uuid = "30578b45-9adc-5946-b283-645ec420af67"
version = "0.4.1"

[[deps.URIs]]
git-tree-sha1 = "97bbe755a53fe859669cd907f2d96aee8d2c1355"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.3.0"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.Vega]]
deps = ["DataStructures", "DataValues", "Dates", "FileIO", "FilePaths", "IteratorInterfaceExtensions", "JSON", "JSONSchema", "MacroTools", "NodeJS", "Pkg", "REPL", "Random", "Setfield", "TableTraits", "TableTraitsUtils", "URIParser"]
git-tree-sha1 = "43f83d3119a868874d18da6bca0f4b5b6aae53f7"
uuid = "239c3e63-733f-47ad-beb7-a12fde22c578"
version = "2.3.0"

[[deps.VegaLite]]
deps = ["Base64", "DataStructures", "DataValues", "Dates", "FileIO", "FilePaths", "IteratorInterfaceExtensions", "JSON", "MacroTools", "NodeJS", "Pkg", "REPL", "Random", "TableTraits", "TableTraitsUtils", "URIParser", "Vega"]
git-tree-sha1 = "3e23f28af36da21bfb4acef08b144f92ad205660"
uuid = "112f6efa-9a02-5b7d-90c0-432ed331239a"
version = "2.6.0"

[[deps.VersionParsing]]
git-tree-sha1 = "58d6e80b4ee071f5efd07fda82cb9fbe17200868"
uuid = "81def892-9a0e-5fdd-b105-ffc91e053289"
version = "1.3.0"

[[deps.WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "b1be2855ed9ed8eac54e5caff2afcdb442d52c23"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.2"

[[deps.XLSX]]
deps = ["Dates", "EzXML", "Printf", "Tables", "ZipFile"]
git-tree-sha1 = "2af4b3e329b51f1a41acb346e64156f904860a74"
uuid = "fdbf4ff8-1666-58a4-91e7-1b58723a45e0"
version = "0.7.9"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "1acf5bdf07aa0907e0a37d3718bb88d4b687b74a"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.9.12+0"

[[deps.ZipFile]]
deps = ["Libdl", "Printf", "Zlib_jll"]
git-tree-sha1 = "3593e69e469d2111389a9bd06bac1f3d730ac6de"
uuid = "a5390f91-8eb1-5f08-bee0-b1d1ffed6cea"
version = "0.9.4"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e45044cd873ded54b6a5bac0eb5c971392cf1927"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.2+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
"""

# ╔═╡ Cell order:
# ╠═7e1248c4-912e-4c52-91c3-d22d3dc35181
# ╠═f7369057-8e79-4384-baaa-c127be359da2
# ╠═ae93dec4-aa36-11ec-3f1a-8332a0276b8d
# ╠═9bc8ea38-cf0b-4ee1-b22e-fb6ff15637ad
# ╠═718bb8ad-8fe5-4cc5-b2b0-3bedb9894c88
# ╠═1e77c48b-964c-464a-90b9-b8824ba6f7c3
# ╠═70805663-76a9-494c-b4e8-be072e117fa6
# ╠═18bef514-8bfd-435d-9119-72ef4da89a68
# ╠═ddb193b6-eeb9-423a-a5f3-9be8553841c7
# ╠═cf5e6093-c757-4e6a-9f4e-b3a68d4b289d
# ╠═7945ce8a-ca4d-4c22-9bc4-459dce201b45
# ╠═f34e5252-01bb-48da-ae1e-70dffda974c4
# ╠═839cb83a-0c2c-4605-a328-78cc04ac110d
# ╠═0809bf6b-5deb-41da-8143-7161be183c95
# ╠═b5a55b98-e822-4d61-9ed3-d2d8de29fb5d
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
