package mainframe

import "core:fmt"

import sdl "shared:odin-sdl2"
import sdl_ttf "shared:odin-sdl2/ttf"

FRAMES_PER_SEC :: 60;
FRAME_DURATION :: 1.0 / FRAMES_PER_SEC;

CLOCK_TICK :: 0.25;

// @Todo(naum): create GameStateEnum to know if the game is in menu, in-game, etc

// @Todo(naum): don't use so many pointers (?)
GameState :: struct {
  frame_count         : u32,

  real_time           : f64,
  real_frame_duration : f64,

  game_time           : f64,
  game_time_scale     : f64,
  game_frame_duration : f64,

  clock_ticks : u32,
  last_game_time_clock_tick : f64,

  font     : ^sdl_ttf.Font,
  window   : ^sdl.Window,
  renderer : ^sdl.Renderer,

  input_manager : ^InputManager,
}

create_game_state :: proc() -> ^GameState {
  game_state := new(GameState);
  using game_state;

  // -----
  // Time / Frame
  // -----

  frame_count = 0;

  real_time = _get_current_time();
  real_frame_duration = 1;

  game_time           = 0;
  game_time_scale     = 1;
  game_frame_duration = 1;

  // -----
  // Clock
  // -----

  clock_ticks = 0;
  last_game_time_clock_tick = 0;

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

  // -------
  // Systems
  // -------

  input_manager = new_input_manager();

  // -------
  // /Systems
  // -------

  // -------
  // Startup prints
  // -------

  w, h : i32;
  sdl.get_window_size(window, &w, &h);

  w_render, h_render : i32;
  sdl.get_renderer_output_size(renderer, &w_render, &h_render);

  fmt.printf("screen size: (%d, %d)\n", w, h);
  fmt.printf("render size: (%d, %d)\n", w_render, h_render);

  // -------
  // /Startup prints
  // -------

  return game_state;
}

delete_game_state :: proc(game_state: ^GameState) {
  using game_state;
  sdl.destroy_window(window);
  sdl.destroy_renderer(renderer);
  free(input_manager);
  free(game_state);
}

start_new_frame :: proc(game_state: ^GameState) {
  using game_state;

  _cap_framerate(game_state);

  frame_count += 1;

  real_frame_duration = _get_current_time() - real_time;
  real_time += real_frame_duration;

  game_frame_duration = game_time_scale * real_frame_duration;
  game_time += game_frame_duration;

  // @Todo(naum): only do this in gameplay
  for game_time - last_game_time_clock_tick >= CLOCK_TICK {
    clock_ticks += 1;

    // Call update for anything that requires clock tick
    fmt.printf("clock tick %d\n", clock_ticks);

    last_game_time_clock_tick += CLOCK_TICK;
  }
}

_cap_framerate :: proc(game_state: ^GameState) {
  using game_state;

  frame_duration := _get_current_time() - real_time;

  // @Todo(naum): compare floats properly
  if frame_duration < FRAME_DURATION {
    delay_duration : u32 = auto_cast (1000.0 * (FRAME_DURATION - frame_duration));
    sdl.delay(delay_duration);
  }

  //add_fps_counter(renderer, font, cur_frame_duration, &text_pos, &text_h, &text_w);
}

// @Todo(naum): move to util.odin (?)
_get_current_time :: proc() -> f64 {
  return f64(sdl.get_performance_counter()) / f64(sdl.get_performance_frequency());
}
