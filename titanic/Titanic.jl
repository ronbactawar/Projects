using Statistics
using DataFrames
using Queryverse
using VegaLite
using MLJ
using ShapML
using CSV

#readtable("data.csv")
#For Graphs
titanic = CSV.read("/home/chigball/Data/train.csv") |>
@select(-:PassengerId, -:Name, -:Ticket, -:Cabin) |>
@mutate(Survived = string(_.Survived)) |>
DataFrame;

println(titanic)