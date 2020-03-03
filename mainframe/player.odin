package mainframe

import "core:fmt"

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

    input_manager.player_action_cache.action = PlayerActions.None;
  }

  // Store that next tick will be an action tick
  // This must be done one tick before because of the action pretime/overtime
  input_manager.is_player_action_tick = (player.cpu_count == (player.cpu_total - 1));
}

can_move_player :: proc(delta_pos: Vec2i, game_manager: ^GameManager) -> bool {
  using game_manager;

  new_pos := Vec2i {
    player.pos.x + delta_pos.x,
    player.pos.y + delta_pos.y
  };

  return is_tile_walkable(new_pos, &terrain);
}

move_player :: proc(delta_pos: Vec2i, game_manager: ^GameManager) {
  using game_manager;

  assert(can_move_player(delta_pos, game_manager));

  new_pos := Vec2i {
    player.pos.x + delta_pos.x,
    player.pos.y + delta_pos.y
  };

  player.pos = new_pos;
}

can_pick_file :: proc(game_manager: ^GameManager) -> bool {
  using game_manager;

  return player.inventory_count != player.inventory_total &&
         is_tile_file(player.pos, &terrain);
}

pick_file :: proc(game_manager: ^GameManager) {
  using game_manager;

  assert(can_pick_file(game_manager));

  terrain.tiles[player.pos.y][player.pos.x].type = TileType.Ground;
  player.inventory_count += 1;
}
