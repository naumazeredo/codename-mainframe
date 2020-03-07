package mainframe

import "core:fmt";

// -----------
// Basic types
// -----------

//Vec2 :: [2]f32;
Vec2i :: [2]int;
Color :: [4]u8;
Recti :: struct { x, y, w, h : int }

WHITE :: Color { 255, 255, 255, 255 };

// ---------------------
// Basic data structures
// ---------------------

Stack :: struct(T: typeid) {
  mem : [dynamic]T,
}

stack_insert :: proc(stack: ^Stack($T), value: T) { append(&stack.mem, value); }
stack_pop    :: proc(stack: ^Stack($T)) -> T      { return pop(&stack.mem); }

Queue :: struct(T: typeid) {
  start, size: int,
  mem : [dynamic]T,
}

queue_insert :: proc(queue: ^Queue($T), value: T) {
  using queue;
  if size == len(mem) {
    temp := make([]T, size);
    p := start;

    for i in 0..<size {
      temp[i] = mem[p];
      p = (p+1)%len(mem);
    }

    for i in 0..<size {
      mem[i] = temp[i];
    }

    len := 2 * len(mem) + 8;
    resize(&mem, len);
    start = 0;
  }

  mem[(start+size)%len(mem)] = value;
  size += 1;
}

queue_pop :: proc(queue: ^Queue($T)) -> T {
  using queue;
  assert(size > 0);
  v := mem[start];
  start = (start+1)%len(mem);
  size -= 1;

  // @Todo(naum): reduce memory (4*size <= len(mem))

  return v;
}

queue_front :: proc(queue: ^Queue($T)) -> T {
  using queue;
  assert(size > 0);
  return mem[start];
}

queue_len :: proc(queue: ^Queue($T)) -> int {
  return queue.size;
}

create_queue :: proc(array: [dynamic]$T) -> Queue(T) {
  q : Queue(T);
  q.start = 0;
  q.size = len(array);
  q.mem = array;
  return q;
}

// @MaybeFix(naum): no multithreading
_back : [TERRAIN_H][TERRAIN_W]Vec2i;
_deltas := []Vec2i { {-1, 0}, {1, 0}, {0, -1}, {0, 1} };

calculate_bfs :: proc(start, end : Vec2i, terrain: ^Terrain) -> Queue(Vec2i) {
  for i in 0..<TERRAIN_H {
    for j in 0..<TERRAIN_W {
      _back[i][j] = {-1, -1};
    }
  }

  q : Queue(Vec2i);
  queue_insert(&q, start);
  _back[start.y][start.x] = {-1, 0};

  for queue_len(&q) != 0 {
    pos := queue_pop(&q);

    if pos == end {
      path : [dynamic]Vec2i;

      // @Note(naum): ignores the start position
      for _back[pos.y][pos.x].x != -1 {
        append(&path, pos);
        pos = _back[pos.y][pos.x];
      }

      return create_queue(reverse(path));
    }

    for delta in _deltas {
      next := pos + delta;
      if is_pos_valid(next) && _back[next.y][next.x] == {-1, -1} && is_tile_walkable(next, terrain) {
        _back[next.y][next.x] = pos;
        queue_insert(&q, next);
      }
    }
  }

  fmt.println("Didn't find a path!");
  assert(false);
  return {};
}

_dist: [TERRAIN_H][TERRAIN_W]int;

ConditionType :: proc(start: Vec2i, pos: Vec2i, dist: int, max_dist: int, terrain: ^Terrain) -> bool;
// @WTF(naum): Odin issue? No way to reuse ConditionType to not type the whole proc stuff everytime?
always_true_condition :: proc(start: Vec2i, pos: Vec2i, dist: int, max_dist: int, terrain: ^Terrain) -> bool { return true; }

tile_walkable_condition :: proc(start: Vec2i, pos: Vec2i, dist: int, max_dist: int, terrain: ^Terrain) -> bool {
  return is_tile_walkable(pos, terrain) && pos != start;
}

tile_ground_and_not_start_condition :: proc(start: Vec2i, pos: Vec2i, dist: int, max_dist: int, terrain: ^Terrain) -> bool {
  return terrain.tile_type[pos.y][pos.x] == .Ground && pos != start;
}

in_euclid_dist_condition :: proc(start: Vec2i, pos: Vec2i, dist: int, max_dist: int, terrain: ^Terrain) -> bool {
  delta := pos - start;
  delta_sq := delta * delta;
  return delta_sq.x + delta_sq.y <= max_dist * max_dist;
}

custom_euclid_dist_condition :: proc(start: Vec2i, pos: Vec2i, dist: int, max_dist: int, terrain: ^Terrain) -> bool {
  delta := pos - start;
  delta_sq := delta * delta;
  return delta_sq.x + delta_sq.y < max_dist * max_dist - 1;
}

dist_in_max_dist_condition :: proc(start: Vec2i, pos: Vec2i, dist: int, max_dist: int, terrain: ^Terrain) -> bool {
  return dist <= max_dist;
}

square_in_max_dist_condition :: proc(start: Vec2i, pos: Vec2i, dist: int, max_dist: int, terrain: ^Terrain) -> bool {
  delta := pos - start;
  return max(abs(delta.x), abs(delta.y)) <= max_dist;
}

calculate_bfs_region :: proc(start: Vec2i,
                             max_dist: int,
                             terrain: ^Terrain,
                             add_condition: ConditionType = always_true_condition,
                             valid_condition: ConditionType = dist_in_max_dist_condition,
                             next_condition: ConditionType = always_true_condition
                            ) -> ([]Vec2i, []int) {

  assert(max_dist >= 0);
  for i in 0..<TERRAIN_H {
    for j in 0..<TERRAIN_W {
      _dist[i][j] = -1;
    }
  }

  region_pos  : [dynamic]Vec2i;
  region_dist : [dynamic]int;

  q : Queue(Vec2i);
  queue_insert(&q, start);
  _dist[start.y][start.x] = 0;

  for queue_len(&q) != 0 {
    pos := queue_pop(&q);
    dist := _dist[pos.y][pos.x];

    if !valid_condition(start, pos, dist, max_dist, terrain) {
      continue;
    }

    if add_condition(start, pos, dist, max_dist, terrain) {
      append(&region_pos,  pos );
      append(&region_dist, dist);
    }


    for delta in _deltas {
      next := pos + delta;
      if is_pos_valid(next) && _dist[next.y][next.x] == -1 &&
         next_condition(start, next, _dist[next.y][next.x], max_dist, terrain) {

        _dist[next.y][next.x] = dist + 1;
        queue_insert(&q, next);
      }
    }
  }

  return region_pos[:], region_dist[:];
}

// ----------------
// Custom functions
// ----------------

reverse :: proc(array: [dynamic]$E) -> [dynamic]E {
  rev : [dynamic]E;
  for i := len(array)-1 ; i >= 0 ; i -= 1 {
    append(&rev, array[i]);
  }
  return rev;
}

// ----------
// Render FPS
// ----------
/*

add_fps_counter :: proc(renderer: ^sdl.Renderer, font: ^sdl_ttf.Font, frame_duration: f64, text_pos: ^sdl.Rect, h, w: ^i32) {
    builder := strings.make_builder();
    defer strings.destroy_builder(&builder);

    strings.write_string(&builder, "FPS: ");
    write_f64(&builder, 1/frame_duration);

    fps_counter := strings.clone_to_cstring(strings.to_string(builder));
    text_surface := sdl_ttf.render_utf8_solid(font, fps_counter, sdl.Color{0, 255, 0, 255});
    text_texture := sdl.create_texture_from_surface(renderer, text_surface);
    sdl.free_surface(text_surface);

    sdl.query_texture(text_texture, nil, nil, w, h);
    sdl.render_copy(renderer, text_texture, nil, text_pos);
}

write_f64 :: proc(builder: ^strings.Builder, v: f64, digits: uint = 6) {
  vv := v;

  if vv < 0 {
    strings.write_byte(builder, '-');
    vv = -vv;
  }


  integral : uint = auto_cast vv;

  strings.write_uint(builder, integral);
  strings.write_byte(builder, '.');

  for i in 1..digits {
    vv -= cast(f64)integral;
    vv *= 10.0;
    integral = auto_cast vv;
    strings.write_uint(builder, integral);
  }
}
*/
