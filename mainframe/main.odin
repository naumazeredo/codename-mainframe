package mainframe

import sdl "shared:odin-sdl2"
import sdl_ttf "shared:odin-sdl2/ttf"

import "core:mem"
import "core:strings"
import "core:fmt"

VIEW_W :: 1280;
VIEW_H :: 720;

main :: proc() {
  sdl.init(sdl.Init_Flags.Everything);
  defer sdl.quit();

  assert(sdl_ttf.init() != -1);

  game_manager := create_game_manager();
  defer destroy_game_manager(game_manager);

  // -----------
  // Test Region
  // -----------

  generate_terrain(game_manager);

  // -----------
  // /Test Region
  // -----------

  // This avoids player acting on the overtime of first frame
  // @Note(naum): move this to the proper place in case we have a menu + gameplay
  game_manager.input_manager.has_acted_on_tick = true;

  for {
    start_new_frame(game_manager);

    // @Todo(naum): (don't return?) use a GameManager field instead of returning?
    running := handle_input(game_manager);
    if !running {
      break;
    }

    render(game_manager);

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
