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

Tile :: struct {
  type : TileType,
}

Terrain :: struct {
  tiles : [TERRAIN_H][TERRAIN_W] Tile,
  enter : Vec2i,
  debugger_top: Vec2i // @Incorrect(naum): isn't this HUD? Not a terrain related thing.
}

create_terrain :: proc(terrain: ^Terrain) {
  using terrain;

  for i in 0..<TERRAIN_H {
    for j in 0..<TERRAIN_W {
      tiles[i][j].type = TileType.None;
    }
  }

  for i in 1..5 {
    for j in 1..5 {
      tiles[i][j].type = TileType.Ground;
    }
  }

  tiles[1][1].type = TileType.File;
  tiles[1][3].type = TileType.File;
  tiles[3][1].type = TileType.File;

  enter = Vec2i{ 3, 3 };
  debugger_top = Vec2i{ 0, 0 };
}

is_tile_walkable :: proc(pos: Vec2i, terrain: ^Terrain) -> bool {
  if pos.y < 0 || pos.y >= TERRAIN_H ||
     pos.x < 0 || pos.x >= TERRAIN_W {
    return false;
  }

  return terrain.tiles[pos.y][pos.x].type != TileType.None;
}

is_tile_file :: proc(pos: Vec2i, terrain: ^Terrain) -> bool {
  if pos.y < 0 || pos.y >= TERRAIN_H ||
     pos.x < 0 || pos.x >= TERRAIN_W {
    return false;
  }

  return terrain.tiles[pos.y][pos.x].type == TileType.File;
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
