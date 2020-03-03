package mainframe

import "core:fmt"

ENEMY_MAX :: 256;
ENEMY_PATTERN_MAX :: 256;

EnemyType :: enum {
  BackAndForth,
  Circle3x3,
}

EnemyContainer :: struct {
  count : u8,
  type : [ENEMY_MAX]EnemyType,
  pos : [ENEMY_MAX]Vec2i,
  cpu_count : [ENEMY_MAX]u8,
  pattern_count : [ENEMY_MAX]u8,
}

EnemyAction :: enum {
  MoveLeft, MoveRight, MoveUp, MoveDown, Scan
}

EnemyTypeAttribute :: struct {
  cpu_total : u8,
  cpu_total_alert : u8,
  pattern : []EnemyAction,
};

enemy_type_attributes := []EnemyTypeAttribute {
  {
    cpu_total = 6,
    cpu_total_alert = 3,
    pattern = {
      .MoveLeft, .MoveLeft, .Scan,
      .MoveRight, .MoveRight, .Scan,
    },
  },
  {
    cpu_total = 4,
    cpu_total_alert = 2,
    pattern = {
      .MoveLeft, .MoveLeft, .Scan,
      .MoveDown, .MoveDown, .Scan,
      .MoveRight, .MoveRight, .Scan,
      .MoveUp, .MoveUp, .Scan,
    },
  },
};

clear_enemy_container :: proc(enemy_container: ^EnemyContainer) {
  enemy_container.count = 0;
}

create_enemy :: proc(type : EnemyType, pos : Vec2i, enemy_container: ^EnemyContainer) {
  assert(enemy_container.count != ENEMY_MAX-1);

  id := enemy_container.count;
  enemy_container.count += 1;

  enemy_container.type[id] = type;
  enemy_container.pos[id] = pos;
  enemy_container.cpu_count[id] = 0;
}

destroy_enemy :: proc(index: u8, enemy_container: ^EnemyContainer) {
  enemy_container.count -= 1;

  if enemy_container.count == 0 {
    return;
  }

  last_id := enemy_container.count;
  enemy_container.type[index] = enemy_container.type[last_id];
  enemy_container.pos[index] = enemy_container.pos[last_id];
  enemy_container.cpu_count[index] = enemy_container.cpu_count[last_id];
}

update_enemy_clock_tick :: proc(index: u8, game_manager: ^GameManager) {
  using game_manager;

  enemy_container.cpu_count[index] += 1;

  type := int(enemy_container.type[index]);
  if enemy_container.cpu_count[index] == enemy_type_attributes[type].cpu_total {
    enemy_container.cpu_count[index] = 0;

    do_enemy_action(index, game_manager);
  }
}

do_enemy_action :: proc(index: u8, game_manager: ^GameManager) {
  using game_manager;

  pattern_count := enemy_container.pattern_count[index];

  delta_pos : Vec2i;
  type := int(enemy_container.type[index]);
  switch enemy_type_attributes[type].pattern[pattern_count] {
    case .MoveLeft :
      delta_pos = Vec2i{ -1, 0 };
    case .MoveRight :
      delta_pos = Vec2i{ 1, 0 };
    case .MoveUp :
      delta_pos = Vec2i{ 0, -1 };
    case .MoveDown :
      delta_pos = Vec2i{ 0, 1 };
    case .Scan :
      fmt.println("scan!");
  }

  if delta_pos != {0, 0} && can_move_enemy(index, delta_pos, game_manager) {
    move_enemy(index, delta_pos, game_manager);
  }

  enemy_container.pattern_count[index] += 1;
  if int(enemy_container.pattern_count[index]) == len(enemy_type_attributes[type].pattern) {
    enemy_container.pattern_count[index] = 0;
  }
}

can_move_enemy :: proc(index: u8, delta_pos: Vec2i, game_manager: ^GameManager) -> bool {
  using game_manager;

  new_pos := Vec2i {
    enemy_container.pos[index].x + delta_pos.x,
    enemy_container.pos[index].y + delta_pos.y
  };

  return is_tile_walkable(new_pos, &terrain);
}

move_enemy :: proc(index: u8, delta_pos: Vec2i, game_manager: ^GameManager) {
  using game_manager;

  assert(can_move_enemy(index, delta_pos, game_manager));

  new_pos := Vec2i {
    enemy_container.pos[index].x + delta_pos.x,
    enemy_container.pos[index].y + delta_pos.y
  };

  enemy_container.pos[index] = new_pos;
}
