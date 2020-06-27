#!/usr/bin/env julia

"""
splish-kaboom.jl - Recreation of the "Splish Kaboom!" minigame from The Legend of Zelda: Wind Waker
"""

mutable struct GameBoard
    shots::Array{Bool}
    squids::Array{Bool}
end

GameBoard(g::GameOptions) = Gameboard(zeros(g.num_rows, g.num_cols), zeros(g.num_rows, g.num_cols)

struct Squid
    length:UInt
end

mutable struct GameOptions
    num_rows::UInt = 8
    num_cols::UInt = 8 
    # Maybe later - num_squids::UInt = 3
    max_allowed_shots::UInt = 24
end

function change_options!(game_opts::GameOptions, squids::Vector{Squid})
    change_opts = True
    biggest_squid = maximum(s->s.length, squids)
    default_row_length = max(g.num_rows, biggest_squid)
    default_col_length = max(g.num_cols, biggest_squid)

    while change_opts
        valid_rows = false
        while not valid_rows
            println("How many rows in the grid (minimum $biggest_squid rows): [${default_row_length}]")
            num_rows = readline()
            try
                # empty answers get default value
                if isempty(num_rows)
                    g.num_rows = default_row_length
                    valid_rows = true
                else
                    # Answer must be an int and largest squid must be able to fit in grid
                    rows = parse(Int, num_rows)
                    if rows >= biggest_squid
                        g.num_rows = rows
                        valid_rows = true
                    end
                end
            catch e
                println("Sorry, that answer was not a valid answer... please try again!)
            end
        end

        valid_cols = false
        while not valid_cols
            println("How many columns in the grid (minimum $biggest_squid columns): [${default_col_length}]")
            num_cols = readline()
            try
                # empty answers get default value
                if isempty(num_cols)
                    g.num_cols = default_row_length
                    valid_cols = true
                else
                    # Answer must be an int and largest squid must be able to fit in grid
                    cols = parse(Int, num_cols)
                    if cols >= biggest_squid
                        g.num_cols = cols
                        valid_cols = true
                    end
                end
            catch e
                println("Sorry, that answer was not a valid answer... please try again!)
            end
        end

        min_possible_shots = sum(s->s.length, squids)
        max_possible_shots = g.num_rows * g.num_cols - min_possible_shots
        default_max_shots = min(25, max_possible_shots)
        valid_shots = false
        while not valid_shots
            println("What is the maximum allowed number of shots you want to have? Fewer makes the game harder (minimum $max_possible_shots): [${default_max_shots}]")
            num_shots = readline()
            try
                # empty answers get default value
                if isempty(num_shots)
                    g.max_allowed_shots = default_max_shots
                    valid_cols = true
                else
                    # Answer must be an int and allowed shots most fall within reasonable range
                    shots = parse(Int, num_shots)
                    if min_possible_shots >= shots >= max_possible_shots
                        g.max_allowed_shots = shots
                        valid_shots = true
                    end
                end
            catch e
                println("Sorry, that answer was not a valid answer... please try again!)
            end
        end
    end
end


function main()
    println("Welcome to Splish, Kaboom!  The objective of this game is to destroy all of the dangerous squids lurking in the nearby open sea before they get you.)
    println("First, would like to modify any of the game options?  The defaults are 8 rows, 8 columns, and 25 shots maximum: (y/n) ")
    change_opts = readline()
    game_opts = GameOptions()
    squids = [Squid(3), Squid(4), Squid(5)]
    if change_opts in ["y", "Y", "yes"]
        change_options!(game_opts, squids)
    end
    gameboard = GameBoard(game_opts)

end

main()