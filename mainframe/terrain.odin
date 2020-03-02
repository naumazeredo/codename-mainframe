package mainframe

import sdl "shared:odin-sdl2"

TILE_SIZE :: 32;

TERRAIN_H :: 256;
TERRAIN_W :: 256;

TileType :: enum {
  None,
  Ground,
}

Tile :: struct {
  type : TileType,
}

Terrain :: struct {
  tiles : [TERRAIN_H][TERRAIN_W] Tile,
  enter : Vec2i,
  debugger_top: Vec2i
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

/*
// @XXX: u8 instead of int?
get_tile_pos :: proc(v : Vec2) -> (int, int) {
  i := int(v.y / TILE_SIZE);
  j := int(v.x / TILE_SIZE);

  i = min(TERRAIN_H-1, max(0, i));
  j = min(TERRAIN_W-1, max(0, j));

  return i, j;
}
*/

/*
TERRAIN_CHUNK_H :: 256;
TERRAIN_CHUNK_W :: 256;

// @XXX(naum): in case it's needed to do terrain streaming
Tile :: struct {
  type : TileType,
}

TerrainChunk :: struct {
  tiles : [TERRAIN_CHUNK_H][TERRAIN_CHUNK_W] Tile,
  pos   : Vec2i, // tiles[i][j] -> (pos.x+j, pos.y+i)
}

Terrain :: struct {
  chunks : [dynamic] TerrainChunk,
}

create_terrain_chunk :: proc() -> TerrainChunk {
  chunk : TerrainChunk;
  using chunk;

  for i in 1..5 {
    for j in 1..5 {
      tiles[i][j].type = TileType.Ground;
    }
  }

  return chunk;
}

create_terrain :: proc() -> Terrain {
  terrain : Terrain;
  using terrain;

  append(&chunks, create_terrain_chunk());

  return terrain;
}
*/

