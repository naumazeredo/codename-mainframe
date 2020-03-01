package mainframe

import "core:mem"
import "core:fmt"

import sdl "shared:odin-sdl2"

InputManager :: struct {
  player_left  : sdl.Scancode,
  player_right : sdl.Scancode,
  player_jump  : sdl.Scancode,

  keystate : ^u8,
}

new_input_manager :: proc() -> ^InputManager {
  input_manager := new(InputManager);

  input_manager.player_left  = sdl.Scancode.A;
  input_manager.player_right = sdl.Scancode.D;
  input_manager.player_jump  = sdl.Scancode.Space;

  input_manager.keystate = sdl.get_keyboard_state(nil);

  return input_manager;
}

// @Todo(naum): handle key inputs properly (key up, key down, key pressed)
// @Note(naum): sdl.poll_event must be in same thread that set video mode
handle_input :: proc(game_manager : ^GameManager) -> bool {
  e: sdl.Event;
  for sdl.poll_event(&e) != 0 {
    if e.type == sdl.Event_Type.Quit {
      // @Todo(naum): change game state
      return false;
    }

    // @Todo(naum): remove this, only for testing
    if e.type == sdl.Event_Type.Key_Down {
      if e.key.keysym.sym == sdl.SDLK_ESCAPE {
        // @Todo(naum): change game state
        return false;
      }

      /*
      if e.key.keysym.sym == i32(sdl.SDLK_UP) {
        game_manager.game_time_scale += 0.01;
        fmt.printf("game_time_scale %f\n", game_manager.game_time_scale);
      }

      if e.key.keysym.sym == i32(sdl.SDLK_DOWN) {
        game_manager.game_time_scale -= 0.01;
        fmt.printf("game_time_scale %f\n", game_manager.game_time_scale);
      }
      */
    }
  }

  return true;
}

_is_key_pressed :: proc(keystate: ^u8, code: sdl.Scancode) -> bool {
  return mem.ptr_offset(keystate, int(code))^ != 0;
}
