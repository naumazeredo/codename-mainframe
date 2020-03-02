package mainframe

import "core:strings"
import "core:fmt"

import sdl "shared:odin-sdl2"
import sdl_ttf "shared:odin-sdl2/ttf"

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
      render_clock_debugger(game_manager);

      render_temp(game_manager);
  }

  sdl.render_present(render_manager.renderer);
}

render_terrain :: proc(game_manager : ^GameManager) {
  using game_manager;

  /*
  // XXX(naum): in case need to do terrain streaming
  for chunk in terrain.chunks {
    for i in 0..<TERRAIN_CHUNK_H {
      for j in 0..<TERRAIN_CHUNK_W {
        if chunk.tiles[i][j].type == TileType.None {
          continue;
        }

        tile_pos_y := i * TILE_SIZE + chunk.pos.y * TERRAIN_CHUNK_H;
        tile_pos_x := j * TILE_SIZE + chunk.pos.x * TERRAIN_CHUNK_W;

        tile_rect := sdl.Rect {
          i32(tile_pos_x + 1), i32(tile_pos_y + 1),
          i32(TILE_SIZE - 2), i32(TILE_SIZE - 2)
        };

        sdl.set_render_draw_color(renderer, 100, 100, 100, 255);
        sdl.render_fill_rect(renderer, &tile_rect);
      }
    }
  }
  */

  for i in 0..<TERRAIN_H {
    for j in 0..<TERRAIN_W {
      if terrain.tiles[i][j].type == TileType.None {
        continue;
      }

      tile_pos_y := i * TILE_SIZE - render_manager.camera_pos.y;
      tile_pos_x := j * TILE_SIZE - render_manager.camera_pos.x;

      tile_rect := sdl.Rect {
        i32(tile_pos_x + 1), i32(tile_pos_y + 1),
        i32(TILE_SIZE - 2), i32(TILE_SIZE - 2)
      };

      sdl.set_render_draw_color(render_manager.renderer, 100, 100, 100, 255);
      sdl.render_fill_rect(render_manager.renderer, &tile_rect);
    }
  }
}

render_player :: proc(game_manager : ^GameManager) {
  using game_manager;

  pos_y := player.pos.y * TILE_SIZE - render_manager.camera_pos.y;
  pos_x := player.pos.x * TILE_SIZE - render_manager.camera_pos.x;

  rect := sdl.Rect {
    i32(pos_x + 2), i32(pos_y + 2),
    i32(TILE_SIZE - 4), i32(TILE_SIZE - 4)
  };

  sdl.set_render_draw_color(render_manager.renderer, 20, 40, 200, 255);
  sdl.render_fill_rect(render_manager.renderer, &rect);
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

  if input_manager.can_act_on_tick {
    rect := sdl.Rect {
      i32(clock_debugger.pivot.x + CLOCK_DEBUGGER_WIDTH + 2), i32(clock_debugger.pivot.y + 2),
      i32(TILE_SIZE-4), i32(TILE_SIZE-4)
    };

    if input_manager.has_acted_on_tick {
      sdl.set_render_draw_color(render_manager.renderer, 255, 20, 20, 255);
    } else {
      sdl.set_render_draw_color(render_manager.renderer, 20, 255, 20, 255);
    }

    sdl.render_fill_rect(render_manager.renderer, &rect);
  }
}

render_temp :: proc(game_manager : ^GameManager) {
  using game_manager;

  if input_manager.is_player_action_next_tick {
    rect := sdl.Rect {
      i32(clock_debugger.pivot.x + CLOCK_DEBUGGER_WIDTH + TILE_SIZE + 2), i32(clock_debugger.pivot.y + 2),
      i32(TILE_SIZE-4), i32(TILE_SIZE-4)
    };

    sdl.set_render_draw_color(render_manager.renderer, 128, 128, 128, 255);

    sdl.render_fill_rect(render_manager.renderer, &rect);
  }

  if input_manager.is_player_action_tick {
    rect := sdl.Rect {
      i32(clock_debugger.pivot.x + CLOCK_DEBUGGER_WIDTH + 2 * TILE_SIZE + 2), i32(clock_debugger.pivot.y + 2),
      i32(TILE_SIZE-4), i32(TILE_SIZE-4)
    };

    sdl.set_render_draw_color(render_manager.renderer, 255, 255, 255, 255);

    sdl.render_fill_rect(render_manager.renderer, &rect);
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
