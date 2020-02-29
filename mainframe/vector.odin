package mainframe

Vec2 :: struct {
  x, y: f32
}

vec2_add :: proc(a, b: Vec2) -> Vec2 { return Vec2 { a.x + b.x, a.y + b.y }; }
vec2_sub :: proc(a, b: Vec2) -> Vec2 { return Vec2 { a.x - b.x, a.y - b.y }; }
vec2_mul :: proc(a: Vec2, f: f32) -> Vec2 { return Vec2 { a.x * f, a.y * f }; }
