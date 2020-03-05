package mainframe

import sdl "shared:odin-sdl2"

import "core:math/rand"
import "core:fmt"

MAX_ROOMS :: 256;
MAX_TUNNELS :: (MAX_ROOMS * (MAX_ROOMS - 1)) / 2;

Topology :: struct {
  rooms : [MAX_ROOMS]Room,

  n_of_rooms : int,
  n_of_tunnels: int,

  boss_room_id : int,

  tunnels : [MAX_TUNNELS][2]int,
}

Room :: struct {
  id : int,
  rect : Recti,
}

create_room :: proc(terrain: ^Terrain, room_rect: Recti) -> (int, bool) {
  using terrain;

  if room_rect.x + room_rect.w >= TERRAIN_W || room_rect.y + room_rect.h >= TERRAIN_H { return -1, false; }

  for i in room_rect.x..<room_rect.x+room_rect.w {
    for j in room_rect.y..<room_rect.y+room_rect.h {
      tiles[j][i].type = TileType.Ground;
    }
  }

  room_id := topology.n_of_rooms;
  new_room := Room{room_id, room_rect};
  topology.rooms[room_id] = new_room;

  topology.n_of_rooms += 1;

  return room_id, true;
}

can_rooms_coexist:: proc(a,b : Recti) -> bool {
  return (a.x + a.w < b.x || b.x + b.w < a.x) &&
         (a.y + a.w < b.y || b.y + b.w < a.y);
}

can_create_room :: proc (terrain : ^Terrain, room : Recti) -> bool {
  using terrain;
  for i in 0..<topology.n_of_rooms {
    if !can_rooms_coexist(topology.rooms[i].rect, room) { return false; }
  }

  return true;
}

//TODO(luciano): if we keep developing this game, make this function smaller
connect_rooms :: proc(terrain: ^Terrain, id1,id2 : int) -> bool {
  using terrain;

  if id1 >= topology.n_of_rooms || id2 >= topology.n_of_rooms ||
     id1 < 0 || id2 < 0 { return false; }

  if rooms_are_already_connected(&topology, id1,id2) { return false; }

  room1, room2 := topology.rooms[id1], topology.rooms[id2];

  y1, y2 := room1.rect.y , room2.rect.y;
  x1, x2 := room1.rect.x , room2.rect.x;
  h1, h2 := room1.rect.h , room2.rect.h;
  w1, w2 := room1.rect.w , room2.rect.w;

  left_room := x1 < x2 ? room1.rect : room2.rect;
  right_room := x1 < x2 ? room2.rect : room1.rect;
  upper_room := y1 < y2 ? room1.rect : room2.rect;
  lower_room := y1 < y2 ? room2.rect : room1.rect;

  rooms_can_have_horizontal_tunnel := (upper_room.y + upper_room.h > lower_room.y);

  if rooms_can_have_horizontal_tunnel {
    lower_bound := max(y1,y2);
    upper_bound := min(y1+h1, y2+h2);
    tunnel_y := rand_int32_range(lower_bound, upper_bound);

    for x in left_room.x + left_room.w .. right_room.x {
      tiles[tunnel_y][x].type = TileType.Ground;
    }

    _append_tunnel(&topology , id1, id2);

    return true;
  }

  rooms_can_have_vertical_tunnel := (left_room.x + left_room.h > right_room.x);

  if rooms_can_have_vertical_tunnel {
    lower_bound := max(x1,x2);
    upper_bound := min(x1+w1, x2+h2);

    tunnel_x := rand_int32_range(lower_bound,upper_bound);

    for y in upper_room.y + upper_room.h .. lower_room.y {
      tiles[y][tunnel_x].type = TileType.Ground;
    }

    _append_tunnel(&topology , id1, id2);

    return true;
  }

  is_upper_corner_path := (rand_int32_range(0, 2) % 2)== 0;
  tunnel_x, tunnel_y, y_lower, y_upper, x_lower, x_upper: int;
  if is_upper_corner_path {
    tunnel_x = rand_int32_range(lower_room.x, lower_room.x+lower_room.w);
    x_lower = min(tunnel_x, upper_room.x);
    x_upper = max(tunnel_x, upper_room.x);
    tunnel_y = rand_int32_range(upper_room.y, upper_room.y+upper_room.h);
    y_lower = tunnel_y;
    y_upper = lower_room.y;
  } else {
    tunnel_x = rand_int32_range(upper_room.x, upper_room.x+upper_room.w);
    x_lower = min(tunnel_x, lower_room.x);
    x_upper = max(tunnel_x, lower_room.x);
    tunnel_y = rand_int32_range(lower_room.y, lower_room.y+lower_room.h);
    y_lower = upper_room.y+upper_room.h;
    y_upper = tunnel_y;
  }

  for y in y_lower .. y_upper {
    tiles[y][tunnel_x].type = TileType.Ground;
  }

  for x in x_lower .. x_upper {
    tiles[tunnel_y][x].type = TileType.Ground;
  }

  return true;
}

rooms_are_already_connected :: proc(topology: ^Topology, id1, id2 : int) -> bool {
  using topology;
  for i in 0.. n_of_tunnels {
    if (tunnels[i][0] == id1 && tunnels[i][1] == id2) || (tunnels[i][0] == id2 && tunnels[i][1] == id1) {
       return true;
    }
  }
  return false;
}

_append_tunnel :: proc(topology : ^Topology, id1,id2: int) {
  topology.tunnels[topology.n_of_tunnels] = [2]int{id1,id2};
  topology.n_of_tunnels += 1;
}
MAX_ROOM_ATTEMPTS :: 50;
MAX_GENERATED_ROOMS :: 10;
MAX_CONNECTION_ATTEMPTS :: 10;
MAX_CONNECTIONS :: 3;
MAX_HOP_DISTANCE :: 2;
MAX_ROOM_WIDTH :: 10;
MIN_ROOM_WIDTH :: 4;
MAX_ROOM_HEIGHT :: 10;
MIN_ROOM_HEIGHT :: 4;
generate_rooms :: proc(terrain: ^Terrain) {
  using terrain;

  previous_room_id := -1;
  for i in 0..<MAX_ROOM_ATTEMPTS {
    x := rand_int32_range(0, 50);
    y := rand_int32_range(0, 50);
    h := rand_int32_range(MIN_ROOM_HEIGHT,MAX_ROOM_HEIGHT+1);
    w := rand_int32_range(MIN_ROOM_WIDTH, MAX_ROOM_WIDTH+1);

    possible_room := Recti{x,y,h,w};

    if can_create_room(terrain, possible_room) {
      created_room_id, _ := create_room(terrain,possible_room);
      connect_rooms(terrain, created_room_id, previous_room_id);

      previous_room_id = created_room_id;
    }

    if topology.n_of_rooms >= MAX_GENERATED_ROOMS { break; }
  }

  starting_room := topology.rooms[0].rect;
  enter = { starting_room.x , starting_room.y };

  topology.boss_room_id = topology.n_of_rooms - 1;

  n_of_interconnections := 0;
  for i in 0..<MAX_CONNECTION_ATTEMPTS{
    random_id1 := rand_int32_range(0,topology.n_of_rooms);
    random_id2 := rand_int32_range(0,topology.n_of_rooms);

    hop_distance := random_id1 - random_id2;
    if hop_distance < 0 { hop_distance = -hop_distance; }

    if hop_distance <= MAX_HOP_DISTANCE { connect_rooms(terrain, random_id1, random_id2); }

    if n_of_interconnections >= MAX_CONNECTIONS { break; }
  }
}

rand_int32_range :: proc(lo,hi :int) -> int{ return int(rand.uint32())%(hi-lo) + lo; }
