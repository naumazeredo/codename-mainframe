package mainframe

import "core:fmt"

import sdl "shared:odin-sdl2"

TILE_SIZE :: 32;

TERRAIN_H :: 256;
TERRAIN_W :: 256;

TileType :: enum {
  None,
  Ground,
  File,
}

// @Idea(naum): Maybe test #soa
Terrain :: struct {
  tile_type : [TERRAIN_H][TERRAIN_W]TileType,
  is_tile_being_scanned : [TERRAIN_H][TERRAIN_W]bool,
  enter : Vec2i,

  topology: Topology,
}

create_test_terrain :: proc(game_manager: ^GameManager) {
  using game_manager;

  for i in 0..<TERRAIN_H {
    for j in 0..<TERRAIN_W {
      terrain.tile_type[i][j] = .None;
      terrain.is_tile_being_scanned[i][j] = false;
    }
  }

  clear_enemy_container(&enemy_container);

  // 0 -> nothing
  // 1 -> player start
  // 2 -> ground
  // 3 -> file
  // 4 -> patrol AMS (left)
  // 5 -> circle AMS (down)
  custom_terrain := [12][12]u8 {
    { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0 },
    { 0, 2, 2, 2, 5, 2, 0, 0, 2, 2, 2, 0 },
    { 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4, 0 },
    { 0, 2, 2, 2, 2, 2, 0, 0, 2, 2, 2, 0 },
    { 0, 2, 2, 2, 2, 2, 0, 0, 0, 2, 0, 0 },
    { 0, 0, 0, 0, 2, 0, 0, 2, 2, 2, 2, 0 },
    { 0, 0, 0, 0, 2, 2, 2, 2, 3, 2, 2, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 2, 2, 3, 2, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 2, 3, 1, 2, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
  };

  for row, i in custom_terrain {
    for elem, j in row {
      terrain.tile_type[i][j] = .Ground;

      switch elem {
        case 0: // nothing
          terrain.tile_type[i][j] = .None;
        case 1: // player
          terrain.enter = Vec2i{ j, i };
          player.pos = terrain.enter;
        case 3: // file
          terrain.tile_type[i][j] = .File;
        case 4: // enemy back and forth
          create_enemy(.BackAndForth, { j, i }, &enemy_container);
        case 5: // enemy circle 3x3
          create_enemy(.Circle3x3, { j, i }, &enemy_container);
      }
    }
  }

  clock_debugger.pivot = Vec2i{ 0, 0 }; // @Todo(naum): move this.. it's a terrain variable

  // mock terrain generation TODO(luciano): remove

  id1, _ := create_room(&terrain, Recti{5, 15, 5, 5});
  id3, _ := create_room(&terrain, Recti{6, 12, 2, 2});
  id4, _ := create_room(&terrain, Recti{1, 12, 2, 2});
  id5, _ := create_room(&terrain, Recti{15, 12, 2, 2});
  id6, _ := create_room(&terrain, Recti{1, 17, 2, 2});
  connect_rooms(&terrain, id1, id3);
  connect_rooms(&terrain, id1, id4);
  connect_rooms(&terrain, id1, id5);
  connect_rooms(&terrain, id1, id6);
}

create_terrain :: proc(game_manager: ^GameManager) {
  using game_manager;

  for i in 0..<TERRAIN_H {
    for j in 0..<TERRAIN_W {
      terrain.tile_type[i][j] = .None;
    }
  }
  clear_enemy_container(&enemy_container);

  //generate_rooms(&terrain);
  create_boss_room_template(&terrain);

  player.pos = terrain.enter;

  clock_debugger.pivot = Vec2i{ 0, 0 }; // @Todo(naum): move this.. it's a terrain variable
}

update_terrain_clock_tick :: proc(game_manager: ^GameManager) {
  using game_manager;

  for i in 0..<TERRAIN_H {
    for j in 0..<TERRAIN_W {
      terrain.is_tile_being_scanned[i][j] = false;
    }
  }
}

is_tile_walkable :: proc(pos: Vec2i, terrain: ^Terrain) -> bool {
  if pos.y < 0 || pos.y >= TERRAIN_H ||
     pos.x < 0 || pos.x >= TERRAIN_W {
    return false;
  }

  return terrain.tile_type[pos.y][pos.x] != .None;
}

is_tile_file :: proc(pos: Vec2i, terrain: ^Terrain) -> bool {
  if pos.y < 0 || pos.y >= TERRAIN_H ||
     pos.x < 0 || pos.x >= TERRAIN_W {
    return false;
  }

  return terrain.tile_type[pos.y][pos.x] == .File;
}

is_pos_valid :: proc(pos: Vec2i) -> bool {
  return pos.x >= 0 && pos.x < TERRAIN_W && pos.y >= 0 && pos.y < TERRAIN_H;
}

// @XXX
tile_to_rect :: proc(i, j : int) -> Rect {
  return Rect {
    f32(j * TILE_SIZE), f32(i * TILE_SIZE),
    f32(TILE_SIZE), f32(TILE_SIZE)
  };
}

tile_pos :: proc(i, j : int) -> Vec2 {
  return Vec2{
    f32(j * TILE_SIZE), f32(i * TILE_SIZE),
  };
}

tile_to_sdlrect :: proc(i, j : int) -> sdl.Rect {
  return sdl.Rect {
    i32(j * TILE_SIZE),
    i32(i * TILE_SIZE),
    TILE_SIZE,
    TILE_SIZE
  };
}
