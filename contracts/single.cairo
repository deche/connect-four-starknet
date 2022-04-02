%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import unsigned_div_rem, assert_nn_le

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
        row : felt, col : felt) -> (row : felt):
    alloc_locals
    if row == 0:
        return (0)
    end
    let (local current_cell) = board.read(row - 1, col)
    if current_cell == 0:
        let (local highest_row) = highest_empty_cell(row - 1, col)
        return (highest_row)
    else:
        return (row)
    end
end

@view
func check_left{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        row : felt, col : felt, player : felt) -> (points : felt):
    alloc_locals
    if col == 0:
        return (0)
    end
    let (local current_cell) = board.read(row, col - 1)
    if current_cell == player + 1:
        let (local left_points) = check_left(row, col - 1, player)
        return (left_points + 1)
    else:
        return (0)
    end
end

func check_right{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        row : felt, col : felt, player : felt) -> (points : felt):
    alloc_locals
    if col == WIDTH - 1:
        return (0)
    end
    let (local current_cell) = board.read(row, col + 1)
    if current_cell == player + 1:
        let (local right_points) = check_right(row, col + 1, player)
        return (right_points + 1)
    else:
        return (0)
    end
end

func check_top{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        row : felt, col : felt, player : felt) -> (points : felt):
    alloc_locals
    if row == 0:
        return (0)
    end
    let (local current_cell) = board.read(row - 1, col)
    if current_cell == player + 1:
        let (local top_points) = check_top(row - 1, col, player)
        return (top_points + 1)
    else:
        return (0)
    end
end

func check_bottom{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        row : felt, col : felt, player : felt) -> (points : felt):
    alloc_locals
    if row == HEIGHT - 1:
        return (0)
    end
    let (local current_cell) = board.read(row + 1, col)
    if current_cell == player + 1:
        let (local bottom_points) = check_bottom(row + 1, col, player)
        return (bottom_points + 1)
    else:
        return (0)
    end
end

func check_row{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        row : felt, col : felt, player : felt) -> (points : felt):
    alloc_locals
    let (local left_points) = check_left(row, col, player)
    let (local right_points) = check_right(row, col, player)
    local total_row = left_points + right_points
    return (total_row)
end

func check_column{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        row : felt, col : felt, player : felt) -> (points : felt):
    alloc_locals
    let (local top_points) = check_top(row, col, player)
    let (local bottom_points) = check_bottom(row, col, player)
    local total_column = top_points + bottom_points
    return (total_column)
end

func check_topleft{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        row : felt, col : felt, player : felt) -> (points : felt):
    alloc_locals
    if col * row == 0:
        return (0)
    end
    let (local current_cell) = board.read(row - 1, col - 1)
    if current_cell == player + 1:
        let (local topleft_points) = check_topleft(row - 1, col - 1, player)
        return (topleft_points + 1)
    else:
        return (0)
    end
end

func check_bottomleft{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        row : felt, col : felt, player : felt) -> (points : felt):
    alloc_locals
    if row == HEIGHT - 1:
        return (0)
    end
    if col == 0:
        return (0)
    end
    let (local current_cell) = board.read(row + 1, col - 1)
    if current_cell == player + 1:
        let (local bottomleft) = check_bottomleft(row + 1, col - 1, player)
        return (bottomleft + 1)
    else:
        return (0)
    end
end

func check_topright{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        row : felt, col : felt, player : felt) -> (points : felt):
    alloc_locals
    if row == 0:
        return (0)
    end
    if col == WIDTH - 1:
        return (0)
    end
    let (local current_cell) = board.read(row - 1, col + 1)
    if current_cell == player + 1:
        let (local topright_points) = check_topright(row - 1, col + 1, player)
        return (topright_points + 1)
    else:
        return (0)
    end
end

func check_bottomright{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        row : felt, col : felt, player : felt) -> (points : felt):
    alloc_locals
    if row == HEIGHT - 1:
        return (0)
    end
    if col == WIDTH - 1:
        return (0)
    end
    let (local current_cell) = board.read(row + 1, col + 1)
    if current_cell == player + 1:
        let (local bottomright_points) = check_bottomright(row + 1, col + 1, player)
        return (bottomright_points + 1)
    else:
        return (0)
    end
end

func check_diagonal_topleft{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        row : felt, col : felt, player : felt) -> (points : felt):
    alloc_locals
    let (local topleft_points) = check_topleft(row, col, player)
    let (local bottomright_points) = check_bottomright(row, col, player)
    local total_topleft = topleft_points + bottomright_points
    return (total_topleft)
end

func check_diagonal_topright{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        row : felt, col : felt, player : felt) -> (points : felt):
    alloc_locals
    let (local topright_points) = check_topright(row, col, player)
    let (local bottomleft_points) = check_bottomleft(row, col, player)
    local total_topright = topright_points + bottomleft_points
    return (total_topright)
end

@view
func view_cell{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        row : felt, col : felt) -> (value : felt):
    let (stored_value) = board.read(row, col)
    return (stored_value)
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
func game_turn_history(game_id : felt, nth_turn : felt) -> (column : felt):
end

@external
func make_move{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        row : felt, col : felt, val : felt) -> ():
    board.write(row, col, val)
    return ()
end

@external
func new_game{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    let (game_id) = current_game_id.read()
    let (user) = get_caller_address()

    game_players.write(game_id + 1, PLAYER_1, user)
    game_status.write(game_id + 1, STATUS_OPEN)
    current_game_id.write(game_id + 1)
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

    # check move is valid
    assert_nn_le(col, WIDTH - 1)
    let (heighest_cell) = board.read(HEIGHT - 1, col)
    assert heighest_cell = 0

    let (local user_row) = highest_empty_cell(HEIGHT - 1, col)
    board.write(user_row, col, 1 + player_index)

    return ()
end
