package mainframe

import "core:fmt"

import sdl "shared:odin-sdl2"
import sdl_ttf "shared:odin-sdl2/ttf"

FRAMES_PER_SEC :: 60;
FRAME_DURATION :: 1.0 / FRAMES_PER_SEC;

CLOCK_TICK :: 0.3333;

// @Todo(naum): create GameStateEnum to know if the game is in menu, in-game, etc
GameState :: enum {
  MainMenu,
  Play,
  GameOver,
  Win,
}

// @Todo(naum): don't use so many pointers (?)
GameManager :: struct {
  frame_count         : u32,

  real_time           : f64,
  real_frame_duration : f64,

  game_time           : f64,
  game_time_scale     : f64,
  game_frame_duration : f64,

  clock_ticks : u32,
  last_game_time_clock_tick : f64,

  floor_current : u8,
  floor_total   : u8,

  game_state : GameState,

  input_manager  : InputManager,
  render_manager : RenderManager,

  terrain : Terrain,
  player  : Player,
  enemy_container : EnemyContainer,

  clock_debugger : ClockDebugger
}

initialize_game_manager :: proc(game_manager: ^GameManager){
  using game_manager;

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

  game_state = .MainMenu;

  create_input_manager(&input_manager);
  create_render_manager(&render_manager);

  floor_current = 1;
  floor_total   = 3;
}

create_game_manager :: proc() -> ^GameManager {
  game_manager := new(GameManager);
  using game_manager;

  initialize_game_manager(game_manager);

  // ------
  // Player
  // ------

  create_player(&player);

  return game_manager;
}

destroy_game_manager :: proc(game_manager: ^GameManager) {
  using game_manager;
  destroy_render_manager(&render_manager);
  free(game_manager);
}

start_new_frame :: proc(game_manager: ^GameManager) {
  using game_manager;

  _cap_framerate(game_manager);
  clock_debugger.fill_percentage = f32((game_time - last_game_time_clock_tick) / CLOCK_TICK);

  frame_count += 1;

  real_frame_duration = _get_current_time() - real_time;
  real_time += real_frame_duration;

  // Game play logic
  if game_state == .Play {
    game_frame_duration = game_time_scale * real_frame_duration;
    game_time += game_frame_duration;

    for game_time - last_game_time_clock_tick >= CLOCK_TICK {
      clock_ticks += 1;
      last_game_time_clock_tick += CLOCK_TICK;

      clock_debugger.fill_percentage = 0;

      update_terrain_clock_tick(game_manager);
      update_player_clock_tick(game_manager);

      for i in 0..<enemy_container.count {
        update_enemy_clock_tick(i, game_manager);
      }

      check_for_player_damage(game_manager);

      terrain_update_player_vision(game_manager);
    }
  }
}

generate_terrain :: proc(game_manager: ^GameManager) {
  using game_manager;

  create_terrain(game_manager);
  //create_boss_test_terrain(game_manager);
  //create_test_terrain(game_manager);
}

check_for_player_damage :: proc(game_manager: ^GameManager) {
  using game_manager;

  has_taken_damage := false;

  for i in 0..<enemy_container.count {
    if enemy_container.pos[i] == player.pos &&
       enemy_container.state[i] != .Timeout {
      has_taken_damage = true;
      enemy_timeout(i, game_manager);
    }
  }

  if has_taken_damage {
    player_take_damage(game_manager);
  }
}

complete_floor :: proc(game_manager: ^GameManager) {
  using game_manager;

  if floor_current == floor_total {
    game_state = .Win;
  } else {
    floor_current += 1;
    generate_terrain(game_manager);
  }
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

// @DeleteMe(naum): temporary test function
temp_reset_game_manager :: proc(game_manager: ^GameManager) {
  using game_manager;

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

  game_state = .Play;

  // ------
  // Player
  // ------

  create_player(&player);

  generate_terrain(game_manager);

  terrain.button_sequence_index = 0;
}
