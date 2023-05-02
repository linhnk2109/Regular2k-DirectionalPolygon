# install if needed
# using Pkg; Pkg.add("TimerOutputs");
# using Pkg; Pkg.add("QHull"); Pkg.add("BenchmarkTools");

using TimerOutputs
using QHull
using BenchmarkTools
using Base.Threads

include("utils.jl")


const splitFactor = 4
const TimeOutput = TimerOutput()

k = 16
struct MinMaxType
    min::Float64
    minIndex::Int
    max::Float64
    maxIndex::Int
end

function mySplit(startIndex, endIndex, numberOfSet)
    step = Int(ceil((endIndex-startIndex+1)/numberOfSet))
    grid = collect(startIndex:step:endIndex)
    push!(grid, endIndex+1)
end

function minMaxCollect(result::Vector{MinMaxType})
    mi = result[1].min
    ma = result[1].max
    minIndex = result[1].minIndex
    maxIndex = result[1].maxIndex
    for i in 2:length(result)
        if (mi>result[i].min)
            mi = result[i].min
            minIndex = result[i].minIndex
        end
        if (ma<result[i].max)
            ma = result[i].max
            maxIndex = result[i].maxIndex
        end
    end
    return MinMaxType(mi, minIndex, ma, maxIndex)
end
#.....
#Min, max e_i
function findDirectionalMinMax1(v::Matrix{Float64},
                                a::Vector{Float64},
                                startIndex::Int,
                                endIndex::Int)
    mi = a[1]*v[startIndex, 1] + a[2]*v[startIndex, 2]
    ma = mi
    minIndex = startIndex
    maxIndex = startIndex
    for i in startIndex+1:endIndex
        value = a[1]*v[i, 1] + a[2]*v[i, 2]
        if (mi>value)
            mi = value
            minIndex = i
        elseif (ma<value)
            ma = value
            maxIndex = i
        end
    end
    return MinMaxType(mi, minIndex, ma, maxIndex)
end

function findDirectionalMinMax(v::Matrix{Float64}, a::Vector{Float64})
    n = size(v, 1)
    threadNr = nthreads()
    if (threadNr == 1)
        return findDirectionalMinMax1(v, a, 1, n)
    else
        grid = mySplit(1, n, threadNr*splitFactor)
        result = Vector{MinMaxType}(undef, length(grid)-1)
        @threads for i in 1:length(grid)-1
            result[i] = findDirectionalMinMax1(v, a, grid[i], grid[i+1]-1)
        end
        return minMaxCollect(result)
    end
end

function find2kExtremePoints(points::Matrix{Float64})
    @timeit TimeOutput "find 16 ex" begin
        kDrection = 8
        ex = Vector{Int}(undef, 0)
        for j in 1:kDrection
            d = pi * (j-1)/kDrection
            a = [cos(d), sin(d)]
            ExtremePoints = findDirectionalMinMax(points, a)
            maxX = ExtremePoints.max
            ex_max = ExtremePoints.maxIndex
            ex = append!(ex, ex_max)

            minX = ExtremePoints.min
            ex_min = ExtremePoints.minIndex
            ex = append!(ex, ex_min)
        end
    end
    return [ex[1], ex[3], ex[5], ex[7], ex[9], ex[11], ex[13], ex[15],
            ex[2],ex[4], ex[6], ex[8], ex[10],ex[12], ex[14], ex[16], ex[1]]
end



function outsidePoints(points::Matrix{Float64},
                        u::Int,
                        v::Int,
                        startIndex::Int,
                        endIndex::Int)
    if (u==v)
        return [u]
    end
    a = points[v,2] - points[u,2]
    b = points[u,1] - points[v,1]
    c = a*points[u,1] + b*points[u,2]
    outside_points = Vector{Int}(undef, 0)
    for i in startIndex:endIndex
        if (a*points[i,1]+b*points[i,2]>=c)
            push!(outside_points, i)
        end
    end
    # Include u and v in case of numerical errors that exclude those points
    if (u>=startIndex && u<=endIndex && a*points[u,1]+b*points[u,2]<c)
        push!(outside_points, u)
    end
    if (v>=startIndex && v<=endIndex && a*points[v,1]+b*points[v,2]<c)
        push!(outside_points, u)
    end
    return outside_points
end

function outsidePoints(points::Matrix{Float64}, u::Int, v::Int)
    if (u==v)
        return [u]
    end
    n = size(points, 1)
    threadNr = nthreads()
    if (threadNr == 1)
        return outsidePoints(points, u, v, 1, n)
    else
        grid = mySplit(1, n, threadNr*splitFactor)
        result = Vector{Vector{Int}}(undef, length(grid)-1)
        @threads for i in 1:length(grid)-1
            result[i] = outsidePoints(points, u, v, grid[i], grid[i+1]-1)
        end
        outside_points = Vector{Int}(undef, 0)
        for i in 1:length(grid)-1
            append!(outside_points, result[i])
        end
        return outside_points
    end
end

function filterRemainingPoints1(points::Matrix{Float64},
                                extremalVertices::Vector{Int})
#    println("Get remaining points")
    @timeit TimeOutput "filter remaining points" begin
        remaining_points1 = Vector{Int}(undef, 0)
        for i in 1:k
            u = extremalVertices[i]
            v = extremalVertices[i+1]
            append!(remaining_points1, outsidePoints(points, u, v))
        end
    end
    return remaining_points1
end

function ch_16_Directions(points, exportCH = false, exportFile = "")
    v = find2kExtremePoints(points)
    remaining_points_index1 = filterRemainingPoints1(points, v)

    remaining_points1 = Matrix{Float64}(undef, length(remaining_points_index1), 2)
    @timeit TimeOutput "get remaining points" begin
        for i in 1:length(remaining_points_index1)
            remaining_points1[i,:] = points[remaining_points_index1[i], :]
        end
    end

#    println("Calling QHull")
    @timeit TimeOutput "calling QHull" begin
        convex_hull1 = chull(remaining_points1)
    end

    if (exportCH)
        vertices1 = map(v -> remaining_points_index1[v], convex_hull1.vertices)
        exportResult(points, vertices1, exportFile)
    end
end
