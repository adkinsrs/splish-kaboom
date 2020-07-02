#!/usr/bin/env julia

"""
splish-kaboom.jl - Recreation of the "Sploosh Kerboom!" minigame from The Legend of Zelda: Wind Waker.  I slightly renamed it because why not.

Zelda sound effects from http://noproblo.dayjo.org/ZeldaSounds/

"""

#using FileIO: loadstreaming
#import LibSndFile
using UnicodePlots

# I don't want to extend beyond single digits and beyond the alphabet
const ROW_LIMIT = 10  # 0-9
const COL_LIMIT = 26  # A-Z
const STARTING_PROB_BOARDS = 12

# Store sound effects to play on cue
# I am not sure if this is working... my Mac OS version is too old to operate the libsndfile API
#sploosh = loadstreaming(joinpath(dirname(PROGRAM_FILE), "WW_Salvatore_Sploosh.wav"))
#kerboom = loadstreaming(joinpath(dirname(PROGRAM_FILE), "WW_Salvatore_Kerboom.wav"))

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
    probability_mode::Bool

    GameOptions() = new(8, 8, 24, false)
end

### GameBoard functions

GameBoard(g::GameOptions) = GameBoard(falses(g.num_rows, g.num_cols), falses(g.num_rows, g.num_cols))

shots_board(g::GameBoard) = g.shots
squids_board(g::GameBoard) = g.squids
num_rows(g::GameBoard) = size(shots_board(g))[1]
num_cols(g::GameBoard) = size(shots_board(g))[2]

function draw_game_board(g::GameBoard)
    """Draw updated game board."""
    println()
    # Top line
    println(" |" * join('A':'A'+num_cols(g)-1, '|'))
    row_spacer = ["-" for i in 1:num_cols(g) *2 + 1]
    # For the main board, print if squid is here (#) or not here (.)
    for row in 1:num_rows(g)
        println(join(row_spacer, ""))
        row_to_print = Char[]
        for col in 1:num_cols(g)
            shot = shots_board(g)[row, col]
            squid = squids_board(g)[row, col]
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
    println()
end

function draw_shots_board(g::GameBoard)
    """Draw board of only shots fired."""
    println()
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
    println()
end

function draw_squids_board(g::GameBoard)
    """Draw board of only squid positions."""
    # TODO: Draw each squid as a different color to easily differentiate
    println()
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
    println()
end

### Squid functions

Base.length(s::Squid)::Int = s.len   #Convert to Int to play nice with other variables
                                     #Also explicitly define as Base.length so Base.length is not overwritten for all other functions

### Game Options

num_rows(g::GameOptions) = g.num_rows
num_cols(g::GameOptions) = g.num_cols
max_allowed_shots(g::GameOptions) = g.max_allowed_shots
prob_mode(g::GameOptions) = g.probability_mode

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

function prob_mode!(g::GameOptions, on::Bool)
    g.probability_mode = on
    return nothing
end

### Normal functions

function all_squids_sunk(g::GameBoard)
    """Determine if all the squids on the board have been sunk."""
    all_sunk = true

    # Julia stores arrays in column-major format, so looping through columns first is faster
    for col in 1:num_cols(g), row in 1:num_rows(g)
        # If squid part has not been hit, all squids have not been sunk.
        if squids_board(g)[row, col] && !shots_board(g)[row, col]
            all_sunk = false
            break
        end
    end
    return all_sunk
end

function change_cols(g::GameOptions, biggest_squid::Int)::UInt
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

function change_max_shots(g::GameOptions, squids::Vector{Squid})::UInt
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

function change_prob_mode(g::GameOptions)
    """Change if probability heatmap should be shown."""
    println("Would you like to know probabilities of hitting a squid in an area?  This can make the game easier: [no]")
    prob_mode = readline()
    if lowercase(prob_mode) in ["y", "yes"]
        return true
    end
    return false
end

function change_rows(g::GameOptions, biggest_squid::Int)::UInt
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
    prob_mode!(game_opts, change_prob_mode(game_opts))
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

function parse_coordinate(coordinate::String)
    """Parse the input shot coordinate.  Number is row, and letter is column."""

    row_id = -1
    col_id = -1

    # If valid return coordinates, if not return erroneous coords
    if length(coordinate) != 2
        println("Not a valid coordinate!  Please try again!")
        return (row_id, col_id)
    end

    one = first(coordinate); two = last(coordinate)

    # Determine which coordinate is the letter
    # Want to give flexibility if coordinate is input as "B2" or "2B"

    # Char '0' starts at int 48
    # Char 'A' starts at int 65
    all_valid_chars = collect('A':'Z')
    append!(all_valid_chars, collect('1':'9'))

    if Int('a') <= Int(one) <= Int('z') || Int('a') <= Int(two) <= Int('z')
        println("Letter coordinate needs to be uppercase.  I'm too lazy to program case-insensitivity.")
        return (row_id, col_id)
    elseif !(one in all_valid_chars && two in all_valid_chars)
        println("Odd character in coordinate.  Please input a letter and a number.")
        return (row_id, col_id)
    elseif Int('A') <= Int(one) <= Int('Z') && Int('A') <= Int(two) <= Int('Z')
        println("Coordinate appears to be two letters.  Please input a letter and a number.")
        return (row_id, col_id)
    elseif Int('1') <= Int(one) <= Int('9') && Int('1')  <= Int(two) <= Int('9')
        println("Coordinate appears to be two numbers.  Please input a letter and a number.")
        return (row_id, col_id)
    else
        # At this point only one value should be a letter and the other should be a number
        if Int('A') <= Int(one)
            row_id = Int(two) - 48
            col_id = Int(one) - 64  # ASCII letters start at 65
        else
            row_id = Int(one) - 48
            col_id = Int(two) - 64
        end
    end
    return (row_id, col_id)
end

function play_game!(gameboard::GameBoard, opts::GameOptions, possible_boards)
    """Play the game until an ending condition is reached."""
    println("Squids have been placed.  Now it is time to play!")
    shots_fired = 0
    game_ends = false
    while !game_ends
        draw_game_board(gameboard)
        if prob_mode(opts)
            prob_board = update_probability(possible_boards)
            println(heatmap(prob_board
                , xlim=[1,num_cols(gameboard)]
                , ylim=[1, num_rows(gameboard)]
                , width=num_cols(gameboard)*2 - 1
                , height=num_rows(gameboard)*2 - 1
                , colormap=:inferno
                , title="Chance to hit squid (lighter is better)"
                , labels=false  #Cannot invert the axes so just hide them to avoid confusion
                ))
        end
        println("Pick a coordinate to fire on.  Example is 'A1' or 'B2'. Type 'exit' to exit game")
        println("##### SHOTS REMAINING - $(max_allowed_shots(opts) - shots_fired) #####")
        print("Fire at - ")
        coordinate = readline()
        println("----------------------------------------------")
        if lowercase(coordinate) == "exit"
            println("Abandoning mission!  You have doomed us all!")
            clean_exit()
        end
        (row_id, col_id) = parse_coordinate(coordinate)
        # Are we still on the game board?
        if row_id > num_rows(gameboard) || col_id > num_cols(gameboard)
            println("Sorry, coordinate '$coordinate' is out of range of this grid.  Select another space!")
            continue
        end
        row_id <= 0 && continue
        # Was shot fired here already?
        if shots_board(gameboard)[row_id, col_id]
            println("Already fired at this location ($coordinate).  Save your ammo for another space!")
            continue
        end
        # Update board with hit or miss
        hit=false
        if squids_board(gameboard)[row_id, col_id]
            #read(kerboom)
            println("KER-BOOM!  You are one step closer to annihilating all squids!")
            hit=true
        else
            #read(sploosh)
            println("SPLOOSH!  Good job, good effort!")
        end
        shots_fired +=1
        shots_board(gameboard)[row_id, col_id] = true
        # Determine if all squids have been sunk
        if all_squids_sunk(gameboard)
            game_ends = true
            draw_game_board(gameboard)
            println("#####")
            println("# FINAL BOARD")
            println("# Hooray, you have sunk all the squids, and are a hero to the people.  Nice shooting there, Tex!")
            println("# Total shots you used: $shots_fired")
            println("######")
        # Determine if all shots have been fired
        elseif shots_fired == opts.max_allowed_shots
            game_ends = true
            println("You have used up all of your allowed shots, but did not destroy all the squids.  You lose!  Squid placement is show below.")
            draw_squids_board(gameboard)
        end
        if prob_mode(opts)
            possible_boards = update_valid_boards(possible_boards, shots_board(gameboard), hit, row_id, col_id)
        end
    end
    return nothing
end

function update_probability(possible_boards)
    """Calculate new probabilities based on remaining valid squid combinations."""
    main_board = first(possible_boards)
    prob_board = zeros(num_rows(main_board), num_cols(main_board))

    # First get frequency of squids in each grid space then convert to a percent chance
    main_squid_board = squids_board(main_board)
    for col in 1:num_cols(main_board), row in 1:num_rows(main_board)
        prob_board[row,col] = sum(x->squids_board(x)[row,col], possible_boards) * 100 / length(possible_boards)
    end
    # Since the heatmap has the origin in the lower-left, we need to flip the y-axis
    return reverse(prob_board, dims=1)
end

function update_valid_boards(possible_boards, shots_board, hit::Bool, row::Int, col::Int)
    """Determine which squid combinations are still valid given the current shot board and outcome."""
    new_possible_boards = [popfirst!(possible_boards)]  # Main board is always first element of old board set
    main_board = first(new_possible_boards)
    if hit
        # On a hit, all valid boards must have a squid at that position
        for board in possible_boards
            squids_board(board)[row, col] && push!(new_possible_boards, board)
        end
    else
        # On a miss, all valid boards must not have a squid at that position
        for board in possible_boards
            squids_board(board)[row, col] || push!(new_possible_boards, board)
        end
    end

    return new_possible_boards  #TO BE EDITED
end

### Main

function main()
    running = true
    while running
        println("Welcome to Splish, Kaboom!  The objective of this game is to destroy all of the dangerous squids lurking in the nearby open sea before they get you.")
        println("First, would like to modify any of the game options?  The defaults are no probability heatmap, 8 rows, 8 columns, and 25 shots maximum: (y/n) [default: n] ")
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

        possible_gameboards = [gameboard]
        if prob_mode(game_opts)
            for idx in 1:STARTING_PROB_BOARDS - 1    # actual gameboard is one board
                fake_gameboard = GameBoard(game_opts)
                for squid in squids
                    place_squid_on_gameboard!(fake_gameboard, squid)
                end
                push!(possible_gameboards, fake_gameboard)
            end
        end
        play_game!(gameboard, game_opts, possible_gameboards)

        println()
        println("Would you like to play again? (y/n) [default: n]")
        play_again = readline()
        if lowercase(play_again) in ["n", "no", ""]
            running = false
        end
    end
    println("Until next time!")
    clean_exit()
end

function clean_exit()
    """Before exiting, close opened streams."""
    #close(sploosh)
    #close(kerboom)
    exit()
end

main()