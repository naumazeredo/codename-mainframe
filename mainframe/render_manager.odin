package mainframe

import "core:strings"
import "core:fmt"

import sdl "shared:odin-sdl2"
import sdl_ttf "shared:odin-sdl2/ttf"
import sdl_image "shared:odin-sdl2/image"

TILE_SIZE   :: Vec2i { 32, 24 };

TEXTURE_TOTAL :: 32;

CPU_COUNT_WIDTH     :: 8;
CPU_COUNT_HEIGHT    :: 10;
CPU_COUNT_SPACING   :: 2;
CPU_COUNT_OFFSET_Y  :: -2;
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

  // Textures
  textures      : [TEXTURE_TOTAL]^sdl.Texture,
  texture_sizes : [TEXTURE_TOTAL]Vec2i,

  camera_pos : Vec2i,
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

  font = sdl_ttf.open_font("arial.ttf", 80);
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

  //
  _load_textures(render_manager);
}

destroy_render_manager :: proc(render_manager: ^RenderManager) {
  using render_manager;
  sdl.destroy_window(window);
  sdl.destroy_renderer(renderer);
}

_load_texture :: proc(index: u8, path: cstring, render_manager: ^RenderManager) {
  using render_manager;

  textures[index] = sdl_image.load_texture(renderer, path);
  if textures[index] == nil {
    fmt.printf("[error] Couldn't load texture: %s\n", path);
    // @Todo(naum): load default texture
    return;
  }

  w, h : i32;
  sdl.query_texture(textures[index], nil, nil, &w, &h);
  texture_sizes[index] = { int(w), int(h) };
}

_load_textures :: proc(render_manager: ^RenderManager) {
  using render_manager;

  // @Todo(naum): create enum to map textures to a better thing than a hardcoded number
  _load_texture(0, "assets/virusy.png", render_manager);
  _load_texture(1, "assets/guardy.png", render_manager);
  _load_texture(2, "assets/tile-32-24.png", render_manager);
  _load_texture(3, "assets/tile-32-24-dark.png", render_manager);
  _load_texture(4, "assets/file.png", render_manager);

  _load_texture(5, "assets/button-square.png", render_manager);
  _load_texture(6, "assets/button-circle.png", render_manager);
  _load_texture(7, "assets/button-triangle.png", render_manager);

  _load_texture(8, "assets/button-square-pressed.png", render_manager);
  _load_texture(9, "assets/button-circle-pressed.png", render_manager);
  _load_texture(10, "assets/button-triangle-pressed.png", render_manager);

  _load_texture(11, "assets/terminal.png", render_manager);
  _load_texture(12, "assets/alert-symbol.png", render_manager);
  _load_texture(13, "assets/fatty.png", render_manager);
}

// @Note(naum): remember Mac issue with screen size vs render size
render :: proc(game_manager : ^GameManager) { // @Refactor(luciano): function could receive only render_manager
  using game_manager;

  render_manager.camera_pos = player.pos * TILE_SIZE + TILE_SIZE / 2 - { VIEW_W / 2, VIEW_H / 2 };

  viewport_rect : sdl.Rect;

  // Clear viewport
  sdl.render_set_viewport(render_manager.renderer, nil);
  sdl.set_render_draw_color(render_manager.renderer, 0, 0, 0, 255);
  sdl.render_clear(render_manager.renderer);

  // @Todo(naum): use game state state
  switch game_state {
    case .MainMenu :
      render_main_menu(&render_manager);
    case .Play :
      render_player_vision(game_manager);
      render_terrain(game_manager);
      render_scan(game_manager);
      render_player_next_action(game_manager);

      render_units(game_manager);

      // HUD
      render_clock_debugger(game_manager);
      render_inventory(game_manager);
      render_cpu_counts(game_manager);
      render_floor_hud(game_manager);
    case .GameOver:
      render_player_vision(game_manager);
      render_terrain(game_manager);
      render_units(game_manager);

      render_clock_debugger(game_manager);
      render_inventory(game_manager);
      render_game_over(&render_manager);
  }

  sdl.render_present(render_manager.renderer);
}

NULL_COLOR_MOD :: Color { 255, 255, 255, 255 };
render_terrain :: proc(game_manager : ^GameManager) {
  using game_manager;

  for i in 0..<TERRAIN_H {
    for j in 0..<TERRAIN_W {
      if terrain.is_tile_hidden[i][j] {
        continue;
      }

      if terrain.tile_type[i][j] == .None {
        if !terrain.is_tile_visible[i][j] {
          _render_color_on_tile_top({ j, i }, { 4, 4, 4, 255}, 0, game_manager);
        }
        continue;
      }

      pos := Vec2i{ j, i } * TILE_SIZE - render_manager.camera_pos;
      texture_id : u8 = 2;
      color_mod := NULL_COLOR_MOD;

      if terrain.is_tile_visible[i][j] {
        #partial switch terrain.tile_type[i][j] {
          case .Ground         : texture_id = 2;
          case .Entrance       : texture_id = 2;
          case .Square         : texture_id = is_button_pressed({j, i}, game_manager) ? 8 : 5;
          case .Circle         : texture_id = is_button_pressed({j, i}, game_manager) ? 9 : 6;
          case .Triangle       : texture_id = is_button_pressed({j, i}, game_manager) ? 10 : 7;
          case .SquareSymbol   : texture_id = is_button_pressed({j, i}, game_manager) ? 8 : 5;
          case .CircleSymbol   : texture_id = is_button_pressed({j, i}, game_manager) ? 9 : 6;
          case .TriangleSymbol : texture_id = is_button_pressed({j, i}, game_manager) ? 10 : 7;
          case .Terminal       : handle_render_terminal(game_manager, pos); continue;
        }
      } else {
        texture_id = 2;
        color_mod = Color { 64, 64, 64, 255 };
      }

      _render_texture(pos, texture_id, color_mod, game_manager);
    }
  }
}

handle_render_terminal :: proc(game_manager : ^GameManager, pos : Vec2i) {
  using game_manager;
  color_mod := NULL_COLOR_MOD;

  _render_texture(pos, 2, color_mod, game_manager);
  _render_texture(pos, 11, color_mod, game_manager);
}

render_player_vision :: proc(game_manager : ^GameManager) {
  using game_manager;

  VISION_COLOR :: Color { 12, 12, 12, 255};

  for i in 0..<TERRAIN_H {
    for j in 0..<TERRAIN_W {
      if terrain.tile_type[i][j] != .None || !terrain.is_tile_visible[i][j] {
        continue;
      }

      _render_color_on_tile_top({ j, i }, VISION_COLOR, 0, game_manager);
    }
  }
}

render_scan :: proc(game_manager : ^GameManager) {
  using game_manager;

  SCAN_COLOR :: Color {100, 255, 100, 128};

  for i in 0..<TERRAIN_H {
    for j in 0..<TERRAIN_W {
      if !terrain.is_tile_being_scanned[i][j] ||
         !terrain.is_tile_visible[i][j] {
        continue;
      }

      _render_color_on_tile_top({ j, i }, SCAN_COLOR, 1, game_manager);
    }
  }
}

render_units :: proc(game_manager : ^GameManager) {
  using game_manager;

  for i in 0..<TERRAIN_H {
    for j in 0..<TERRAIN_W {
      if !terrain.is_tile_visible[i][j] { continue; }

      pos := Vec2i { j, i };

      if terrain.has_file[i][j] { _render_unit(pos, 4, WHITE, game_manager); }
      if player.pos == pos      { _render_unit(pos, 0, WHITE, game_manager); }

      // @MaybeFix(naum): not the best way to do it, but simple to do it right now
      for i in 0..<enemy_container.count {
        if enemy_container.pos[i] == pos {

          color_mod := Color { 255, 255, 255, 255 };

          #partial switch enemy_container.state[i] {
            case .Timeout   : color_mod = {100, 100, 255, 255};
          }
          texture_id := texture_id_from_enemy_type(enemy_container.type[i]);

          _render_unit(pos, texture_id, color_mod, game_manager);

          if enemy_container.state[i] == .Alert || enemy_container.state[i] == .AlertScan {
            _render_above_unit(pos, 12, WHITE, 1, game_manager);
          }
        }
      }
    }
  }
}

//@Refactor: handle this better
texture_id_from_enemy_type :: proc(enemy_type : EnemyType) -> u8 {
  if enemy_type == EnemyType.BackAndForth { return 1; }
  if enemy_type == EnemyType.Circle3x3 { return 13; }
  return 0;
}

// -----
//  HUD
// -----

render_cpu_counts :: proc(game_manager: ^GameManager) {
  using game_manager;
  pos : Vec2i;

  // Player CPU count
  pos = TILE_SIZE * player.pos - render_manager.camera_pos;
  pos += TILE_SIZE / 2;
  pos -= { render_manager.texture_sizes[0].x / 2, render_manager.texture_sizes[0].y };

  render_cpu_count(
    player.cpu_count, player.cpu_total,
    pos,
    game_manager
  );

  // Enemies CPU counts
  for i in 0..<enemy_container.count {
    enemy_pos := enemy_container.pos[i];
    if !terrain.is_tile_visible[enemy_pos.y][enemy_pos.x] { continue; }

    pos = TILE_SIZE * enemy_container.pos[i] - render_manager.camera_pos;
    pos += TILE_SIZE / 2;
    pos -= { render_manager.texture_sizes[1].x / 2, render_manager.texture_sizes[1].y };

    type := int(enemy_container.type[i]);
    render_cpu_count(
      enemy_container.cpu_count[i], enemy_container.cpu_total[i],
      pos,
      game_manager
    );
  }
}

render_cpu_count:: proc(cpu_count, cpu_total: u8, pivot : Vec2i, game_manager: ^GameManager) {
  using game_manager;

  total_width := int(cpu_total) * CPU_COUNT_WIDTH + (int(cpu_total)-1) * CPU_COUNT_SPACING;

  pos_x := i32(pivot.x - total_width / 2 + TILE_SIZE.x / 2);
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
        i32(TILE_SIZE.x - 8), i32(TILE_SIZE.y - 8)
      };

      sdl.set_render_draw_color(render_manager.renderer, 255, 255, 255, 128);
      sdl.render_fill_rect(render_manager.renderer, &rect);

    case .UseScript:
      // @Todo(naum): HUD for script use

    case .Action:
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
    foreground_width, i32(TILE_SIZE.y-4)
  };

  background_rect := sdl.Rect {
    i32(clock_debugger.pivot.x + 2), i32(clock_debugger.pivot.y + 2),
    i32(CLOCK_DEBUGGER_WIDTH - 4), i32(TILE_SIZE.y - 4)
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

render_game_over :: proc(render_manager : ^RenderManager) {
  using render_manager;

  w_render, h_render : i32;
  sdl.get_renderer_output_size(renderer, &w_render, &h_render);

  w := int(w_render);
  h := int(h_render);

  pos_upper := Vec2i {w/2, h/2 - 40};
  pos_lower := Vec2i {w/2, h/2 + 60};
  color := sdl.Color{255,255,255,200};

  _render_text(render_manager, "game over", color, pos_upper, 50);
  _render_text(render_manager, "press r to restart", color, pos_lower, 50);
}

render_main_menu :: proc(render_manager : ^RenderManager) {
  using render_manager;

  w_render, h_render : i32;
  sdl.get_renderer_output_size(renderer, &w_render, &h_render);

  w := int(w_render);
  h := int(h_render);

  pos_upper := Vec2i {w/2, h/2 - 110};
  pos_mid   := Vec2i {w/2, h/2 - 25};
  pos_lower := Vec2i {w/2, h/2 + 60};
  color := sdl.Color{255,255,255,255};

  _render_text(render_manager, "mainframe - hacker adventures", color, pos_upper, 50);
  _render_text(render_manager, "press any key to start", color, pos_mid, 50);
  _render_text(render_manager, "movement: w,a,s,d ; action :e ", color, pos_lower, 50);
}

render_floor_hud :: proc(game_manager: ^GameManager) {
  using game_manager;

  w_render, h_render : i32;
  sdl.get_renderer_output_size(render_manager.renderer, &w_render, &h_render);
  w := int(w_render);
  h := int(h_render);

  pos := Vec2i {w/2, VIEW_H - 50};
  color := sdl.Color{255,255,255,200};

  builder := strings.make_builder();
  defer strings.destroy_builder(&builder);

  strings.write_string(&builder, "floor ");
  strings.write_uint(&builder, uint(floor_current));
  strings.write_string(&builder, " / ");
  strings.write_uint(&builder, uint(floor_total));

  str := strings.clone_to_cstring(strings.to_string(builder));
  _render_text(&render_manager, str, color, pos, 25);
}


//_render_text :: proc (render_manager : ^RenderManager, text : cstring, color : sdl.Color, pos : ^sdl.Rect) {
_render_text :: proc (render_manager : ^RenderManager, text : cstring, color : sdl.Color, pos_mid_bot: Vec2i, h: int) {
  using render_manager;

  text_surface := sdl_ttf.render_utf8_solid(render_manager.font, text, color);

  w := int(text_surface.w) * h / int(text_surface.h);

  text_texture := sdl.create_texture_from_surface(renderer, text_surface);
  sdl.free_surface(text_surface);

  rect := sdl.Rect {
    i32(pos_mid_bot.x - w/2),
    i32(pos_mid_bot.y - h),
    i32(w), i32(h)
  };

  sdl.render_copy(renderer,text_texture, nil, &rect);
}


// -----------------
// Utility functions
// -----------------

_render_color_on_tile_top :: proc(pos: Vec2i, color: Color, border: int, game_manager: ^GameManager) {
  using game_manager;
  render_pos := pos * TILE_SIZE - render_manager.camera_pos;

  rect := sdl.Rect {
    i32(render_pos.x + border), i32(render_pos.y + border),
    i32(TILE_SIZE.x - 2 * border), i32(TILE_SIZE.y - 2 * border)
  };

  sdl.set_render_draw_color(render_manager.renderer, color.r, color.g, color.b, color.a);
  sdl.render_fill_rect(render_manager.renderer, &rect);
}

_render_texture :: proc(pos: Vec2i, texture_id: u8, color_mod: Color, game_manager: ^GameManager) {
  using game_manager;

  rect := sdl.Rect {
    i32(pos.x), i32(pos.y),
    i32(render_manager.texture_sizes[texture_id].x),
    i32(render_manager.texture_sizes[texture_id].y),
  };

  sdl.set_texture_color_mod(
    render_manager.textures[texture_id],
    color_mod.r, color_mod.g, color_mod.b
  );

  sdl.render_copy(
    render_manager.renderer,
    render_manager.textures[texture_id],
    nil,
    &rect
  );
}

_render_unit :: proc(pos: Vec2i, texture_id: u8, color_mod: Color, game_manager: ^GameManager) {
  using game_manager;

  render_pos := pos * TILE_SIZE - render_manager.camera_pos;
  render_pos += TILE_SIZE / 2;
  render_pos -= { render_manager.texture_sizes[texture_id].x / 2, render_manager.texture_sizes[texture_id].y };

  _render_texture(render_pos, texture_id, color_mod, game_manager);
}

_render_above_unit :: proc(pos: Vec2i, texture_id: u8, color_mod: Color, unit_texture_id: u8, game_manager: ^GameManager) {
  using game_manager;

  render_pos := pos * TILE_SIZE - render_manager.camera_pos;
  render_pos += TILE_SIZE / 2;
  render_pos -= {
    render_manager.texture_sizes[texture_id].x / 2,
    render_manager.texture_sizes[texture_id].y + render_manager.texture_sizes[unit_texture_id].y + 16
  };

  _render_texture(render_pos, texture_id, color_mod, game_manager);
}
