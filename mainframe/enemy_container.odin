package mainframe

import "core:fmt"

ENEMY_MAX :: 256;
ENEMY_PATTERN_MAX :: 256;

EnemyType :: enum {
  BackAndForth,
  Circle3x3,
}

EnemyState :: enum {
  Patrol,
  Alert,
  AlertScan,
  BackToPatrol,
}

// @Idea(naum): try #soa
EnemyContainer :: struct {
  count : u8,

  type            : [ENEMY_MAX]EnemyType,
  state           : [ENEMY_MAX]EnemyState,
  pos             : [ENEMY_MAX]Vec2i,
  cpu_total       : [ENEMY_MAX]u8,
  cpu_count       : [ENEMY_MAX]u8,
  pattern_count   : [ENEMY_MAX]u8,
  last_patrol_pos : [ENEMY_MAX]Vec2i,
  alert_pos       : [ENEMY_MAX]Vec2i, // @XXX(naum): not used, use for propagating alert(?)
  alert_path      : [ENEMY_MAX]Queue(Vec2i),
}

EnemyAction :: enum {
  MoveLeft, MoveRight, MoveUp, MoveDown, Scan
}

EnemyTypeAttribute :: struct {
  cpu_total       : u8,
  cpu_total_alert : u8,
  pattern         : []EnemyAction,
  scan_size       : u8,
};

// @XXX(naum): Come on, Odin, why can't we iterate on a constant array?
enemy_type_attributes := []EnemyTypeAttribute {
  {
    cpu_total = 6,
    cpu_total_alert = 4,
    pattern = {
      .MoveLeft, .MoveLeft, .Scan,
      .MoveRight, .MoveRight, .Scan,
    },
    scan_size = 1,
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
    scan_size = 2,
  },
};

clear_enemy_container :: proc(enemy_container: ^EnemyContainer) {
  enemy_container.count = 0;
}

create_enemy :: proc(type : EnemyType, pos : Vec2i, enemy_container: ^EnemyContainer) {
  assert(enemy_container.count != ENEMY_MAX-1);

  index := enemy_container.count;
  enemy_container.count += 1;

  enemy_container.type[index] = type;
  enemy_container.pos[index] = pos;
  enemy_container.cpu_total[index] = enemy_type_attributes[int(enemy_container.type[index])].cpu_total;
  enemy_container.cpu_count[index] = 0;
}

destroy_enemy :: proc(index: u8, enemy_container: ^EnemyContainer) {
  enemy_container.count -= 1;

  if enemy_container.count == 0 {
    return;
  }

  last_index := enemy_container.count;
  enemy_container.type[index] = enemy_container.type[last_index];
  enemy_container.pos[index] = enemy_container.pos[last_index];
  enemy_container.cpu_total[index] = enemy_container.cpu_total[last_index];
  enemy_container.cpu_count[index] = enemy_container.cpu_count[last_index];
}

update_enemy_clock_tick :: proc(index: u8, game_manager: ^GameManager) {
  using game_manager;

  enemy_container.cpu_count[index] += 1;

  if enemy_container.cpu_count[index] == enemy_container.cpu_total[index] {
    enemy_container.cpu_count[index] = 0;

    do_enemy_action(index, game_manager);
  }
}

// @Optimize(naum): can change to be data oriented: add enemy to a move list or scan list, then process the lists
do_enemy_action :: proc(index: u8, game_manager: ^GameManager) {
  using game_manager;

  type := int(enemy_container.type[index]);
  switch enemy_container.state[index] {
    case .Patrol :
      pattern_count := enemy_container.pattern_count[index];

      delta_pos : Vec2i;
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
          do_enemy_scan(index, game_manager);
      }

      if delta_pos != {0, 0} && can_move_enemy(index, delta_pos, game_manager) {
        move_enemy(index, delta_pos, game_manager);
      }

      enemy_container.pattern_count[index] += 1;
      if int(enemy_container.pattern_count[index]) == len(enemy_type_attributes[type].pattern) {
        enemy_container.pattern_count[index] = 0;
      }

    case .Alert :
      next_pos := queue_pop(&enemy_container.alert_path[index]);
      move_enemy(
        index,
        next_pos - enemy_container.pos[index],
        game_manager
      );

      if queue_len(&enemy_container.alert_path[index]) == 0 {
        enemy_container.state[index] = .AlertScan;
      }

    case .AlertScan :
      player_found := do_enemy_scan(index, game_manager);

      if !player_found {
        enemy_container.state[index] = .BackToPatrol;
        enemy_container.cpu_total[index] = enemy_type_attributes[type].cpu_total;

        enemy_container.alert_path[index] = calculate_bfs(enemy_container.pos[index],
                                                          enemy_container.last_patrol_pos[index],
                                                          &terrain);
      }

    case .BackToPatrol :
      next_pos := queue_pop(&enemy_container.alert_path[index]);
      move_enemy(
        index,
        next_pos - enemy_container.pos[index],
        game_manager
      );

      if queue_len(&enemy_container.alert_path[index]) == 0 {
        enemy_container.state[index] = .Patrol;
      }
  }
}

can_move_enemy :: proc(index: u8, delta_pos: Vec2i, game_manager: ^GameManager) -> bool {
  using game_manager;

  new_pos := enemy_container.pos[index] + delta_pos;
  return is_tile_walkable(new_pos, &terrain);
}

move_enemy :: proc(index: u8, delta_pos: Vec2i, game_manager: ^GameManager) {
  using game_manager;

  assert(can_move_enemy(index, delta_pos, game_manager));

  new_pos := enemy_container.pos[index] + delta_pos;
  enemy_container.pos[index] = new_pos;
}

do_enemy_scan :: proc(index: u8, game_manager: ^GameManager) -> bool {
  using game_manager;

  player_found := false;
  type := int(enemy_container.type[index]);
  scan_size := int(enemy_type_attributes[type].scan_size);

  for i in -scan_size..scan_size {
    for j in -scan_size..scan_size {
      if i == 0 && j == 0 { continue; }
      pos := enemy_container.pos[index] + Vec2i { int(j), int(i) };
      terrain.is_tile_being_scanned[pos.y][pos.x] = true;

      if player.pos == pos {
        player_found = true;

        // @Optimize(naum): use data oriented design (add to enemies_with_successful_scan[state])
        switch enemy_container.state[index] {
          case .Patrol :
            enemy_container.last_patrol_pos[index] = enemy_container.pos[index];
            enemy_container.cpu_total[index] = enemy_type_attributes[type].cpu_total_alert;
          fallthrough;

          case .AlertScan:
            enemy_container.state[index] = .Alert;
          fallthrough;

          case .Alert :
            enemy_container.alert_pos[index]  = player.pos;
            enemy_container.alert_path[index] = calculate_bfs(enemy_container.pos[index],
                                                              player.pos,
                                                              &terrain);

          case .BackToPatrol :
            fmt.println("scanning while going back to patrol should not happen!");
            assert(false);
        }
      }
    }
  }

  return player_found;
}
