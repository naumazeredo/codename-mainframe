package mainframe

import "core:fmt"

import sdl "shared:odin-sdl2"
import sdl_ttf "shared:odin-sdl2/ttf"

FRAMES_PER_SEC :: 60;
FRAME_DURATION :: 1.0 / FRAMES_PER_SEC;

CLOCK_TICK :: 1;
ACTION_THRESHOLD :: 0.2; // actions will hold within the margin of (tick + dt) and (tick - dt) and this is the dt

// @Todo(naum): create GameStateEnum to know if the game is in menu, in-game, etc
GameState :: enum {
  MainMenu,
  Play,
}

// @Todo(naum): don't use so many pointers (?)
GameManager :: struct {
  font     : ^sdl_ttf.Font,
  window   : ^sdl.Window,
  renderer : ^sdl.Renderer,

  frame_count         : u32,

  real_time           : f64,
  real_frame_duration : f64,

  game_time           : f64,
  game_time_scale     : f64,
  game_frame_duration : f64,

  clock_ticks : u32,
  last_game_time_clock_tick : f64,

  game_state : GameState,

  input_manager : InputManager,

  terrain : Terrain,
  player  : Player,

  clock_debugger : ClockDebugger
}

create_game_manager :: proc() -> ^GameManager {
  game_manager := new(GameManager);
  using game_manager;

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

  // -------
  // Systems
  // -------

  game_state = GameState.Play;

  create_input_manager(&input_manager);

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

  return game_manager;
}

delete_game_manager :: proc(game_manager: ^GameManager) {
  using game_manager;
  sdl.destroy_window(window);
  sdl.destroy_renderer(renderer);
  free(game_manager);
}

start_new_frame :: proc(game_manager: ^GameManager) {
  using game_manager;

  _cap_framerate(game_manager);
  clock_debugger.fill_percentage = f32((game_time - last_game_time_clock_tick) / CLOCK_TICK);

  frame_count += 1;

  real_frame_duration = _get_current_time() - real_time;
  real_time += real_frame_duration;

  game_frame_duration = game_time_scale * real_frame_duration;
  game_time += game_frame_duration;

  // @Todo(naum): only do this in gameplay

  input_manager.can_act_on_tick = game_time - last_game_time_clock_tick <= ACTION_THRESHOLD ||
                                  game_time - last_game_time_clock_tick >= CLOCK_TICK - ACTION_THRESHOLD;

  for game_time - last_game_time_clock_tick >= CLOCK_TICK {
    clock_ticks += 1;

    clock_debugger.fill_percentage = 0;

    // Call update for anything that requires clock tick
    //fmt.printf("clock tick %d\n", clock_ticks);

    last_game_time_clock_tick += CLOCK_TICK;
  }

  if game_time - last_game_time_clock_tick > ACTION_THRESHOLD &&
     game_time - last_game_time_clock_tick < CLOCK_TICK - ACTION_THRESHOLD {

    input_manager.has_acted_on_tick = false;
  }
}

generate_terrain :: proc(game_manager: ^GameManager) {
  using game_manager;

  create_terrain(&terrain);
  player.pos = terrain.enter;
  clock_debugger.pivot = terrain.debugger_top;
}

_cap_framerate :: proc(game_manager: ^GameManager) {
  using game_manager;

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
