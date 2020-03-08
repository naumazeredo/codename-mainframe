package mainframe

import "core:fmt"
import "core:math/rand"

PLAYER_DROP_SIZE :: 3;

Player :: struct {
  pos : Vec2i,

  cpu_total : u8,
  cpu_count : u8,

  inventory_total : u8,
  inventory_count : u8,

  vision_radius : u8,
}

create_player :: proc(player: ^Player) {
  player.cpu_total = 3;
  player.cpu_count = 0;

  player.inventory_total = 3;
  player.inventory_count = 0;

  player.vision_radius = 8;
}

update_player_clock_tick :: proc(game_manager: ^GameManager) {
  using game_manager;

  player.cpu_count += 1;

  if player.cpu_count == player.cpu_total {
    player.cpu_count = 0;

    switch input_manager.player_action_cache.action {
      case .None :
        // do nothing
      case .Move :
        move_player(
          input_manager.player_action_cache.move_direction,
          game_manager
        );
      case .UseScript :
        //
      case .Action :
        ok := try_pick_file(game_manager);
        if ok { break; }
        ok = player_try_press_button(game_manager);
        if ok { break; }
        player_try_access_terminal(game_manager);
    }

    input_manager.player_action_cache.action = .None;
  }

  // Store that next tick will be an action tick
  // This must be done one tick before because of the action pretime/overtime
  input_manager.is_player_action_tick = (player.cpu_count == (player.cpu_total - 1));
}

// @Todo(naum): rename to can_player_move
can_move_player :: proc(delta_pos: Vec2i, game_manager: ^GameManager) -> bool {
  using game_manager;

  new_pos := player.pos + delta_pos;
  return is_tile_walkable(new_pos, &terrain);
}

// @Todo(naum): rename to player_move
move_player :: proc(delta_pos: Vec2i, game_manager: ^GameManager) {
  using game_manager;

  assert(can_move_player(delta_pos, game_manager));

  new_pos := player.pos + delta_pos;
  player.pos = new_pos;
}

// @Todo(naum): rename to can_player_pick_file
can_pick_file :: proc(game_manager: ^GameManager) -> bool {
  using game_manager;

  return player.inventory_count != player.inventory_total &&
         terrain.has_file[player.pos.y][player.pos.x];
}

// @Todo(naum): rename to player_pick_file
try_pick_file :: proc(game_manager: ^GameManager) -> bool{
  using game_manager;

  if !can_pick_file(game_manager) { return false; }

  terrain.has_file[player.pos.y][player.pos.x] = false;
  player.inventory_count += 1;

  return true;
}

player_is_over_button :: proc(game_manager: ^GameManager) -> bool{
  using game_manager;
  current_tile := terrain.tile_type[player.pos.y][player.pos.x];
  return current_tile == .Circle || current_tile == .Triangle || current_tile == .Square;
}

player_can_press_button  :: proc(game_manager: ^GameManager) -> bool {
  using game_manager;
  return player_is_over_button(game_manager) && !is_button_pressed(player.pos, game_manager);
}

player_is_around_terminal :: proc(game_manager: ^GameManager) -> bool {
  using game_manager;
  valid_directions := [9][2]int{{-1,-1}, {-1, 0}, {-1, 1}, {0, -1}, {0,0}, {0, 1}, {1, -1}, {1, 0}, {1,1}};

  possible_pos : Vec2i ;
  for i in 0 .. 8 {
    x := player.pos.x + valid_directions[i].x;
    y := player.pos.y + valid_directions[i].y;
    if x < 0 || y < 0 ||
       x >= TERRAIN_W || y >= TERRAIN_H { continue; }

    if terrain.tile_type[y][x] == TileType.Terminal { return true; }
  }

  return false;
}

player_try_press_button :: proc(game_manager: ^GameManager) -> bool{
  using game_manager;

  if !player_can_press_button(game_manager) { return false; }

  current_tile := terrain.tile_type[player.pos.y][player.pos.x];

  id := tile_get_button_id(current_tile);
  assert(id != -1);

  if !terrain.is_button_pressed[id] {
    if terrain.button_sequence[terrain.button_sequence_index] == current_tile {
      terrain.is_button_pressed[id] = true;
      terrain.button_sequence_index += 1;
    } else {
      for i in 0..2 {
        terrain.is_button_pressed[i] = false;
      }
      terrain.button_sequence_index = 0;
    }

    return true;
  }

  return false;
}

player_try_access_terminal :: proc(game_manager: ^GameManager) {
  using game_manager;

  if player_is_around_terminal(game_manager) && terrain.button_sequence_index == 3 {
    complete_floor(game_manager);
  }
}

player_take_damage :: proc(game_manager: ^GameManager) {
  using game_manager;

  if player.inventory_count == 0 {
    game_state = GameState.GameOver;
    return;
  }

  region_pos  : []Vec2i;

  for i := PLAYER_DROP_SIZE ; i < 10 ; i += 1 {
    region_pos, _ = calculate_bfs_region(
      player.pos, i, &terrain,
      // @Todo(naum): change to not count tiles with items also
      tile_ground_and_not_start_condition
    );

    if len(region_pos) - 1 >= int(player.inventory_count) - 1 {
      break;
    }
  }

  rand.shuffle(region_pos);

  // Lose one file and drop the rest

  max_files_dropped := min(int(player.inventory_count)-1, len(region_pos));
  player.inventory_count -= u8(max_files_dropped + 1);

  for i in 0..<max_files_dropped {
    pos := region_pos[i];
    terrain.has_file[pos.y][pos.x] = true;
  }
}

player_can_act :: proc(game_manager : ^GameManager) -> bool {
  return can_pick_file(game_manager) ||
         player_can_press_button(game_manager) ||
         player_is_around_terminal(game_manager);
}

