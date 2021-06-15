### A Pluto.jl notebook ###
# v0.14.7

using Markdown
using InteractiveUtils

# ╔═╡ ddfd4874-cad7-11eb-304a-35d3cbefc98e
begin
	# Packages used
	using Pkg
	Pkg.activate("MLJ_environment", shared=true)
	using Statistics
	using StatsBase: corkendall
	using DataFrames
	using Queryverse
	using VegaLite
	using MLJ
end

# ╔═╡ 785014f4-e0c6-4523-b548-90f0aae9ad27
showhidebutton = html"""
<style>
body.hide-all-code pluto-input {display: none !important;}
</style>

<button onClick="document.body.classList.toggle('hide-all-code')">Show/hide all code</button> 

<script>
document.body.classList.add('hide-all-code')
</script>

"""

# ╔═╡ 72e92e89-c5f3-40fc-9403-fd7938e0ffd7
html"""<style>
main {
    max-width: 1000px;
    align-self: center;
  
}
"""

# ╔═╡ 25ebaa52-1aab-4fb9-b41c-d20f51e48554
md"
# Runtime of a Matrix Product
"

# ╔═╡ ce12b1da-54bc-4d1e-ae15-29267dae4e08
md"
## Objective
The objective is to predict the runtime (milliseconds) of a matrix-matrix product A*B = C, where all matrices have size 2048 x 2048, using a parameterizable SGEMM GPU kernel with 261400 possible parameter combinations. For each tested combination, 4 runs were performed and their results are reported as the 4 last columns. For this analysis the predictor variable will simply be called runtime and will be aggregated mean of the four runtimes.
"

# ╔═╡ 12897db9-989b-43d2-8913-60b15e46ef39
md"

## Data
The data consist of 241600 instances over 15 variables; 14 of which will be used to predict runtime.  Variable descriptions are provided below. 

* The data was loaded from a .csv file called sgemm_product.csv
* A new variable called Runtime was created by averaging the 4 runtimes (Runs)
* Rows were shuffled in preparation of machine learning and statistical analysis

**Variable**|**Data Type**|**Description**
:-----:|:-----:|:-----:
MWG/NWG|Integer|Per-matrix 2D tiling at workgroup level: {16, 32, 64, 128}
KWG|Integer|Inner dimension of 2D tiling at workgroup level: {16, 32} 
MDIMC/NDIMC|Integer|Local workgroup size: {8, 16, 32} 
MDIMA/NDIMB|Integer|Local memory shape: {8, 16, 32} 
KWI|Integer|Kernel loop unrolling factor: {2, 8} 
VWM/VWN|Integer|Per-matrix vector widths for loading and storing: {1, 2, 4, 8} 
STRM/STRN|Categorical|Enable stride for accessing off-chip memory within a single thread: {0, 1} 
SA/SB|Categorical|Per-matrix manual caching of the 2D workgroup tile: {0, 1} 
Run1/Run2/Run3/Run4|Float|Performance times in milliseconds for 4 independent runs using the same parameters
Runtime|Float|The average value of the 4 runtimes

"

# ╔═╡ 174ba3e4-bb41-45dd-b30d-262a070fd49e
begin
	# Load the data and create Runtime variable
	data = Queryverse.load("/home/chigball/Data/sgemm_product.csv") |>
	@mutate(Runtime = (_.Run1 + _.Run2 + _.Run3 + _.Run4) / 4) |> 
	@select(1:14, 19) |> DataFrame
	
	# Shuffle the data
	data = data[shuffle(axes(data, 1)), :]
	
	# Data Preview
	data_prev = data |> @take(10)
	
md"
Here is a preview of the data		
"
end

# ╔═╡ f556b63b-ae67-4eb5-9f77-c3b980cc12ce
data_prev

# ╔═╡ e2676718-dfa9-4f54-8fd9-904b28323ece
md"
## Exploration
How is runtime impacted by different features?  This data was visualized with a series of circle plots and bar charts.  Judging from these charts, it appears that MWG/NWG, MDIMC/NDIMC, and VWM/VWN are impactful variables.  Variable importance will also be revisited via the regression tree via modeling. 
"

# ╔═╡ 4095c382-087b-43df-9665-f3f72d05b533
begin
	# Function to plot circle plots
	function circle_plot(m::String, n::String, data::Symbol)
	:(
		@vlplot(
		data = $data,
		mark = {:circle, tooltips = true},
		y = {$m, sort = "-y"},
		x = $n,
		size = "mean(Runtime)",
		color =  "mean(Runtime)",
		height = 200,
		width = 200
		)
	)
	end;

	# Function to plot bar plots
	function bar_plot(x::String, data::Symbol)
	:(
	@vlplot(
		data = $data,
		mark = :bar,
		y = "mean(Runtime)",
		x = $x,
		height = 200,
		width = 200
		)  
	)   
	end;
md""
end

# ╔═╡ 9ef71868-0832-4ce1-80bc-8ae0f9d9bf52
begin
	# Use a random sample of 3000 for plotting
	data_ex = data |> @take(3000) |> DataFrame;

	# Come up with 8 graphs to plot
	p1 = circle_plot("MWG:o", "NWG:o", :data_ex) |> eval;
	p2 = circle_plot("MDIMC:o", "NDIMC:o", :data_ex) |> eval;
	p3 = circle_plot("MDIMA:o", "NDIMB:o", :data_ex) |> eval;
	p4 = circle_plot("VWM:o", "VWN:o", :data_ex) |> eval;
	p5 = circle_plot("STRM:o", "STRN:o", :data_ex) |> eval;
	p6 = circle_plot("SA:o", "SB:o", :data_ex) |> eval;
	p7 = bar_plot("KWG:o", :data_ex) |> eval;
	p8 = bar_plot("KWI:o", :data_ex) |> eval;
	
	@vlplot(title={text = "Mean Runtime by Feature", fontSize = 20, anchor = "middle"}) + [[p1 p2 p3] ; [p4 p5 p6] ; [p7 p8]]	
	

end		


# ╔═╡ 418e21cf-8cb6-4325-927a-fd8686c1fa81
md"
## Model Building

The data was split into a training and testing set (70/30) and a EvoTree Regressor model built to predict runtime, initially using a max_dept of 8 and nrounds of 10.  The schema suggest a need for a Count to Continous conversion for an EvoTree ML pipeline, since EvoTree only accepts Continous datatypes for its input.
"

# ╔═╡ e92deacb-8929-4aad-aa4d-c06fc059df2d
begin
	# Select X and y for modeling
	X = data |> @select(-:Runtime) |> DataFrame;
	y = data.Runtime;
	schema(X)
end

# ╔═╡ 6596661b-34f5-45a7-8ee3-48764b399b95
begin
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
	md""		
end

# ╔═╡ 90cf6ee5-5b53-43a9-b91b-56da1554438c
md"
Here are the current parameters of the EvoTreeRegressor.  We begin with max_depth = 8 and nbins = 64.

"

# ╔═╡ 2694133f-1e5f-4764-9b92-7d0f909f1fb1
begin
	# Create pipeline that converts inputs into continous and fits an EvoTreeRegressor
	pipe = @pipeline(
		X -> coerce(X, Count => Continuous),
		Tree(max_depth = 8),
		prediction_type = :deterministic
	)
	
	# Fit machine
	mach = machine(pipe, Xm, ym) |> fit!
	
	# Show pipe
	pipe	
end

# ╔═╡ ff161769-78d5-43a6-b6a1-b13d1bf00403
md"
## Cross Validation & Model Tuning
The number of rounds of training [nrounds] and maximum tree dept [max-dept] was plotted as learning curves. At nrounds = 80 and max-dept = 14 the root mean squared error (rms) was minimized. As a result the machine was refitted with these parameters.

"

# ╔═╡ ffa6c37e-be1b-4a73-9300-81944b12a226
begin
	# Function to plot learning curves
	function plot_lc(curve::NamedTuple, measure::String)

	  # Create a dataframe from data
	  df = DataFrame(parameter_values = curve.parameter_values, measurements = curve.measurements)

	  # Use vlplot to plot data  
	  @vlplot(
		data = df,
		mark = {:line, tooltip = true, point = true},
		x = {"parameter_values:q", title = curve.parameter_name},
		y = {"measurements:q", title = measure},
		title = "Learning Curve",
		height = 250,
		width = 260
	  )  
	end;
end

# ╔═╡ e3ebce33-2536-4390-a1fb-98d5486363ca
begin
	# Generate learning curve
	r1 = range(pipe, :(evo_tree_regressor.nrounds); values = 1:20:120)
	curve1 = learning_curve(mach; range=r1, resampling = Holdout(), measure = rms)
	
	# Plot learning curve
	lc1 = plot_lc(curve1, "rms")
end

# ╔═╡ 9789336b-f1a3-4d07-bfe9-4872e0f50070
begin
	# Change nrounds parameter to 80
	pipe.evo_tree_regressor.nrounds = 80

	# Refit machine
	mach1 = machine(pipe, Xm, ym) |> fit!
	md""
end

# ╔═╡ a08f34a8-c33d-4c50-9bd2-0ad4cbe3dff2
begin
	# Generate learning curve
	r2 = range(pipe, :(evo_tree_regressor.max_depth); values = 1:16)
	curve2 = learning_curve(mach1; range=r2, resampling = Holdout(), measure = rms)
	
	# Plot learning curve
	lc2 = plot_lc(curve2, "rms")
end

# ╔═╡ 1494c880-1238-40f1-9605-39a6ce3e9f2e
begin
	# Change nrounds parameter to 14
	pipe.evo_tree_regressor.max_depth = 14
	
	# Refit machine
	mach2 = machine(pipe, Xm, ym) |> fit!
	md""
end

# ╔═╡ d391daf7-82f1-45b2-8349-e8d695c0e135
begin
	# Model Evaluation on test data
	yp = collect(predict(mach, Xv))
	RMS = round(rms(yp, yv), digits = 3) 
	COR = round(Statistics.cor(yp, yv), digits = 8) 

	# Model Evaluation
	ev = evaluate!(mach, 
	  resampling=Holdout(fraction_train=0.7, shuffle=true, rng=1234),
	  measures=[rms, mae],
	  verbosity = 0
	)
	
	# Display Error
	DataFrame(Metric = [:RootMeanSquredError, :MeanAbsoluteError], Value = ev.measurement)
end

# ╔═╡ 474e0ecd-44fa-4618-8995-8d04fa30235e
md"
## Model Evaluation
Evaluation was done using the metrics rms and mae with 70% shuffled resampling. The error values for rms and mae are described in the table below. By comparison A rms error of $(RMS) and a correlation of $(COR) was also achieved for the test set between the predicted and observed values.
"

# ╔═╡ 7ae6aaaf-1fb6-4b29-a1b0-754ea522614b
md"
## Feature Importance
Feature selection was done using EvoTree's normalized gain by feature.  The most important variables are shown below.  The EvoTree model found MWG/NWG and MDIMC/NDIMC to be important predictor variables. Surprisingly SA/SB are also adequate predictors despite them seeming irrelevant in the earlier data visualization.
"

# ╔═╡ e3dd3030-17e0-4db5-9231-99974f098bbf
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


# ╔═╡ 77255bcf-46d9-4f11-b2ca-7e744f9c88d0
# Plot the feature importance ranking
Importance(mach)

# ╔═╡ bc273be7-322b-4c1a-91bd-761be43dea53
md"
## Conclusion

The runtime of the matrix product (A * B) was found to be most dependent on the variables MWG/NWG and MDIMC/NDIMC but to a lesser extent SA/SB.  A higher MWG/NWG and a lower MDIMC/NDIMC reduced the runtime of matrix multiplication.  The EvoTree model regression model was also optimized when when nrounds and max_dept parameters was set to around 80 and 14 respectively. 

"

# ╔═╡ 2f22063b-7b62-498e-a3a5-c1fc4af8fd0c
md"
## References

* Rafael Ballester-Ripoll, Enrique G. Paredes, Renato Pajarola. Sobol Tensor Trains for Global Sensitivity Analysis. In arXiv Computer Science / Numerical Analysis e-prints, 2017 (https://128.84.21.199/abs/1712.00233).

* Cedric Nugteren and Valeriu Codreanu. CLTune: A Generic Auto-Tuner for OpenCL Kernels. In: MCSoC: 9th International Symposium on Embedded Multicore/Many-core Systems-on-Chip. IEEE, 2015 (http://ieeexplore.ieee.org/document/7328205/)

"

# ╔═╡ Cell order:
# ╠═785014f4-e0c6-4523-b548-90f0aae9ad27
# ╠═72e92e89-c5f3-40fc-9403-fd7938e0ffd7
# ╠═ddfd4874-cad7-11eb-304a-35d3cbefc98e
# ╠═25ebaa52-1aab-4fb9-b41c-d20f51e48554
# ╟─ce12b1da-54bc-4d1e-ae15-29267dae4e08
# ╟─12897db9-989b-43d2-8913-60b15e46ef39
# ╠═174ba3e4-bb41-45dd-b30d-262a070fd49e
# ╠═f556b63b-ae67-4eb5-9f77-c3b980cc12ce
# ╟─e2676718-dfa9-4f54-8fd9-904b28323ece
# ╠═4095c382-087b-43df-9665-f3f72d05b533
# ╠═9ef71868-0832-4ce1-80bc-8ae0f9d9bf52
# ╟─418e21cf-8cb6-4325-927a-fd8686c1fa81
# ╠═e92deacb-8929-4aad-aa4d-c06fc059df2d
# ╠═6596661b-34f5-45a7-8ee3-48764b399b95
# ╟─90cf6ee5-5b53-43a9-b91b-56da1554438c
# ╠═2694133f-1e5f-4764-9b92-7d0f909f1fb1
# ╟─ff161769-78d5-43a6-b6a1-b13d1bf00403
# ╠═ffa6c37e-be1b-4a73-9300-81944b12a226
# ╠═e3ebce33-2536-4390-a1fb-98d5486363ca
# ╠═9789336b-f1a3-4d07-bfe9-4872e0f50070
# ╠═a08f34a8-c33d-4c50-9bd2-0ad4cbe3dff2
# ╠═1494c880-1238-40f1-9605-39a6ce3e9f2e
# ╟─474e0ecd-44fa-4618-8995-8d04fa30235e
# ╠═d391daf7-82f1-45b2-8349-e8d695c0e135
# ╟─7ae6aaaf-1fb6-4b29-a1b0-754ea522614b
# ╠═e3dd3030-17e0-4db5-9231-99974f098bbf
# ╠═77255bcf-46d9-4f11-b2ca-7e744f9c88d0
# ╟─bc273be7-322b-4c1a-91bd-761be43dea53
# ╟─2f22063b-7b62-498e-a3a5-c1fc4af8fd0c
