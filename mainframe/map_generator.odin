package mainframe

import sdl "shared:odin-sdl2"

import "core:math/rand"
import "core:fmt"

create_room :: proc(terrain: ^Terrain, room_rect: Recti) -> bool {
  using terrain;

  if room_rect.x + room_rect.w >= TERRAIN_W || room_rect.y + room_rect.h >= TERRAIN_H { return false; }

  for i in room_rect.x..<room_rect.x+room_rect.w {
    for j in room_rect.y..<room_rect.y+room_rect.h {
      tiles[i][j].type = TileType.Ground;
    }
  }

  return true;
}

can_rooms_coexist:: proc(a,b : Recti) -> bool {
  return (a.x + a.w < b.x || b.x + b.w < a.x) &&
         (a.y + a.w < b.y || b.y + b.w < a.y);
}

MAX_GENERATED_ROOMS :: 5;
MAX_ROOM_WIDTH :: 5;
MIN_ROOM_WIDTH :: 2;
MAX_ROOM_HEIGHT :: 5;
MIN_ROOM_HEIGHT :: 2;
generate_rooms :: proc(terrain: ^Terrain) {
  for i in 0..<MAX_GENERATED_ROOMS {
    x := rand_int32_range(0, 10); // TODO: bound to whole map
    y := rand_int32_range(0, 10);
    h := rand_int32_range(MIN_ROOM_HEIGHT,MAX_ROOM_HEIGHT+1);
    w := rand_int32_range(MIN_ROOM_WIDTH, MAX_ROOM_WIDTH+1);

    possible_room := Recti{x,y,h,w}; // TODO: test intersection and create paths

    create_room(terrain,possible_room);
  }
}

rand_int32_range :: proc(lo,hi :int) -> int{ return int(rand.uint32())%(hi-lo) + lo; }
