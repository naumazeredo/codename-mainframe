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
}

create_player :: proc(player: ^Player) {
  player.cpu_total = 3;
  player.cpu_count = 0;

  player.inventory_total = 3;
  player.inventory_count = 0;
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
      case .PickFile :
        pick_file(game_manager);
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
         is_tile_file(player.pos, &terrain);
}

// @Todo(naum): rename to player_pick_file
pick_file :: proc(game_manager: ^GameManager) {
  using game_manager;

  assert(can_pick_file(game_manager));

  terrain.tile_type[player.pos.y][player.pos.x] = .Ground;
  player.inventory_count += 1;
}

player_take_damage :: proc(game_manager: ^GameManager) {
  using game_manager;

  if player.inventory_count == 0 {
    fmt.println("player, you are dead!!!");
    return;
  }

  region_pos  : []Vec2i;

  for i := PLAYER_DROP_SIZE ; i < 10 ; i += 1 {
    region_pos, _ = calculate_bfs_region(
      player.pos, i, &terrain,
      is_tile_ground_and_not_player
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
    terrain.tile_type[pos.y][pos.x] = .File;
  }
}
