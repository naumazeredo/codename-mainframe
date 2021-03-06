package mainframe

import "core:fmt"
import "core:math/rand"

import sdl "shared:odin-sdl2"

TERRAIN_H :: 256;
TERRAIN_W :: 256;

TileType :: enum {
  None,
  Entrance,
  Ground,
  Square,
  Triangle,
  Circle,
  Terminal,
  SquareSymbol,
  TriangleSymbol,
  CircleSymbol,
}

// @Idea(naum): Maybe test #soa
Terrain :: struct {
  tile_type             : [TERRAIN_H][TERRAIN_W]TileType,
  is_tile_being_scanned : [TERRAIN_H][TERRAIN_W]bool,
  is_tile_visible       : [TERRAIN_H][TERRAIN_W]bool,
  is_tile_hidden        : [TERRAIN_H][TERRAIN_W]bool,
  has_file              : [TERRAIN_H][TERRAIN_W]bool,

  is_button_pressed : [3]bool,

  enter : Vec2i, // @CleanUp(naum): remove?

  button_sequence : [3]TileType,
  button_sequence_index : int,

  topology: Topology,
}

reset_terrain :: proc(game_manager: ^GameManager) {
  using game_manager;

  for i in 0..<TERRAIN_H {
    for j in 0..<TERRAIN_W {
      terrain.tile_type[i][j] = .None;
      terrain.is_tile_being_scanned[i][j] = false;
      terrain.is_tile_visible[i][j] = false;
      terrain.is_tile_hidden[i][j] = true;
      terrain.has_file[i][j] = false;
    }
  }
  for i in 0 .. 2 {
    terrain.is_button_pressed[i] = false;
  }

  terrain.button_sequence_index = 0;

  clear_enemy_container(&enemy_container);

  terrain.topology = Topology{};
}

create_test_terrain :: proc(game_manager: ^GameManager) {
  using game_manager;

  reset_terrain(game_manager);

  // 0 -> nothing
  // 1 -> player start
  // 2 -> ground
  // 3 -> file
  // 4 -> patrol AMS (left)
  // 5 -> circle AMS (down)
  /*
  custom_terrain := [][]u8 {
    { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 2, 2, 2, 5, 2, 0, 0, 2, 2, 2, 0, 0 },
    { 0, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4, 0, 0 },
    { 0, 0, 2, 2, 2, 2, 2, 0, 0, 2, 2, 2, 0, 0 },
    { 0, 0, 2, 2, 2, 2, 2, 0, 0, 0, 2, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 2, 0, 0, 2, 2, 2, 2, 0, 0 },
    { 0, 0, 0, 0, 0, 2, 2, 2, 2, 3, 2, 2, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 3, 2, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0, 2, 3, 1, 2, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
  };
  */

  /*
  custom_terrain := [][]u8 {
    { 1 }
  };
  */

  custom_terrain := [][]u8 {
    { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 2, 2, 2, 2, 5, 0 },
    { 0, 0, 0, 0, 0, 2, 6, 7, 8, 2, 0 },
    { 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 0 },
    { 0, 0, 0, 0, 0, 2, 3, 1, 3, 2, 0 },
    { 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
  };

  for row, i in custom_terrain {
    for elem, j in row {
      terrain.tile_type[i][j] = .Ground;

      switch elem {
        case 0: // nothing
          terrain.tile_type[i][j] = .None;
        case 1: // entrance
          terrain.tile_type[i][j] = .Entrance;
          player.pos = Vec2i { j, i };
        case 3: // file
          terrain.has_file[i][j] = true;
        case 4: // enemy back and forth
          create_enemy(.BackAndForth, { j, i }, &enemy_container);
        case 5: // enemy circle 3x3
          create_enemy(.Circle3x3, { j, i }, &enemy_container);
        case 6: // square
          terrain.tile_type[i][j] = .Square;
        case 7: // circle
          terrain.tile_type[i][j] = .Circle;
        case 8: // circle
          terrain.tile_type[i][j] = .Triangle;
      }
    }
  }

  terrain_update_player_vision(game_manager);

  clock_debugger.pivot = Vec2i{ 0, 0 }; // @Todo(naum): move this.. it's a terrain variable

  // mock terrain generation TODO(luciano): remove
}

generate_shuffled_buttons :: proc() -> []TileType {
  buttons_to_shuffle := []TileType{TileType.Square, TileType.Triangle, TileType.Circle};
  rand.shuffle(buttons_to_shuffle);
  return buttons_to_shuffle;
}

create_terrain :: proc(game_manager: ^GameManager) {
  fmt.println("creating terrain!");
  using game_manager;

  reset_terrain(game_manager);

  shuffled_buttons := generate_shuffled_buttons();

  terrain.button_sequence[0] = shuffled_buttons[0];
  terrain.button_sequence[1] = shuffled_buttons[1];
  terrain.button_sequence[2] = shuffled_buttons[2];

  fmt.println("button_sequence", terrain.button_sequence);

  terrain.button_sequence_index = 0;
  clear_enemy_container(&enemy_container);

  fmt.println("generating rooms");
  generate_rooms(&terrain, &enemy_container);
  fmt.println("generating rooms OK");

  player.pos = terrain.enter;

  clock_debugger.pivot = Vec2i{ 0, 0 }; // @Todo(naum): move this.. it's a terrain variable
  fmt.println("creating terrain OK!");

  terrain_update_player_vision(game_manager);
}

create_boss_test_terrain:: proc(game_manager: ^GameManager) {
  using game_manager;

  for i in 0..<TERRAIN_H {
    for j in 0..<TERRAIN_W {
      terrain.tile_type[i][j] = .None;
    }
  }
  clear_enemy_container(&enemy_container);

  create_boss_room(&terrain, &enemy_container);

  player.pos = terrain.enter;

  clock_debugger.pivot = Vec2i{ 0, 0 }; // @Todo(naum): move this.. it's a terrain variable
}

update_terrain_clock_tick :: proc(game_manager: ^GameManager) {
  using game_manager;

  for i in 0..<TERRAIN_H {
    for j in 0..<TERRAIN_W {
      terrain.is_tile_being_scanned[i][j] = false;
      terrain.is_tile_visible[i][j] = false;
    }
  }
}

terrain_update_player_vision :: proc(game_manager: ^GameManager) {
  using game_manager;

  player_vision, _ := calculate_bfs_region(player.pos,
                                           int(player.vision_radius),
                                           &terrain,
                                           always_true_condition,
                                           //in_euclid_dist_condition
                                           custom_euclid_dist_condition
                                          );
  for pos in player_vision {
    terrain.is_tile_visible[pos.y][pos.x] = true;
    terrain.is_tile_hidden[pos.y][pos.x] = false;
  }
}

is_tile_walkable :: proc(pos: Vec2i, terrain: ^Terrain) -> bool {
  if pos.y < 0 || pos.y >= TERRAIN_H ||
     pos.x < 0 || pos.x >= TERRAIN_W {
    return false;
  }

  tile := terrain.tile_type[pos.y][pos.x];

  return  tile != .None && tile != .Terminal;
}

is_pos_valid :: proc(pos: Vec2i) -> bool {
  return pos.x >= 0 && pos.x < TERRAIN_W && pos.y >= 0 && pos.y < TERRAIN_H;
}

tile_get_button_id :: proc(tile : TileType) -> int {
  if (tile == .Square || tile == .SquareSymbol) { return 0; }
  if (tile == .Triangle || tile == .TriangleSymbol) { return 1; }
  if (tile == .Circle || tile == .CircleSymbol) { return 2; }
  return -1;
}

is_button :: proc(tile : TileType) -> bool {
  return tile_get_button_id(tile) != -1 ;
}

is_button_pressed :: proc(pos: Vec2i, game_manager: ^GameManager) -> bool {
  using game_manager;
  current_tile := terrain.tile_type[pos.y][pos.x];

  id := tile_get_button_id(current_tile);
  if id == -1 { return false; }

  return terrain.is_button_pressed[id];
}
