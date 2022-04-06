%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import unsigned_div_rem, assert_nn_le
from starkware.cairo.common.alloc import alloc

const RED = 0
const YELLOW = 1

const WIDTH = 7
const HEIGHT = 6

const PLAYER_1 = 0
const PLAYER_2 = 1

const STATUS_OPEN = 0
const STATUS_PLAYING = 1
const STATUS_DRAW = 2
const STATUS_PLAYER_1_WINNER = 3
const STATUS_PLAYER_2_WINNER = 4
const STATUS_PLAYER_1_WINNER_TIMEOUT = 5
const STATUS_PLAYER_2_WINNER_TIMEOUT = 6

func valid_cell{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        row : felt, col : felt):
    assert row * (row - 1) * (row - 2) * (row - 3) * (row - 4) * (row - 5) = 0
    assert col * (col - 1) * (col - 2) * (col - 3) * (col - 4) * (col - 5) * (col - 6) = 0
    return ()
end

func valid_column{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        row : felt, col : felt):
    assert col * (col - 1) * (col - 2) * (col - 3) * (col - 4) * (col - 5) * (col - 6) = 0
    return ()
end

@view
func highest_empty_cell{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_id : felt, row : felt, col : felt) -> (row : felt):
    alloc_locals
    if row == 0:
        return (0)
    end
    let (local current_cell) = board.read(game_id, row - 1, col)
    if current_cell == 0:
        let (local highest_row) = highest_empty_cell(game_id, row - 1, col)
        return (highest_row)
    else:
        return (row)
    end
end

func check_left{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_id : felt, row : felt, col : felt, player : felt) -> (points : felt):
    alloc_locals
    if col == 0:
        return (0)
    end
    let (local current_cell) = board.read(game_id, row, col - 1)
    if current_cell == player + 1:
        let (local left_points) = check_left(game_id, row, col - 1, player)
        return (left_points + 1)
    else:
        return (0)
    end
end

func check_right{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_id : felt, row : felt, col : felt, player : felt) -> (points : felt):
    alloc_locals
    if col == WIDTH - 1:
        return (0)
    end
    let (local current_cell) = board.read(game_id, row, col + 1)
    if current_cell == player + 1:
        let (local right_points) = check_right(game_id, row, col + 1, player)
        return (right_points + 1)
    else:
        return (0)
    end
end

func check_top{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_id : felt, row : felt, col : felt, player : felt) -> (points : felt):
    alloc_locals
    if row == 0:
        return (0)
    end
    let (local current_cell) = board.read(game_id, row - 1, col)
    if current_cell == player + 1:
        let (local top_points) = check_top(game_id, row - 1, col, player)
        return (top_points + 1)
    else:
        return (0)
    end
end

func check_bottom{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_id : felt, row : felt, col : felt, player : felt) -> (points : felt):
    alloc_locals
    if row == HEIGHT - 1:
        return (0)
    end
    let (local current_cell) = board.read(game_id, row + 1, col)
    if current_cell == player + 1:
        let (local bottom_points) = check_bottom(game_id, row + 1, col, player)
        return (bottom_points + 1)
    else:
        return (0)
    end
end


func check_win{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_id : felt, row : felt, col : felt, player : felt) -> (result : felt):
    alloc_locals

    let (column_points) = check_column(game_id, row, col, player)
    if (column_points - 3) * (column_points - 4) * (column_points - 5) * (column_points - 6) * (column_points - 7) == 0:
        player_wins(game_id, player)
        return (column_points)
    end

    let (row_points) = check_row(game_id, row, col, player)
    if (row_points - 3) * (row_points - 4) * (row_points - 5) * (row_points - 6) * (row_points - 7) == 0:
        player_wins(game_id, player)
         return (row_points)
    end

    let (diagonal_topleft_points) = check_diagonal_topleft(game_id, row, col, player)
    if (diagonal_topleft_points - 3) * (diagonal_topleft_points - 4) * (diagonal_topleft_points - 5) * (diagonal_topleft_points - 6) * (diagonal_topleft_points - 7) == 0:
        player_wins(game_id, player)
         return (diagonal_topleft_points)
    end

    let (diagonal_topright_points) = check_diagonal_topright(game_id, row, col, player)
    if (diagonal_topright_points - 3) * (diagonal_topright_points - 4) * (diagonal_topright_points - 5) * (diagonal_topright_points - 6) * (diagonal_topright_points - 7) == 0:
        player_wins(game_id, player)
         return (diagonal_topright_points)
    end    

    return (0)
end

func player_wins{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_id : felt, player : felt):
    if player == PLAYER_1:
        game_status.write(game_id, STATUS_PLAYER_1_WINNER)
    else:
        game_status.write(game_id, STATUS_PLAYER_2_WINNER)
    end

    return ()
end


func check_row{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_id : felt, row : felt, col : felt, player : felt) -> (points : felt):
    alloc_locals
    let (local left_points) = check_left(game_id, row, col, player)
    let (local right_points) = check_right(game_id, row, col, player)
    local total_row = left_points + right_points
    return (total_row)
end

func check_column{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_id : felt, row : felt, col : felt, player : felt) -> (points : felt):
    alloc_locals
    let (local top_points) = check_top(game_id, row, col, player)
    let (local bottom_points) = check_bottom(game_id, row, col, player)
    local total_column = top_points + bottom_points
    return (total_column)
end

func check_topleft{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_id : felt, row : felt, col : felt, player : felt) -> (points : felt):
    alloc_locals
    if col * row == 0:
        return (0)
    end
    let (local current_cell) = board.read(game_id, row - 1, col - 1)
    if current_cell == player + 1:
        let (local topleft_points) = check_topleft(game_id, row - 1, col - 1, player)
        return (topleft_points + 1)
    else:
        return (0)
    end
end

func check_bottomleft{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_id : felt, row : felt, col : felt, player : felt) -> (points : felt):
    alloc_locals
    if row == HEIGHT - 1:
        return (0)
    end
    if col == 0:
        return (0)
    end
    let (local current_cell) = board.read(game_id, row + 1, col - 1)
    if current_cell == player + 1:
        let (local bottomleft) = check_bottomleft(game_id, row + 1, col - 1, player)
        return (bottomleft + 1)
    else:
        return (0)
    end
end

func check_topright{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_id : felt, row : felt, col : felt, player : felt) -> (points : felt):
    alloc_locals
    if row == 0:
        return (0)
    end
    if col == WIDTH - 1:
        return (0)
    end
    let (local current_cell) = board.read(game_id, row - 1, col + 1)
    if current_cell == player + 1:
        let (local topright_points) = check_topright(game_id, row - 1, col + 1, player)
        return (topright_points + 1)
    else:
        return (0)
    end
end

func check_bottomright{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_id : felt, row : felt, col : felt, player : felt) -> (points : felt):
    alloc_locals
    if row == HEIGHT - 1:
        return (0)
    end
    if col == WIDTH - 1:
        return (0)
    end
    let (local current_cell) = board.read(game_id, row + 1, col + 1)
    if current_cell == player + 1:
        let (local bottomright_points) = check_bottomright(game_id, row + 1, col + 1, player)
        return (bottomright_points + 1)
    else:
        return (0)
    end
end

func check_diagonal_topleft{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_id : felt, row : felt, col : felt, player : felt) -> (points : felt):
    alloc_locals
    let (local topleft_points) = check_topleft(game_id, row, col, player)
    let (local bottomright_points) = check_bottomright(game_id, row, col, player)
    local total_topleft = topleft_points + bottomright_points
    return (total_topleft)
end

func check_diagonal_topright{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_id : felt, row : felt, col : felt, player : felt) -> (points : felt):
    alloc_locals
    let (local topright_points) = check_topright(game_id, row, col, player)
    let (local bottomleft_points) = check_bottomleft(game_id, row, col, player)
    local total_topright = topright_points + bottomleft_points
    return (total_topright)
end

func append_games_data{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(user: felt, n: felt, game_ids: felt*):
    if n==0:
        return()
    end
    append_games_data(user, n-1, game_ids)
    let index = n - 1
    let (game_id) = player_games.read(user, index)
    assert game_ids[index] = game_id
    return ()
end

func append_turns_history{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(game_id: felt, n: felt, turns: felt*):
    if n==0:
        return()
    end
    append_turns_history(game_id, n-1, turns)
    let index = n - 1
    let (turn) = game_turn_history.read(game_id, index)
    assert turns[index] = turn[1]
    return ()
end

@view
func check_game_status{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(game_id: felt) -> (status : felt):
    let (status) = game_status.read(game_id)
    return (status)
end

@view
func game_id{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (value : felt):
    let (current_id) = current_game_id.read()
    return (current_id)
end

@view
func get_user_games{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(user: felt) -> (game_ids_len: felt, game_ids: felt*):
    alloc_locals
    let (local count) = player_games_counter.read(user)
    let (local game_ids : felt*) = alloc()

    append_games_data(user, count, game_ids)
    return (count, game_ids)
end

@view
func get_game_history{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(game_id: felt) -> (turns_len: felt, turns: felt*):
    alloc_locals
    let (local count) = game_total_turns.read(game_id)
    let (local turns : felt*) = alloc()

    append_turns_history(game_id, count, turns)
    return (count, turns)
end

@storage_var
func board(game_id : felt, row : felt, col : felt) -> (val : felt):
end

@storage_var
func current_game_id() -> (game_id : felt):
end

@storage_var
func active_player() -> (player : felt):
end

@storage_var
func game_status(game_id : felt) -> (status : felt):
end

@storage_var
func game_players(game_id : felt, player_index : felt) -> (address : felt):
end

@storage_var
func game_total_turns(game_id : felt) -> (total_turns : felt):
end

@storage_var
func game_turn_history(game_id : felt, nth_turn : felt) -> (cell: (felt, felt)):
end

# list of player's games
@storage_var
func player_games(address : felt, nth_index : felt) -> (game_id : felt):
end

# the total number of games a player is in
@storage_var
func player_games_counter(address: felt) -> (total_games : felt):
end

@external
func make_move{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_id: felt, row : felt, col : felt, val : felt) -> ():
    board.write(game_id, row, col, val)
    return ()
end

@external
func new_game{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    let (game_id) = current_game_id.read()
    let (user) = get_caller_address()

    game_players.write(game_id + 1, PLAYER_1, user)
    game_status.write(game_id + 1, STATUS_OPEN)
    current_game_id.write(game_id + 1)

    let (games_counter) = player_games_counter.read(user)
    player_games.write(user, games_counter, game_id + 1)
    player_games_counter.write(user, games_counter + 1)
    return ()
end

@external
func join_game{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(game_id : felt):
    let (user) = get_caller_address()
    let (player_2) = game_players.read(game_id, PLAYER_2)

    assert player_2 = 0
    game_players.write(game_id, PLAYER_2, user)
    game_status.write(game_id, STATUS_PLAYING)
    return ()
end

@external
func player_move{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_id : felt, col : felt):
    alloc_locals
    # check if game status is playing
    let (status) = game_status.read(game_id)
    assert status = STATUS_PLAYING

    # check if it's the player's turn
    let (user) = get_caller_address()
    let (player_1) = game_players.read(game_id, PLAYER_1)
    let (player_2) = game_players.read(game_id, PLAYER_2)
    let (total_turns) = game_total_turns.read(game_id)
    let (local quotient, remainder) = unsigned_div_rem(total_turns, 2)
    local player_index = PLAYER_1
    if remainder == 0:
        assert user = player_1
    else:
        assert user = player_2
        player_index = PLAYER_2
    end

    # check move is valid, at least highest cell is empty
    assert_nn_le(col, WIDTH - 1)
    let (heighest_cell) = board.read(game_id, HEIGHT - 1, col)
    assert heighest_cell = 0

    # get shich row should be filled
    let (local user_row) = highest_empty_cell(game_id, HEIGHT - 1, col)
    
    board.write(game_id, user_row, col, 1 + player_index)
    game_turn_history.write(game_id, total_turns, (user_row, col))
    game_total_turns.write(game_id, total_turns + 1)

    check_win(game_id, user_row, col, player_index)

    return ()
end
