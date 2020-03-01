package mainframe

import sdl "shared:odin-sdl2"

TILE_SIZE :: 32;

TERRAIN_CHUNK_H :: 16;
TERRAIN_CHUNK_W :: 16;

TileType :: enum {
  None,
  Ground
}

Tile :: struct {
  type : TileType,
  //pos  : Vec2
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
