package mainframe

/*
// @WTF(naum): Odin issue? can't use more than one update after for?
for i, p := 0, 0 ;
    i < player.inventory_count-1 ;
    i += 1, p += 1 {
*/

/*
// @WTF(naum): Odin issue? No way to reuse ConditionType to not type the whole proc stuff everytime?
ConditionType :: proc(start: Vec2i, pos: Vec2i, dist: int, terrain: ^Terrain) -> bool;
is_tile_walkable_condition :: proc(start: Vec2i, pos: Vec2i, dist: int, terrain: ^Terrain) -> bool {
  return is_tile_walkable(pos, terrain) && pos != start;
}
*/

/*
can't iterate on constant arrays/slices
*/
