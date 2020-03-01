package mainframe

import "core:strings"
import "core:fmt"

import sdl "shared:odin-sdl2"
import sdl_ttf "shared:odin-sdl2/ttf"

// @Note(naum): remember Mac issue with screen size vs render size
render :: proc(game_manager : ^GameManager) {
  using game_manager;

  viewport_rect : sdl.Rect;

  // Clear viewport
  sdl.render_set_viewport(renderer, nil);
  sdl.set_render_draw_color(renderer, 0, 0, 0, 255);
  sdl.render_clear(renderer);

  // @Todo(naum): use game state state
  switch game_state {
    case .MainMenu :
      fmt.println("main menu!");
    case .Play :
      render_terrain(game_manager);
  }

  sdl.render_present(renderer);
}

render_terrain :: proc(game_manager : ^GameManager) {
  using game_manager;

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
