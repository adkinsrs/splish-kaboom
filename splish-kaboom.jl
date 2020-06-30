#!/usr/bin/env julia

"""
splish-kaboom.jl - Recreation of the "Sploosh Kaboom!" minigame from The Legend of Zelda: Wind Waker.  I slightly renamed it because why not.
"""

# I don't want to extend beyond single digits and beyond the alphabet
ROW_LIMIT = 10  # 0-9
COL_LIMIT = 26  # A-Z

### Structs
mutable struct GameBoard
    shots::Array{Bool}  # Keeps track of shots fired
    squids::Array{Bool} # Keeps track of squid positions
end

struct Squid
    len::UInt    # Number of coordinates the squid takes on the board
end

mutable struct GameOptions
    num_rows::UInt
    num_cols::UInt
    # Maybe later - num_squids::UInt = 3
    max_allowed_shots::UInt

    GameOptions() = new(8, 8, 24)
end

### GameBoard functions

GameBoard(g::GameOptions) = GameBoard(falses(g.num_rows, g.num_cols), falses(g.num_rows, g.num_cols))

shots_board(g::GameBoard) = g.shots
squids_board(g::GameBoard) = g.squids
num_rows(g::GameBoard) = size(shots_board(g))[1]
num_cols(g::GameBoard) = size(shots_board(g))[2]

function draw_game_board(g::GameBoard)
    """Draw updated game board."""
    # Top line
    println(" |" * join('A':'A'+num_cols(g)-1, '|'))
    row_spacer = ["-" for i in 1:num_cols(g) *2 + 1]
    # For the main board, print if squid is here (#) or not here (.)
    for row in 1:num_rows(g)
        println(join(row_spacer, ""))
        row_to_print = Char[]
        for col in 1:num_cols(g)
            shot = shots_board(g)[row][col]
            squid = squids_board(g)[row][col]
            if shot && squid
                push!(row_to_print, 'O')
            elseif shot
                push!(row_to_print, 'X')
            else
                push!(row_to_print, ' ')
            end
        end
        println(string(row) * '|' * join(row_to_print, '|'))
    end
end

function draw_shots_board(g::GameBoard)
    """Draw board of only shots fired."""
    # Top line
    println(" |" * join('A':'A'+num_cols(g)-1, '|'))
    row_spacer = ["-" for i in 1:num_cols(g) *2 + 1]
    # For the main board, print if squid is here (#) or not here (.)
    for row in 1:num_rows(g)
        println(join(row_spacer, ""))
        row_to_print = Char[]
        for col in shots_board(g)[row, :]
            push!(row_to_print, col ? 'X' : '.')
        end
        println(string(row) * '|' * join(row_to_print, '|'))
    end
end

function draw_squids_board(g::GameBoard)
    """Draw board of only squid positions."""
    # Top line
    println(" |" * join('A':'A'+num_cols(g)-1, '|'))
    row_spacer = ["-" for i in 1:num_cols(g) *2 + 1]
    # For the main board, print if squid is here (#) or not here (.)
    for row in 1:num_rows(g)
        println(join(row_spacer, ""))
        row_to_print = Char[]
        for col in squids_board(g)[row, :]
            push!(row_to_print, col ? '#' : '.')
        end
        println(string(row) * '|' * join(row_to_print, '|'))
    end
end

### Squid functions

length(s::Squid)::Int = s.len   #Convert to Int to play nice with other variables

### Game Options

num_rows(g::GameOptions) = g.num_rows
num_cols(g::GameOptions) = g.num_cols
max_allowed_shots(g::GameOptions) = g.max_allowed_shots

function num_rows!(g::GameOptions, rows::UInt)
    g.num_rows = rows
    return nothing
end

function num_cols!(g::GameOptions, cols::UInt)
    g.num_cols = cols
    return nothing
end

function max_allowed_shots!(g::GameOptions, max_shots::UInt)
    g.max_allowed_shots = max_shots
    return nothing
end

### Normal functions

function change_cols(g::GameOptions, biggest_squid::Int)
    """Change the number of columns for the game board."""
    default_col_length = max(g.num_cols, biggest_squid)
    while true
        println("How many columns in the grid (minimum $biggest_squid columns): [$default_col_length]")
        num_cols = readline()
        try
            # empty answers get default value
            if isempty(num_cols)
                return default_col_length
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

function change_max_shots(game_opts::GameOptions, squids::Vector{Squid})
    min_possible_shots = sum(s->length(s), squids)
    max_possible_shots = g.num_rows * g.num_cols - min_possible_shots
    default_max_shots = min(25, max_possible_shots)
    while true
        println("What is the maximum allowed number of shots you want to have? Fewer makes the game harder (range is $min_possible_shots - $max_possible_shots): [$default_max_shots]")
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

function change_rows(g::GameOptions, biggest_squid::Int)
    """Change the number of rows for the game board."""
    default_row_length = max(num_rows(g), biggest_squid)
    while true
        println("How many rows in the grid (minimum $biggest_squid rows): [$default_row_length]")
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

function change_options!(game_opts::GameOptions, squids::Vector{Squid})
    """Change options for gameplay."""
    biggest_squid = maximum(s->length(s), squids)

    num_rows!(game_opts, change_rows(game_opts, biggest_squid))
    num_cols!(game_opts, change_cols(game_opts, biggest_squid))
    max_allowed_shots!(game_opts, change_max_shots(game_opts, squids))
    return nothing
end

function place_squid_on_gameboard!(gameboard::GameBoard, squid::Squid)
    """Randomly place a squid on an unoccupied strip of the game board."""
    truearray = trues(length(squid))

    # Keep executing loop until squid is placed
    while true
        # Placed up/down (true) or left/right (false)?
        vertical = rand(Bool)
        if vertical
            # Randomly get starting coordinate.
            last_valid_row = num_rows(gameboard) - (length(squid) - 1)
            rand_row = rand(1:last_valid_row)
            rand_col = rand(1:num_cols(gameboard))
            # Place squid on board if it does not overlap with another squid
            if !any(squids_board(gameboard)[rand_row:rand_row+(length(squid) - 1), rand_col])
                squids_board(gameboard)[rand_row:rand_row+(length(squid) - 1), rand_col] = truearray
                return nothing
            end
        else
            last_valid_col = num_cols(gameboard) - (length(squid) - 1)
            rand_col = rand(1:last_valid_col)
            rand_row = rand(1:num_rows(gameboard))
            if !any(squids_board(gameboard)[rand_row, rand_col:rand_col+(length(squid) - 1)])
                squids_board(gameboard)[rand_row, rand_col:rand_col+(length(squid) - 1)] =  truearray
                return nothing
            end
        end
    end
end

function play_game!(gameboard::GameBoard)
    println("Squids have been placed.  Now it is time to play!")
    game_ends = false
    while !game_ends

    end
end

### Main

function main()
    println("Welcome to Splish, Kaboom!  The objective of this game is to destroy all of the dangerous squids lurking in the nearby open sea before they get you.")
    println("First, would like to modify any of the game options?  The defaults are 8 rows, 8 columns, and 25 shots maximum: (y/n) [default: n] ")
    change_opts = readline()
    game_opts = GameOptions()
    squids = [Squid(3), Squid(4), Squid(5)] #TODO: Customize number of squids and lengths
    if lowercase(change_opts) in ["y", "yes"]
        change_options!(game_opts, squids)
    end
    gameboard = GameBoard(game_opts)
    # Place the longest squid on the board first to prevent potential issues
    sort!(squids, rev=true, by=x->length(x))
    for squid in squids
        place_squid_on_gameboard!(gameboard, squid)
    end
    play_game!(gameboard)
end

main()