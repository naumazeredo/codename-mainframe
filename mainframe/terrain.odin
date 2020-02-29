package mainframe

import sdl "shared:odin-sdl2"

TERRAIN_W :: 32;
TERRAIN_H :: 18;

TILE_SIZE :: VIEW_W / TERRAIN_W;

TileType :: enum {
  Nothing,
  Solid,
  Warp
}

// @Note(naum): as it is right now it could be an alias, but I think we will add more stuff here
Tile :: struct {
  type: TileType
}

Terrain :: struct {
  tiles : [TERRAIN_H][TERRAIN_W]Tile,
}

new_terrain :: proc() -> Terrain {
  terrain : Terrain;
  using terrain;

  for j in 0..<TERRAIN_W/2-5 {
    tiles[0][j].type = TileType.Solid;
    tiles[TERRAIN_H-1][j].type = TileType.Solid;
  }

  for j in TERRAIN_W/2+5..<TERRAIN_W {
    tiles[0][j].type = TileType.Solid;
    tiles[TERRAIN_H-1][j].type = TileType.Solid;
  }

  for i in 1..<TERRAIN_H-1 {
    for j in 1..<TERRAIN_W-1 {
      tiles[i][j].type = TileType.Nothing;
    }
  }


  tiles[TERRAIN_H-2][3].type = TileType.Solid;

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

// @XXX: u8 instead of int?
get_tile_pos :: proc(v : Vec2) -> (int, int) {
  i := int(v.y / TILE_SIZE);
  j := int(v.x / TILE_SIZE);

  i = min(TERRAIN_H-1, max(0, i));
  j = min(TERRAIN_W-1, max(0, j));

  return i, j;
}
