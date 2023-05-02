# Regular 2k-Directional Polygon Algorithm
The code implements Regular $2k$-Directional Polygon Algorithm to find the convex hull of a finite set of points.

### Install libraries
- Open a terminal and go to the directory containing the code
>        julia install.jl

### Run the programs
- Open a terminal and go to the directory containing the code 
- Run Regular 2k-Directional Polygon Algorithm (k  = 2, 4, 8, 16) in sequential mode
>        julia main_ch_4_Directions.jl
>        julia main_ch_8_Directions.jl
>        julia main_ch_16_Directions.jl
>        julia main_ch_32_Directions.jl
- Run Regular 2k-Directional Polygon Algorithm (k  = 2, 4, 8, 16) in parallel mode
>        julia -t numberOfThreads main_ch_4_Directions.jl
>        julia -t numberOfThreads main_ch_8_Directions.jl
>        julia -t numberOfThreads main_ch_16_Directions.jl
>        julia -t numberOfThreads main_ch_32_Directions.jl

### Note
Creat a file "result" in this directory

### Setting
- Benchmarking mode
> Set benchmarking = true in the main functions
- Export the convex hull to file
> Set benchmarking = false and exportResult = true in the main functions
