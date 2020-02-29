package mainframe

import "core:strings"

import sdl "shared:odin-sdl2"
import sdl_ttf "shared:odin-sdl2/ttf"

// @Note(naum): remember Mac issue with screen size vs render size
render :: proc(game_state : ^GameState) {
  renderer := game_state.renderer;

  viewport_rect : sdl.Rect;

  // Clear viewport
  sdl.render_set_viewport(renderer, nil);
  sdl.set_render_draw_color(renderer, 0, 0, 0, 255);
  sdl.render_clear(renderer);

  render_terrain(renderer);

  /*
  // Render player
  for _, i in entity_container.players {
    player := &entity_container.players[i];
    mirror_player_rendering(renderer, player);
  }
  */

  sdl.render_present(renderer);
}

render_terrain :: proc(renderer: ^sdl.Renderer) {
  for i in 0..<TERRAIN_H {
    for j in 0..<TERRAIN_W {
      if i != 0 && i != TERRAIN_H-1 && j != 0 && j != TERRAIN_W-1 {
        continue;
      }

      tile_pos_x := j * TILE_SIZE;
      tile_pos_y := i * TILE_SIZE;

      tile_rect := sdl.Rect {
        i32(tile_pos_x), i32(tile_pos_y),
        i32(TILE_SIZE), i32(TILE_SIZE)
      };

      sdl.set_render_draw_color(renderer, 100, 100, 100, 255);
      sdl.render_fill_rect(renderer, &tile_rect);
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
