package mainframe

import sdl "shared:odin-sdl2"
import sdl_ttf "shared:odin-sdl2/ttf"

import "shared:io"

// @Todo(naum): create GameStateEnum to know if the game is in menu, in-game, etc

// @Todo(naum): don't use so many pointers (?)
GameState :: struct {
  font     : ^sdl_ttf.Font,
  window   : ^sdl.Window,
  renderer : ^sdl.Renderer,

  input_manager : ^InputManager,
}

create_game_state :: proc() -> ^GameState {
  game_state := new(GameState);

  game_state.font = sdl_ttf.open_font("arial.ttf", 40);
  assert(game_state.font != nil);
  io.print("loaded font!\n");

  game_state.window = sdl.create_window(
    "Codename Rogue",
    i32(sdl.Window_Pos.Undefined),
    i32(sdl.Window_Pos.Undefined),
    VIEW_W, VIEW_H,
    sdl.Window_Flags.Allow_High_DPI
  );
  assert(game_state.window != nil);

  game_state.renderer = sdl.create_renderer(
    game_state.window,
    -1,
    sdl.Renderer_Flags(0)
  );
  assert(game_state.renderer != nil);

  // -------
  // Systems
  // -------

  game_state.input_manager = new_input_manager();

  // -------
  // /Systems
  // -------

  // -------
  // Startup prints
  // -------

  w, h : i32;
  sdl.get_window_size(game_state.window, &w, &h);

  w_render, h_render : i32;
  sdl.get_renderer_output_size(game_state.renderer, &w_render, &h_render);

  io.print("[screen size]: (%, %)\n", w, h);
  io.print("[render size]: (%, %)\n", w_render, h_render);

  // -------
  // /Startup prints
  // -------

  return game_state;
}

delete_game_state :: proc(game_state: ^GameState) {
  sdl.destroy_window(game_state.window);
  sdl.destroy_renderer(game_state.renderer);
  free(game_state.input_manager);
  free(game_state);
}
