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

is_room_out_of_bounds :: proc(room_rect : Recti) -> bool {
  return room_rect.x + room_rect.w >= TERRAIN_W ||
     room_rect.y + room_rect.h >= TERRAIN_H ||
     room_rect.x < 0 ||
     room_rect.y < 0;
}

create_room :: proc(terrain: ^Terrain, room_rect: Recti) -> (int, bool) {
  using terrain;

  if is_room_out_of_bounds(room_rect) { return -1, false; }

  for i in room_rect.x..<room_rect.x+room_rect.w {
    for j in room_rect.y..<room_rect.y+room_rect.h {
      tile_type[j][i] = TileType.Ground;
    }
  }

  room_id := topology.n_of_rooms;
  new_room := Room{room_id, room_rect};
  topology.rooms[room_id] = new_room;

  topology.n_of_rooms += 1;

  return room_id, true;
}

create_boss_room :: proc(terrain : ^Terrain, enemy_container: ^EnemyContainer) {
  using terrain.topology;

  boss_x := 5*MAX_ROOM_WIDTH;
  boss_y := 5*MAX_ROOM_HEIGHT;
  boss_h := rand_int32_range(MIN_ROOM_HEIGHT, MAX_ROOM_HEIGHT+1); // can remove duplicate code by adding
  boss_w := rand_int32_range(MIN_ROOM_WIDTH, MAX_ROOM_WIDTH+1);   // a function
  boss_room := Recti{boss_x,boss_y,boss_w,boss_h};

  terrain.enter = Vec2i{boss_x, boss_y};

  boss_room_id, _ = create_room(terrain, boss_room);

  boss_mid_y := boss_y + (boss_w) / 2;
  boss_mid_x := boss_x + (boss_h) / 2;

  h := rand_int32_range(MIN_ROOM_HEIGHT,MAX_ROOM_HEIGHT+1);
  w := rand_int32_range(MIN_ROOM_WIDTH, MAX_ROOM_WIDTH+1);
  x := boss_x - w - MAX_ROOM_WIDTH/2 - 1;
  y := boss_mid_y - h/2;
  boss_left_room := Recti{x,y,w,h};

  room_id, _ := create_room(terrain,boss_left_room);
  connect_rooms(terrain, boss_room_id, room_id);
  generate_room_enemies(terrain, enemy_container, room_id);

  h = rand_int32_range(MIN_ROOM_HEIGHT,MAX_ROOM_HEIGHT+1);
  w = rand_int32_range(MIN_ROOM_WIDTH, MAX_ROOM_WIDTH+1);
  x = boss_x + boss_w + MAX_ROOM_WIDTH/2 + 1;
  y = boss_mid_y - h/2;
  boss_right_room := Recti{x,y,w,h};

  room_id, _ = create_room(terrain,boss_right_room);
  connect_rooms(terrain, boss_room_id, room_id);
  generate_room_enemies(terrain, enemy_container, room_id);

  h = rand_int32_range(MIN_ROOM_HEIGHT,MAX_ROOM_HEIGHT+1);
  w = rand_int32_range(MIN_ROOM_WIDTH, MAX_ROOM_WIDTH+1);
  x = boss_mid_x - w/2;
  y = boss_y - h - MAX_ROOM_HEIGHT/2 - 1;
  boss_upper_room := Recti{x,y,w,w};

  room_id, _ = create_room(terrain,boss_upper_room);
  connect_rooms(terrain, boss_room_id, room_id);
  generate_room_enemies(terrain, enemy_container, room_id);

  place_buttons(terrain);
}

place_buttons :: proc(terrain : ^Terrain) {
  using terrain.topology;

  room := rooms[0].rect;
  terrain.tile_type[room.y+room.h/2][room.x+room.w/2] = .Terminal;

  shuffled_buttons := generate_shuffled_buttons();
  symbol_type : TileType;
  for i in 0..2 {
    // place terminal buttons
    if terrain.button_sequence[i] == .Square { symbol_type = .SquareSymbol; }
    if terrain.button_sequence[i] == .Circle { symbol_type = .CircleSymbol; }
    if terrain.button_sequence[i] == .Triangle { symbol_type = .TriangleSymbol; }
    terrain.tile_type[room.y+1+room.h/2][room.x+i-1+room.w/2] = symbol_type;

    random_room := rooms[i+1].rect;
    random_spot := pick_room_spot(random_room);
    terrain.tile_type[random_spot.y][random_spot.x] = shuffled_buttons[i];
  }
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

is_empty_area :: proc(terrain : ^Terrain, room :Recti) -> bool {
  using terrain;

  if is_room_out_of_bounds(room) { return false; }

  lower_limit_y := room.y == 0 ? 0 : room.y -1;
  lower_limit_x := room.x == 0 ? 0 : room.x -1;

  for x in lower_limit_x..room.x+room.w {
    for y in lower_limit_y..room.y+room.h {
      if tile_type[y][x] != TileType.None {
        return false;
      }
    }
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
      tile_type[tunnel_y][x] = TileType.Ground;
    }

    _append_tunnel(&topology , id1, id2);

    return true;
  }

  rooms_can_have_vertical_tunnel := (left_room.x + left_room.h > right_room.x);

  if rooms_can_have_vertical_tunnel {
    lower_bound := max(x1,x2);
    upper_bound := min(x1+w1, x2+w2);

    tunnel_x := rand_int32_range(lower_bound,upper_bound);

    for y in upper_room.y + upper_room.h .. lower_room.y {
      tile_type[y][tunnel_x] = TileType.Ground;
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
    tile_type[y][tunnel_x] = TileType.Ground;
   }

  for x in x_lower .. x_upper {
    tile_type[tunnel_y][x] = TileType.Ground;
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

MAX_GENERATED_ROOMS :: 15;
MAX_CONNECTION_ATTEMPTS :: 10;
MAX_CONNECTIONS :: 3;
MAX_HOP_DISTANCE :: 2;
MAX_ROOM_WIDTH :: 10;
MIN_ROOM_WIDTH :: 4;
MAX_ROOM_HEIGHT :: 10;
MIN_ROOM_HEIGHT :: 4;
EXPANSION_STEP :: 5;
MAX_EXPANSION_ATTEMPTS :: 10;
generate_rooms :: proc(terrain: ^Terrain, enemy_container: ^EnemyContainer) {
  using terrain;

  create_boss_room(terrain, enemy_container);

  random_id := topology.boss_room_id;
  random_room := topology.rooms[random_id];
  directions := [3][2]int{ {0,1}, {1,0}, {-1,0} };
  expansion_index := 0;
  expansion_direction := directions[expansion_index];
  for i in 0..<MAX_GENERATED_ROOMS {
  
    expansion_start := pick_room_spot(topology.rooms[random_id].rect);
    h := rand_int32_range(MIN_ROOM_HEIGHT, MAX_ROOM_HEIGHT+1);
    w := rand_int32_range(MIN_ROOM_WIDTH, MAX_ROOM_WIDTH+1);
  
    possible_room := Recti{expansion_start.x,expansion_start.y,h,w};
    expansion_attempts := 0;
    for !is_empty_area(terrain,possible_room) {
      expansion_attempts +=1;
      possible_room.x += expansion_direction.x * EXPANSION_STEP;
      possible_room.y += expansion_direction.y * EXPANSION_STEP;

      if expansion_attempts >= MAX_EXPANSION_ATTEMPTS {
        expansion_index = (expansion_index + 1)% 3;
        expansion_direction = directions[expansion_index];

        possible_room = Recti{expansion_start.x,expansion_start.y,h,w};
        expansion_attempts = 0;
      }
    }
  
    created_room_id, _ := create_room(terrain,possible_room);
    connect_rooms(terrain, created_room_id, random_id);

    if (i != MAX_GENERATED_ROOMS-1) { generate_room_enemies(terrain, enemy_container, created_room_id); }
  
    expansion_direction = directions[rand_int32_range(0,3)];
    random_id = rand_int32_range(4,topology.n_of_rooms);
  }
  
  starting_room := topology.rooms[topology.n_of_rooms-1].rect;
  enter = { starting_room.x , starting_room.y };
  
  topology.boss_room_id = topology.n_of_rooms - 1;
  
  n_of_interconnections := 0;
  for i in 0..<MAX_CONNECTION_ATTEMPTS{
    random_id1 := rand_int32_range(4,topology.n_of_rooms); // we use for to not interconnect boss room pattern
    random_id2 := rand_int32_range(4,topology.n_of_rooms);
  
    hop_distance := random_id1 - random_id2;
    if hop_distance < 0 { hop_distance = -hop_distance; }
  
    if hop_distance <= MAX_HOP_DISTANCE { connect_rooms(terrain, random_id1, random_id2); }
  
    if n_of_interconnections >= MAX_CONNECTIONS { break; }
  }
}

MIN_ENEMIES_PER_ROOM :: 1;
MAX_ENEMIES_PER_ROOM :: 3;

generate_room_enemies :: proc(terrain : ^Terrain, enemy_container : ^EnemyContainer, room_id : int) {
  room := terrain.topology.rooms[room_id].rect;

  scale_max := room.w*room.h;
  scale_value := rand_int32_range(1, MAX_ROOM_WIDTH*MAX_ROOM_HEIGHT+1);
  max_n_of_enemies := int((scale_value/scale_max) + 1.0);

  n_of_enemies := rand_int32_range(MIN_ENEMIES_PER_ROOM, max_n_of_enemies+1);

  for i in 0..<n_of_enemies {
    enemy_spot := pick_room_spot(room);

    enemy_type := pick_enemy_type();

    create_enemy(enemy_type, enemy_spot, enemy_container);
  }
}

pick_room_spot :: proc(rect: Recti) -> Vec2i {
  random_x := rand_int32_range(rect.x, rect.x + rect.w);
  random_y := rand_int32_range(rect.y, rect.y + rect.h);

  return Vec2i{max(random_x, 0), max(random_y, 0)};
}

// result lies between lo inclusive and hi exclusive
rand_int32_range :: proc(lo,hi :int) -> int{ return int(rand.uint32())%(hi-lo) + lo; }
