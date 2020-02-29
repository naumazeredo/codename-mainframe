package mainframe

import sdl "shared:odin-sdl2"

FRAMES_PER_SEC :: 60;
FRAME_DURATION_MS :: 1000.0 / FRAMES_PER_SEC;

_frame_time : u64 = 0;
cur_frame_duration : f64 = 0;

start_cap_frame :: proc() {
  _frame_time = sdl.get_performance_counter();
}

cap_frame :: proc() {
  new_frame_time := sdl.get_performance_counter();
  frame_duration : f64 = 1000.0 * f64(new_frame_time - _frame_time) / f64(sdl.get_performance_frequency());

  if frame_duration < FRAME_DURATION_MS {
    delay_duration : u32 = auto_cast (FRAME_DURATION_MS - cur_frame_duration);
    sdl.delay(delay_duration);
  }

  // FPS calculation
  new_frame_time = sdl.get_performance_counter();
  cur_frame_duration = 1.0 * f64(new_frame_time - _frame_time) / f64(sdl.get_performance_frequency());

  _frame_time = sdl.get_performance_counter();

  //add_fps_counter(renderer, font, cur_frame_duration, &text_pos, &text_h, &text_w);
}
