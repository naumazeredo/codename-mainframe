package mainframe

import sdl "shared:odin-sdl2"
import sdl_ttf "shared:odin-sdl2/ttf"

import "core:mem"
import "core:strings"
import "core:fmt"

import "shared:io"

VIEW_W :: 1280;
VIEW_H :: 720;

main :: proc() {
  fmt.println("starting!");

  sdl.init(sdl.Init_Flags.Everything);
  defer sdl.quit();

  assert(sdl_ttf.init() != -1);

  game_state := create_game_state();
  defer delete_game_state(game_state);

  // -----------
  // Test Region
  // -----------

  // -----------
  // /Test Region
  // -----------

  start_cap_frame();

  for {
    running := handle_input(game_state);
    if !running {
      break;
    }

    render(game_state);

    cap_frame();

    // -------
    // Physics
    // -------

    // @Todo(naum): update in periodic intervals (interpolate/extrapolate on render)
    // update time
    //update_physics(physics_manager, entity_container, f32(cur_frame_duration));

    // -------
    // /Physics
    // -------
  }
}
