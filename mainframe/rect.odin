package mainframe

import sdl "shared:odin-sdl2"

Rect :: struct {
  x, y, w, h : f32
}

rect_to_sdlrect :: proc(r: Rect) -> sdl.Rect {
  return sdl.Rect { i32(r.x), i32(r.y), i32(r.w), i32(r.h) };
}

Recti :: struct {
  x, y, w, h : int
}
