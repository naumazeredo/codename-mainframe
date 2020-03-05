package mainframe

import "core:strings"
import "core:fmt"

import sdl "shared:odin-sdl2"
import sdl_ttf "shared:odin-sdl2/ttf"

CPU_COUNT_WIDTH     :: 8;
CPU_COUNT_HEIGHT    :: 10;
CPU_COUNT_SPACING   :: 2;
CPU_COUNT_OFFSET_Y  :: -5;
CPU_FILLED_COLOUR   :: Color {200, 200, 255, 255};
CPU_UNFILLED_COLOUR :: Color {64, 64, 64, 255};
CPU_CAN_ACT_COLOUR  :: Color {100, 255, 100, 255};

INVENTORY_SPACING :: 4;
INVENTORY_POS_X :: INVENTORY_SPACING;
INVENTORY_POS_Y :: VIEW_H - INVENTORY_FILE_HEIGHT - INVENTORY_SPACING;
INVENTORY_FILE_WIDTH  :: 28;
INVENTORY_FILE_HEIGHT :: 40;

RenderManager :: struct {
  font     : ^sdl_ttf.Font,
  window   : ^sdl.Window,
  renderer : ^sdl.Renderer,

  camera_pos : Vec2i,
  //update_camera_pos : bool,
}

create_render_manager :: proc(render_manager: ^RenderManager) {
  using render_manager;

  // -----
  // Window / Renderer / Font
  // -----

  window = sdl.create_window(
    "Codename Rogue",
    i32(sdl.Window_Pos.Undefined),
    i32(sdl.Window_Pos.Undefined),
    VIEW_W, VIEW_H,
    sdl.Window_Flags.Allow_High_DPI
  );
  assert(window != nil);
  fmt.println("window created!");

  renderer = sdl.create_renderer(
    window,
    -1,
    sdl.Renderer_Flags(0)
  );
  assert(renderer != nil);
  fmt.println("renderer created!");

  // @DeleteMe(naum): remove this when we have proper graphics
  sdl.set_render_draw_blend_mode(renderer, sdl.Blend_Mode.Blend);

  font = sdl_ttf.open_font("arial.ttf", 40);
  assert(font != nil);
  fmt.println("font loaded!");

  // -----
  //
  // -----

  camera_pos = Vec2i { 0, 0 };

  // -------
  // Startup prints
  // -------

  w, h : i32;
  sdl.get_window_size(render_manager.window, &w, &h);

  w_render, h_render : i32;
  sdl.get_renderer_output_size(render_manager.renderer, &w_render, &h_render);

  fmt.printf("screen size: (%d, %d)\n", w, h);
  fmt.printf("render size: (%d, %d)\n", w_render, h_render);
}

destroy_render_manager :: proc(render_manager: ^RenderManager) {
  using render_manager;
  sdl.destroy_window(window);
  sdl.destroy_renderer(renderer);
}

// @Note(naum): remember Mac issue with screen size vs render size
render :: proc(game_manager : ^GameManager) {
  using game_manager;

  // Update render information
  // @XXX(naum): use update_camera_pos?
  //if render_manager.update_camera_pos {
    render_manager.camera_pos = Vec2i {
      player.pos.x * TILE_SIZE + TILE_SIZE/2 - VIEW_W/2,
      player.pos.y * TILE_SIZE + TILE_SIZE/2 - VIEW_H/2
    };
    //render_manager.update_camera_pos = false;
  //}

  viewport_rect : sdl.Rect;

  // Clear viewport
  sdl.render_set_viewport(render_manager.renderer, nil);
  sdl.set_render_draw_color(render_manager.renderer, 0, 0, 0, 255);
  sdl.render_clear(render_manager.renderer);

  // @Todo(naum): use game state state
  switch game_state {
    case .MainMenu :
      fmt.println("main menu!");
    case .Play :
      render_terrain(game_manager);
      render_player(game_manager);
      render_enemies(game_manager);
      render_scan(game_manager);

      // HUD
      render_clock_debugger(game_manager);
      render_inventory(game_manager);

      render_player_next_action(game_manager);
      render_cpu_counts(game_manager);
  }

  sdl.render_present(render_manager.renderer);
}

render_terrain :: proc(game_manager : ^GameManager) {
  using game_manager;

  GROUND_COLOR :: Color {100, 100, 100, 255};
  FILE_COLOR   :: Color {80, 200, 60, 255};

  for i in 0..<TERRAIN_H {
    for j in 0..<TERRAIN_W {
      if terrain.tile_type[i][j] == TileType.None {
        continue;
      }

      tile_pos := Vec2i{ j, i } * TILE_SIZE - render_manager.camera_pos;

      tile_rect := sdl.Rect {
        i32(tile_pos.x + 1), i32(tile_pos.y + 1),
        i32(TILE_SIZE - 2), i32(TILE_SIZE - 2)
      };

      if terrain.tile_type[i][j] == TileType.Ground {
        sdl.set_render_draw_color(
          render_manager.renderer,
          GROUND_COLOR.r, GROUND_COLOR.g, GROUND_COLOR.b, GROUND_COLOR.a
        );
      } else {
        sdl.set_render_draw_color(
          render_manager.renderer,
          FILE_COLOR.r, FILE_COLOR.g, FILE_COLOR.b, FILE_COLOR.a
        );
      }

      sdl.render_fill_rect(render_manager.renderer, &tile_rect);
    }
  }
}

render_scan :: proc(game_manager : ^GameManager) {
  using game_manager;

  SCAN_COLOR :: Color {100, 255, 100, 128};

  for i in 0..<TERRAIN_H {
    for j in 0..<TERRAIN_W {
      if !terrain.is_tile_being_scanned[i][j] {
        continue;
      }

      tile_pos := Vec2i{ j, i } * TILE_SIZE - render_manager.camera_pos;

      tile_rect := sdl.Rect {
        i32(tile_pos.x + 1), i32(tile_pos.y + 1),
        i32(TILE_SIZE - 2), i32(TILE_SIZE - 2)
      };

      sdl.set_render_draw_color(
        render_manager.renderer,
        SCAN_COLOR.r, SCAN_COLOR.g, SCAN_COLOR.b, SCAN_COLOR.a
      );

      sdl.render_fill_rect(render_manager.renderer, &tile_rect);
    }
  }
}

render_player :: proc(game_manager : ^GameManager) {
  using game_manager;

  pos := TILE_SIZE * player.pos - render_manager.camera_pos;

  rect := sdl.Rect {
    i32(pos.x + 2), i32(pos.y + 2),
    i32(TILE_SIZE - 4), i32(TILE_SIZE - 4)
  };

  sdl.set_render_draw_color(render_manager.renderer, 20, 40, 200, 255);
  sdl.render_fill_rect(render_manager.renderer, &rect);
}

render_enemies :: proc(game_manager: ^GameManager) {
  using game_manager;

  for i in 0..<enemy_container.count {
    pos := TILE_SIZE * enemy_container.pos[i] - render_manager.camera_pos;

    rect := sdl.Rect {
      i32(pos.x + 2), i32(pos.y + 2),
      i32(TILE_SIZE - 4), i32(TILE_SIZE - 4)
    };

    if enemy_container.state[i] == .Alert {
      sdl.set_render_draw_color(render_manager.renderer, 255, 20, 10, 255);
    } else {
      sdl.set_render_draw_color(render_manager.renderer, 120, 20, 10, 255);
    }
    sdl.render_fill_rect(render_manager.renderer, &rect);
  }
}

// -----
//  HUD
// -----

render_cpu_counts :: proc(game_manager: ^GameManager) {
  using game_manager;
  pos : Vec2i;


  // Player CPU count
  pos = player.pos * TILE_SIZE - render_manager.camera_pos;
  render_cpu_count(
    player.cpu_count, player.cpu_total,
    { pos.x + TILE_SIZE/2, pos.y },
    game_manager
  );

  // Enemies CPU counts
  for i in 0..<enemy_container.count {
    pos = enemy_container.pos[i] * TILE_SIZE - render_manager.camera_pos;
    type := int(enemy_container.type[i]);
    render_cpu_count(
      enemy_container.cpu_count[i], enemy_type_attributes[type].cpu_total,
      { pos.x + TILE_SIZE/2, pos.y },
      game_manager
    );
  }
}

render_cpu_count:: proc(cpu_count, cpu_total: u8, pivot : Vec2i, game_manager: ^GameManager) {
  using game_manager;

  total_width := int(cpu_total) * CPU_COUNT_WIDTH + (int(cpu_total)-1) * CPU_COUNT_SPACING;

  pos_x := i32(pivot.x - total_width / 2);
  pos_y := i32(pivot.y + CPU_COUNT_OFFSET_Y - CPU_COUNT_HEIGHT);

  if cpu_count == cpu_total-1 {

    sdl.set_render_draw_color(render_manager.renderer,
      CPU_CAN_ACT_COLOUR.r, CPU_CAN_ACT_COLOUR.g, CPU_CAN_ACT_COLOUR.b, CPU_CAN_ACT_COLOUR.a
    );

    for i in 0..<cpu_total {
      rect := sdl.Rect {
        pos_x, pos_y,
        i32(CPU_COUNT_WIDTH), i32(CPU_COUNT_HEIGHT)
      };

      sdl.render_fill_rect(render_manager.renderer, &rect);

      pos_x += CPU_COUNT_WIDTH + CPU_COUNT_SPACING;
    }

  } else {

    sdl.set_render_draw_color(render_manager.renderer, CPU_FILLED_COLOUR.r, CPU_FILLED_COLOUR.g, CPU_FILLED_COLOUR.b, CPU_FILLED_COLOUR.a);

    for i in 0..cpu_count{
      rect := sdl.Rect {
        pos_x, pos_y,
        i32(CPU_COUNT_WIDTH), i32(CPU_COUNT_HEIGHT)
      };

      sdl.render_fill_rect(render_manager.renderer, &rect);

      pos_x += CPU_COUNT_WIDTH + CPU_COUNT_SPACING;
    }

    sdl.set_render_draw_color(render_manager.renderer, CPU_UNFILLED_COLOUR.r, CPU_UNFILLED_COLOUR.g, CPU_UNFILLED_COLOUR.b, CPU_UNFILLED_COLOUR.a);

    for i in cpu_count+1..<cpu_total{
      rect := sdl.Rect {
        pos_x, pos_y,
        i32(CPU_COUNT_WIDTH), i32(CPU_COUNT_HEIGHT)
      };

      sdl.render_fill_rect(render_manager.renderer, &rect);

      pos_x += CPU_COUNT_WIDTH + CPU_COUNT_SPACING;
    }
  }
}

render_player_next_action :: proc(game_manager : ^GameManager) {
  using game_manager;

  switch input_manager.player_action_cache.action {
    case .None :
      // do nothing

    case .Move :
      pos := TILE_SIZE * player.pos - render_manager.camera_pos;
      pos += input_manager.player_action_cache.move_direction * TILE_SIZE;

      rect := sdl.Rect {
        i32(pos.x + 4), i32(pos.y + 4),
        i32(TILE_SIZE - 8), i32(TILE_SIZE - 8)
      };

      sdl.set_render_draw_color(render_manager.renderer, 255, 255, 255, 128);
      sdl.render_fill_rect(render_manager.renderer, &rect);

    case .UseScript:
      // @Todo(naum): HUD for script use

    case .PickFile:
      count := int(player.inventory_count);

      pos := Vec2i {
        INVENTORY_POS_X + count * (INVENTORY_FILE_WIDTH + INVENTORY_SPACING),
        INVENTORY_POS_Y
      };

      rect := sdl.Rect {
        i32(pos.x), i32(pos.y),
        i32(INVENTORY_FILE_WIDTH), i32(INVENTORY_FILE_HEIGHT)
      };

      sdl.set_render_draw_color(render_manager.renderer, 100, 255, 100, 255);
      sdl.render_fill_rect(render_manager.renderer, &rect);
  }
}

render_clock_debugger :: proc(game_manager : ^GameManager) {
  using game_manager;

  foreground_width := i32((CLOCK_DEBUGGER_WIDTH)*f32(clock_debugger.fill_percentage));

  foreground_rect := sdl.Rect {
    i32(clock_debugger.pivot.x + 2), i32(clock_debugger.pivot.y + 2),
    foreground_width, i32(TILE_SIZE-4)
  };

  background_rect := sdl.Rect {
    i32(clock_debugger.pivot.x + 2), i32(clock_debugger.pivot.y + 2),
    i32(CLOCK_DEBUGGER_WIDTH - 4), i32(TILE_SIZE - 4)
  };

  sdl.set_render_draw_color(render_manager.renderer, 20, 255, 255, 255);
  sdl.render_fill_rect(render_manager.renderer, &background_rect);
  sdl.set_render_draw_color(render_manager.renderer, 20, 40, 200, 126);
  sdl.render_fill_rect(render_manager.renderer, &foreground_rect);
}

render_inventory :: proc(game_manager: ^GameManager) {
  using game_manager;

  pos := Vec2i { INVENTORY_POS_X, INVENTORY_POS_Y };

  for i in 0..<player.inventory_count {
    rect := sdl.Rect {
      i32(pos.x), i32(pos.y),
      i32(INVENTORY_FILE_WIDTH), i32(INVENTORY_FILE_HEIGHT)
    };

    sdl.set_render_draw_color(render_manager.renderer, 196, 196, 196, 255);
    sdl.render_fill_rect(render_manager.renderer, &rect);

    pos.x += INVENTORY_FILE_WIDTH + INVENTORY_SPACING;
  }

  for i in player.inventory_count..<player.inventory_total {
    rect := sdl.Rect {
      i32(pos.x), i32(pos.y),
      i32(INVENTORY_FILE_WIDTH), i32(INVENTORY_FILE_HEIGHT)
    };

    sdl.set_render_draw_color(render_manager.renderer, 64, 64, 64, 255);
    sdl.render_fill_rect(render_manager.renderer, &rect);

    pos.x += INVENTORY_FILE_WIDTH + INVENTORY_SPACING;
  }
}

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
