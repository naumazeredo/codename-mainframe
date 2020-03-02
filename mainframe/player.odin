package mainframe

Player :: struct {
  pos : Vec2i,
}

move_player :: proc(delta_pos: Vec2i, game_manager: ^GameManager) -> bool {
  using game_manager;

  new_pos := Vec2i {
    player.pos.x + delta_pos.x,
    player.pos.y + delta_pos.y
  };

  if is_tile_walkable(new_pos, &terrain) {
    player.pos = new_pos;
    return true;
  }

  return false;
}

