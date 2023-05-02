# install if needed
# import Pkg; Pkg.add("Distributions")

using Random
using Distributions
using JLD2

include("ch_4_Directions.jl")

function outside(points::Matrix{Float64})
    res = Vector{Int}(undef, 0)
    for i in 1:length(points[:,1])
        l =  points[i,1]^2 + points[i,2]^2
        append!(res, l > 10000)
    end
    return res
end

function main()
    k = 4
    setNumbers = 30
    data_sizes = [1000, 5000, 10000, 50000, 100000, 500000, 1000000, 5000000, 10000000, 50000000, 100000000]
    rectangleData_sizes = data_sizes*2

    instanceNames = Vector{String}(undef, length(data_sizes)*setNumbers)
    runningTime_ch_4_Directions = Matrix{Float32}(undef, length(instanceNames), 7)

    resultDirectory = "/home/hoai/Linh/CH-Regular-2k-Directions_BK/result/"

    # set benchmarking = true if want to benchmark
    benchmarking = true
    # only export results if exportResult = true and benchmarking = false
    exportResult = true

    # create data, use the same seed number in mainOctagonal.jl and mainQH.jl
    Random.seed!(42)
    for i in 1:length( data_sizes )
        for j in 1:setNumbers
            data = rand(Uniform(-100, 100), rectangleData_sizes[i], 2)
            B = Vector{Int}(undef, 0)

            A = outside(data) #Find points outside
            B = findall(isodd, A) #label points ouside is an odd number
            x_data = deleteat!(data[:,1], B) #delete points labeled by an odd number
            y_data = deleteat!(data[:,2], B)
            data = hcat(x_data, y_data)


            t = (i-1)*setNumbers+j
            instanceNames[t] = string(data_sizes[i], "_", j)

            println()
            println("Consider instance ", instanceNames[t])
            points = hcat(data[1 : data_sizes[i], 1], data[1 : data_sizes[i], 2])
            if benchmarking
                # https://discourse.julialang.org/t/output-of-benchmark-to-string-or-table/27977/4
                # call atmost 30 times until execution time of 10000 is reached
                # create report ignoring the worst 10 runs


                bm_ch_4_Directions = run(@benchmarkable ch_4_Directions($points) samples=25 seconds=10000)
                runningTime_ch_4_Directions[t,:] = report(bm_ch_4_Directions, 5)

            else

                exportFile_ch_4_Directions = string(resultDirectory, instanceNames[t], "_ch_4_Directions")
                ch_4_Directions(points, exportResult, exportFile_ch_4_Directions)

            end
        end
    end

    if benchmarking

        exportReport(instanceNames, runningTime_ch_4_Directions, string(resultDirectory,"ch_4_Directions_running_time.csv"))

    end
end

main()

# Print the timings in the default way
show(TimeOutput)
