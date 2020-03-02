package mainframe

import "core:mem"
import "core:fmt"

import sdl "shared:odin-sdl2"

InputManager :: struct {
  player_left   : sdl.Scancode,
  player_right  : sdl.Scancode,
  player_up     : sdl.Scancode,
  player_down   : sdl.Scancode,
  player_script : sdl.Scancode,
  player_pick   : sdl.Scancode,

  has_acted_on_tick : bool,
  can_act_on_tick   : bool,

  is_player_action_next_tick : bool,
  is_player_action_tick      : bool,

  keystate : ^u8,
}

create_input_manager :: proc(input_manager: ^InputManager) {
  using input_manager;

  player_left   = sdl.Scancode.A;
  player_right  = sdl.Scancode.D;
  player_up     = sdl.Scancode.W;
  player_down   = sdl.Scancode.S;
  player_script = sdl.Scancode.Space;
  player_pick   = sdl.Scancode.E;

  has_acted_on_tick = false; // @Todo(naum): add player_ or something that tells it's player related
  can_act_on_tick   = false; // @Todo(naum): change to some name more suggestive (related to the time frame of action)

  is_player_action_next_tick = false;
  is_player_action_tick      = false;

  keystate = sdl.get_keyboard_state(nil);
}

// @Todo(naum): handle key inputs properly (key up, key down, key pressed)
// @Note(naum): sdl.poll_event must be in same thread that set video mode
handle_input :: proc(game_manager : ^GameManager) -> bool {
  using game_manager;

  e : sdl.Event = ---;
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

      if e.key.keysym.sym == sdl.SDLK_r {
        temp_reset_game_manager(game_manager);
      }

      if game_state == GameState.Play {
        // Player movement
        if input_manager.can_act_on_tick &&
           !input_manager.has_acted_on_tick &&
           input_manager.is_player_action_tick {

          // @XXX(naum): maybe just has_acted_on_tick = handle_player_input(..)?
          if handle_player_input(e, game_manager) {
            input_manager.has_acted_on_tick = true;
          }
        }

        // ----
        // Test time scale
        // ----

        if e.key.keysym.sym == i32(sdl.SDLK_j) {
          game_manager.game_time_scale += 0.05;
          fmt.printf("game_time_scale %f\n", game_manager.game_time_scale);
        }

        if e.key.keysym.sym == i32(sdl.SDLK_k) {
          game_manager.game_time_scale -= 0.05;
          fmt.printf("game_time_scale %f\n", game_manager.game_time_scale);
        }

        // ----
        // /Test
        // ----
      }
    }
  }

  return true;
}

handle_player_input :: proc(e: sdl.Event, game_manager: ^GameManager) -> bool {
  using game_manager;

  delta_pos := Vec2i { 0, 0 };

  if _is_scancode_pressed(e, input_manager.player_left)  { return move_player({ -1,  0 }, game_manager); }
  if _is_scancode_pressed(e, input_manager.player_right) { return move_player({ +1,  0 }, game_manager); }
  if _is_scancode_pressed(e, input_manager.player_up)    { return move_player({  0, -1 }, game_manager); }
  if _is_scancode_pressed(e, input_manager.player_down)  { return move_player({  0, +1 }, game_manager); }

  if _is_scancode_pressed(e, input_manager.player_pick)  { return pick_file(game_manager); }

  return false;
}

_is_key_pressed :: proc(keystate: ^u8, code: sdl.Scancode) -> bool {
  return mem.ptr_offset(keystate, int(code))^ != 0;
}

_is_scancode_pressed :: proc(e: sdl.Event, code: sdl.Scancode) -> bool {
  return e.key.keysym.scancode == code;
}
