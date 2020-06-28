#!/usr/bin/env julia

"""
splish-kaboom.jl - Recreation of the "Sploosh Kaboom!" minigame from The Legend of Zelda: Wind Waker.  I slightly renamed it because why not.
"""

# I don't want to extend beyond single digits and beyond the alphabet
ROW_LIMIT = 10  # 0-9
COL_LIMIT = 26  # A-Z

mutable struct GameBoard
    shots::Array{Bool}
    squids::Array{Bool}
end

GameBoard(g::GameOptions) = Gameboard(zeros(g.num_rows, g.num_cols), zeros(g.num_rows, g.num_cols)

struct Squid
    length:UInt
end

### Game Options

mutable struct GameOptions
    num_rows::UInt = 8
    num_cols::UInt = 8
    # Maybe later - num_squids::UInt = 3
    max_allowed_shots::UInt = 24
end

num_rows(g::GameOptions) = g.num_rows
num_cols(g::GameOptions) = g.num_cols
max_allowed_shots(g::GameOptions) = g.max_allowed_shots

function num_rows!(g::GameOptions, rows::UInt) {
    g.num_rows = rows
    return nothing
}

function num_cols!(g::GameOptions, cols::UInt) {
    g.num_cols = cols
    return nothing
}

function max_allowed_shots!(g::GameOptions, max_shots::UInt) {
    g.max_allowed_shots = max_shots
    return nothing
}

### Normal functions

function change_col(g::GameOptions, biggest_squid::Int)
    """Change the number of columns for the game board."""
    default_col_length = max(g.num_cols, biggest_squid)
    while true
        println("How many columns in the grid (minimum $biggest_squid columns): [${default_col_length}]")
        num_cols = readline()
        try
            # empty answers get default value
            if isempty(num_cols)
                return default_row_length
            else
                # Answer must be an int and largest squid must be able to fit in grid
                cols = parse(Int, num_cols)
                if biggest_squid <= cols <= COL_LIMIT
                    return cols
                end
            end
        catch e
            println("Sorry, that answer was not a valid answer... please try again!")
        end
    end
end

function change_max_shots(game_opts::GameOptions squids::Vector{Squid})
    min_possible_shots = sum(s->s.length, squids)
    max_possible_shots = g.num_rows * g.num_cols - min_possible_shots
    default_max_shots = min(25, max_possible_shots)
    while True
        println("What is the maximum allowed number of shots you want to have? Fewer makes the game harder (range is $min_possible_shots - $max_possible_shots): [${default_max_shots}]")
        num_shots = readline()
        try
            # empty answers get default value
            if isempty(num_shots)
                return default_max_shots
            else
                # Answer must be an int and allowed shots most fall within reasonable range
                shots = parse(Int, num_shots)
                if min_possible_shots <= shots <= max_possible_shots
                    return shots
                end
            end
        catch e
            println("Sorry, that answer was not a valid answer... please try again!")
        end
    end
end

function change_options!(game_opts::GameOptions, squids::Vector{Squid})
    """Change options for gameplay."""
    change_opts = True
    biggest_squid = maximum(s->s.length, squids)

    num_rows!(game_opts, change_rows(game_opts, biggest_squid))
    num_cols!(game_opts, change_cols(game_opts, biggest_squid))
    max_allowed_shots!(game_opts, change_shots(game_opts, squids))
    return nothing
end

function change_row(g::GameOptions, biggest_squid::Int)
    """Change the number of rows for the game board."""
    default_row_length = max(num_rows(g), biggest_squid)
    while true
        println("How many rows in the grid (minimum $biggest_squid rows): [${default_row_length}]")
        num_rows = readline()
        try
            # empty answers get default value
            if isempty(num_rows)
                return default_row_length
            else
                # Answer must be an int and largest squid must be able to fit in grid
                rows = parse(Int, num_rows)
                if biggest_squid <= rows <= ROW_LIMIT
                    return rows
                end
            end
        catch e
            println("Sorry, that answer was not a valid answer... please try again!")
        end
    end
end

### Main

function main()
    println("Welcome to Splish, Kaboom!  The objective of this game is to destroy all of the dangerous squids lurking in the nearby open sea before they get you.")
    println("First, would like to modify any of the game options?  The defaults are 8 rows, 8 columns, and 25 shots maximum: (y/n) ")
    change_opts = readline()
    game_opts = GameOptions()
    squids = [Squid(3), Squid(4), Squid(5)]
    if change_opts in ["y", "Y", "yes"]
        change_options!(game_opts, squids)
    end
    gameboard = GameBoard(game_opts)
    for squid in squids
        place_squid_on_gameboard(gameboard, squid)
    end

end

main()