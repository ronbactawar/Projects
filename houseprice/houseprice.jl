### A Pluto.jl notebook ###
# v0.14.8

using Markdown
using InteractiveUtils

# ╔═╡ 02221a8e-5f2d-11eb-0736-17dd58b3bf81
begin
	using Pkg
	Pkg.activate("MLJ_environment", shared=true)
	using StatsBase: corkendall
	using DataFrames
	using Queryverse
	using VegaLite
	using MLJ
end

# ╔═╡ 71be8616-2f30-48dd-94cc-4544896e6e79
showhidebutton = html"""
<style>
body.hide-all-code pluto-input {display: none !important;}
</style>

<button onClick="document.body.classList.toggle('hide-all-code')">Show/hide all code</button> 

<script>
document.body.classList.add('hide-all-code')
</script>

"""

# ╔═╡ 28470ba4-9a14-4aa6-a042-1a49d5c3b0bb
html"""<style>
main {
    max-width: 1000px;
    align-self: center;
  
}
"""

# ╔═╡ f671d676-af5c-4192-a2c3-7fcd3393e1fe
md"
# Home Price Prediction
" 

# ╔═╡ 0674f088-5f2e-11eb-15fd-1105e972504e
md"## Objective

The objective is to build a regression model which predicts houseprice from several housing variables.

"

# ╔═╡ 9b776da2-5f2e-11eb-03b5-5f6d33e1f080
md"
## Data Processing

Area and Prices are quantitative variables measured in square-feet and dollars respectively. Garage, FirePlace and Baths refers to the number of this items in a specific house. City is a qualitative variable indicating one of 3 different cities. All remaining variable indicate the presence (1) of absence (0) of that feature.

"

# ╔═╡ 37658576-5f2f-11eb-26ff-0922333ddcad
begin
	# Load the data and show a preview
	houseprice = Queryverse.load("/home/chigball/Data/houseprice.csv") |> DataFrame
	describe(houseprice)
end

# ╔═╡ 7ece7140-5f2f-11eb-199d-1d1f9c6f2c8a
md"

## Data Exploration
Data was manipulated to investigate one of three things:

1. Distribution of house price
2. How area affects the average house price
3. What house price variable contribute to house price


"

# ╔═╡ 01f3be5c-5f49-11eb-287c-fb2fa0de4fd4
begin
	# Dicts for code manipulation 
	D1 = Dict("001" => "Indian", "010" => "Black", "100" => "White")
	D2 = Dict(0 => "No", 1 => "Yes")
	
	# Manipulate data for data exploration
	houseprice_ex = houseprice |> 
	@mutate(MarbleType = string(_.WhiteMarble) * string(_.BlackMarble) * string(_.IndianMarble)) |> 
	@mutate(MarbleType = D1[_.MarbleType]) |>
	@mutate(Floors = D2[_.Floors]) |> # Floors
	@mutate(Solar = D2[_.Solar]) |> # Solar
	@mutate(Electric = D2[_.Electric]) |> # Electric
	@mutate(Fiber = D2[_.Fiber]) |> # Fiber
	@mutate(GlassDoors = D2[_.GlassDoors]) |> # GlassDoors
	@mutate(SwimingPool = D2[_.SwimingPool]) |> # SwimingPool
	@mutate(Garden = D2[_.Garden]) |> # Garden
	@select(1:4, 17, 8:16) |> DataFrame
	
	# Code creates expressions for aggregation and plotting of dependent variable against average price 
	function aggprice(v::Symbol, x::String)
		:(
		houseprice_ex |> 
		@groupby(_.$v) |> 
		@map({$v = key(_), Avg_Price = mean(_.Prices)}) |> 
		@orderby(_.$v) |> 
		@vlplot(
		mark = :bar,
		x = $x,
		y = {"Avg_Price:q", title = "Average Price"}
		)  
		)
	end
	
	# Data plots of dependent variables vs price
	Garage = eval(aggprice(:Garage, "Garage:n")) # Garage y
	FirePlace = eval(aggprice(:FirePlace, "FirePlace:n")) # FirePlace y
	Baths = eval(aggprice(:Baths, "Baths:n")) # Baths y
	MarbleType = eval(aggprice(:MarbleType, "MarbleType:n")) # MarbleType yy
	Floors = eval(aggprice(:Floors, "Floors:n")) # Floors yy
	City = eval(aggprice(:City, "City:n")) # City y
	Solar = eval(aggprice(:Solar, "Solar:n")) # Solar n
	Electric = eval(aggprice(:Electric, "Electric:n")) # Electric 0.5y
	Fiber = eval(aggprice(:Fiber, "Fiber:n")) # Fiber yy
	GlassDoors = eval(aggprice(:GlassDoors, "GlassDoors:n")) # GlassDoors 0.5y
	SwimingPool = eval(aggprice(:SwimingPool, "SwimingPool:n")) # SwimingPool n
	Garden = eval(aggprice(:Garden, "Garden:n")); # Garden n
	
	# Average House Price by Area Range
	ahp = houseprice_ex |> 
	@take(10000) |>
	@vlplot(
	mark = {:bar},
	x = {"Area:n", bin={maxbins=20}, title = "Area Range"},
	y = {"average(Prices)", scale = {zero = false}, title = "Average House Price"},
	height = 200,
	width = 400,
	title = "Average House Price by Area Range"
	)
	
	
	# House Price Density Plot
	houseprice_dp = houseprice_ex |> 
	@take(10000) |>
	@vlplot(
	mark = :area, # It's an area plot
	transform = [{density = "Prices"}], # For counts add in : counts = true
	x = {"value:q", title = "House Price"},
	y = {"density:q"},  # Density variable created
	width = 400,
	title = "House Price Density Plot"
	)
end;

# ╔═╡ 66fa624e-5f47-11eb-0e88-53484161f6a6
md"The distribution of house price is generally bell shaped, with a high number house-prices in the 35,000 to 40,000 range."

# ╔═╡ a53dd96e-5f47-11eb-3ea0-0788d12dff13
houseprice_dp

# ╔═╡ ef09109a-5f47-11eb-284f-014889170ef4
md"Average house prices generally increase with area range, however that trend is broken in the range 80-120 sqft as well as 180-200 sqft."

# ╔═╡ 6e9ca784-5f48-11eb-2dc5-433b85aac6a8
ahp 

# ╔═╡ fa39b260-5f4c-11eb-0575-a7f84b9aa954
md"Having white marble type and a fiber connection tends to be a strong predictor of price. Variables like Garage, FirePlace, Baths and Floors which increase with Area also tend to predict higher prices. Non predictors of price seem to includes features like Solar SwimmingPool and Garden."

# ╔═╡ 16d43366-5f4d-11eb-37a7-adea621cdfc6
begin
@vlplot("title"="Variable Impacts on House Prices") + 
[[Garage FirePlace Baths MarbleType] ; [Floors City Electric Fiber GlassDoors] ; [Solar SwimingPool Garden]] 
end

# ╔═╡ 16b7e166-5f4d-11eb-2fb7-b7e056adf40c
md"
## Model Building
The data was split into a training and testing set (70/30). The data science pipeline requires converting variables into a continuous type, then fitting a EvoTree Regressor model to predict house prices, using a max_dept of 8.
"

# ╔═╡ 169ad614-5f4d-11eb-3665-6b4679f0caf7
begin
	# Filter data for useful variables and convert Prices to float
	houseprice_mod = houseprice |>@select(-:Solar, -:SwimingPool, -:Garden) |> 
	@mutate(Prices = float(_.Prices)) |> DataFrame;
	
	# Select X and y for modeling
	X = houseprice_mod |> @select(-:Prices) |> DataFrame
	y = houseprice_mod.Prices
	
	# Create an index for model and validation sets
	m, v = partition(eachindex(y), 0.7, shuffle=true);
	
	# Create model/training sets
	Xm = X[m,:]
	ym = y[m]
	
	# Create validation/testing sets
	Xv = X[v,:]
	yv = y[v]
	
	# load EvoTreeRegressor model
	Tree = @load EvoTreeRegressor pkg="EvoTrees"
	

end;

# ╔═╡ a930518a-f33b-4af1-923c-cfc652422359
begin
    # Create pipeline that converts inputs into continous and fits an EvoTreeRegressor
	pipe = @pipeline(
	X -> coerce(X, Count => Continuous),
	Tree(max_depth = 8),
	prediction_type=:deterministic
	);
	
	# Fit machine
	mach = machine(pipe, Xm, ym);
	fit!(mach)
	
md""
end

# ╔═╡ e0ac4d71-d502-4876-b085-154d695bd5ca
pipe

# ╔═╡ 16691c8c-5f4d-11eb-0594-f1913d78ee84
md"
# Cross Validation
The number of rounds of training (nrounds) was plotted on a learning curve. After about 120 rounds there are diminishing returns for a low rms error, as a result the original model will be retrained with nrounds=128 rather than nrounds=10.

"

# ╔═╡ f4015f20-5f61-11eb-16c4-859573f8d2ab
begin
# Function to plot learning curves
function plot_lc(curve::NamedTuple, measure::String)
  
  # Create a dataframe from data
DataFrame(parameter_values = curve.parameter_values, measurements = curve.measurements) |>
@vlplot(
mark = {:line, tooltip = true, point = true},
x = {"parameter_values:q", title = curve.parameter_name},
y = {"measurements:q", title = measure},
title = "Learning Curve",
height = 250,
width = 260
)  
end

# Generate learning curve
r = range(pipe, :(evo_tree_regressor.nrounds); values = 1:20:130)
curve = learning_curve(mach; range=r, resampling=CV(), measure=rms)
end;

# ╔═╡ ec9ac81e-5f63-11eb-2f14-a3b015a21b4a
md"
A sufficient number of rounds is needed to achieve rms > 300, as indicated by the chart below
"

# ╔═╡ f3e2ea54-5f61-11eb-037f-a9cfe47f6ffa
plot_lc(curve, "rms")

# ╔═╡ f3be513c-5f61-11eb-1a77-abaa3bcf7fec
begin
	# Retrain model at nrounds = 128
	pipe.evo_tree_regressor.nrounds = 128
	mach2 = machine(pipe, Xm, ym);
	fit!(mach2);
end;

# ╔═╡ b128d932-5f64-11eb-3e00-0f81dac4d709
md"
Model Evaluation
Evaluation was done using the metrics rms/mae and a 70% shuffled resampling. A reasonable error was achieved for both metrics.
"

# ╔═╡ d36f8504-5f64-11eb-108c-d75388d40759
begin	
	# Model Evaluation
	ev = evaluate!(mach2, 
	  resampling=Holdout(fraction_train=0.7, shuffle=true, rng=1234),
	  measures=[rms, mae],
	  verbosity = 0
	);
end;

# ╔═╡ b432fd02-5f74-11eb-05fd-3784cecbe6d8
DataFrame(measure=ev[1], value = ev[2])

# ╔═╡ c291965a-60bd-11eb-32cd-095930757708
begin
	# Model Evaluation on test data
	yp = collect(predict(mach2, Xv))
	RMS = round(rms(yp, yv), digits = 0) 
	COR = round(corkendall(yp, yv), digits = 3) 
end;

# ╔═╡ c27c1834-60bd-11eb-065c-cfd56a1ade95
md"
A rms error of $(RMS) and a corelation of $(COR)  was also achieved for the test set.
"

# ╔═╡ 1cdb81b8-670b-11eb-0bc6-597120b7daa5
md"
## Feature Importance
Feature selection was done using EvoTree's normalized gain by feature. The most important variables are shown below. Having more floors along with the presence of fiber optics and white marble relates to higher prices. 
"

# ╔═╡ 411a026a-6bf7-45f8-929f-8e3b9fef77ac
begin
	# A function to extract the feature importance from a mach object of an evotree classifier
	function Importance(mach::Machine)
		df = report(mach).evo_tree_regressor |> DataFrame |>
		@mutate(Feature = first.(_.feature_importances)) |>
		@mutate(Importance = last.(_.feature_importances)) |>
		@mutate(Importance = round.(_.Importance, digits = 2)) |>
		@filter(_.Importance > 0) |> 
		@select(:Feature, :Importance) |> 
		@vlplot(
			x = "Importance:q",
			y = {"Feature:n", sort = "-x"},
			mark = {:bar, tooltops = true},
			height = 300,
			title = "Feature Importance Ranking"    
		)
	end;
md""
end


# ╔═╡ a3d3a23f-0d34-42b8-9df9-b63d6060b986
# Plot the feature importance ranking
Importance(mach2)

# ╔═╡ Cell order:
# ╠═71be8616-2f30-48dd-94cc-4544896e6e79
# ╠═28470ba4-9a14-4aa6-a042-1a49d5c3b0bb
# ╟─02221a8e-5f2d-11eb-0736-17dd58b3bf81
# ╟─f671d676-af5c-4192-a2c3-7fcd3393e1fe
# ╟─0674f088-5f2e-11eb-15fd-1105e972504e
# ╟─9b776da2-5f2e-11eb-03b5-5f6d33e1f080
# ╟─37658576-5f2f-11eb-26ff-0922333ddcad
# ╟─7ece7140-5f2f-11eb-199d-1d1f9c6f2c8a
# ╠═01f3be5c-5f49-11eb-287c-fb2fa0de4fd4
# ╟─66fa624e-5f47-11eb-0e88-53484161f6a6
# ╠═a53dd96e-5f47-11eb-3ea0-0788d12dff13
# ╟─ef09109a-5f47-11eb-284f-014889170ef4
# ╠═6e9ca784-5f48-11eb-2dc5-433b85aac6a8
# ╟─fa39b260-5f4c-11eb-0575-a7f84b9aa954
# ╠═16d43366-5f4d-11eb-37a7-adea621cdfc6
# ╟─16b7e166-5f4d-11eb-2fb7-b7e056adf40c
# ╠═169ad614-5f4d-11eb-3665-6b4679f0caf7
# ╠═a930518a-f33b-4af1-923c-cfc652422359
# ╠═e0ac4d71-d502-4876-b085-154d695bd5ca
# ╠═16691c8c-5f4d-11eb-0594-f1913d78ee84
# ╟─f4015f20-5f61-11eb-16c4-859573f8d2ab
# ╟─ec9ac81e-5f63-11eb-2f14-a3b015a21b4a
# ╠═f3e2ea54-5f61-11eb-037f-a9cfe47f6ffa
# ╠═f3be513c-5f61-11eb-1a77-abaa3bcf7fec
# ╟─b128d932-5f64-11eb-3e00-0f81dac4d709
# ╠═d36f8504-5f64-11eb-108c-d75388d40759
# ╠═b432fd02-5f74-11eb-05fd-3784cecbe6d8
# ╠═c291965a-60bd-11eb-32cd-095930757708
# ╠═c27c1834-60bd-11eb-065c-cfd56a1ade95
# ╟─1cdb81b8-670b-11eb-0bc6-597120b7daa5
# ╠═411a026a-6bf7-45f8-929f-8e3b9fef77ac
# ╠═a3d3a23f-0d34-42b8-9df9-b63d6060b986
