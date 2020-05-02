using Random
check(bound::Vector) = cell -> all([1, 1] .≤ cell .≤ bound)
neighbors(cell::Vector, bound::Vector, step::Int=2) =
    filter(check(bound), map(dir -> cell + step * dir, [[0, 1], [-1, 0], [0, -1], [1, 0]]))
 
function walk(maze::Matrix, nxtcell::Vector, visited::Vector=[])
    push!(visited, nxtcell)
    for neigh in shuffle(neighbors(nxtcell, collect(size(maze))))
        if neigh ∉ visited
            maze[round.(Int, (nxtcell + neigh) / 2)...] = 0
            walk(maze, neigh, visited)
        end
    end
    maze
end

function maze(w::Int, h::Int)
    maze = collect(i % 2 | j % 2 for i in 1:2w+1, j in 1:2h+1)
    firstcell = 2 * [rand(1:w), rand(1:h)]
    maze = walk(maze, firstcell)
    #zero out entry and exit
    maze[2w,2h+1] = 0
    maze[2,1]     = 0
    return maze
end

pprint(matrix) = for i = 1:size(matrix, 1) println(join(matrix[i, :])) end
function printmaze(maze)
    walls = split("╹ ╸ ┛ ╺ ┗ ━ ┻ ╻ ┃ ┓ ┫ ┏ ┣ ┳ ╋")
    h, w = size(maze)
    f = cell -> 2 ^ ((3cell[1] + cell[2] + 3) / 2)
    wall(i, j) = if maze[i,j] == 0 " " else
        walls[Int(sum(f, filter(x -> maze[x...] != 0, neighbors([i, j], [h, w], 1)) .- [[i, j]]))]
    end
    mazewalls = collect(wall(i, j) for i in 1:2:h, j in 1:w)
    pprint(mazewalls)
end
 
printmaze(maze(10, 10))
