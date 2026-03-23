///|
pub struct Position {
  x : Int
  y : Int
} derive(Eq, ToJson, FromJson)

///|
pub fn Position::new(x : Int, y : Int) -> Position {
  { x, y }
}

///|
pub struct Tile {
  mut pos : Position
  value : Int
  mut previous_pos : Position?
  mut merged_from : Array[Tile]?
}

///|
pub fn Tile::new(
  pos : Position,
  value : Int,
  merged_from? : Array[Tile],
) -> Tile {
  { pos, value, previous_pos: None, merged_from }
}

///|
pub fn Tile::save_position(self : Tile) -> Unit {
  self.previous_pos = Some(self.pos)
}

///|
pub fn Tile::update_position(self : Tile, pos : Position) -> Unit {
  self.pos = pos
}

///|
pub fn Tile::serialize(self : Tile) -> Json {
  { "position": { "x": self.pos.x, "y": self.pos.y }, "value": self.value }
}

///|
pub fn Tile::clear_merge(self : Tile) -> Unit {
  self.merged_from = None
}

///|
pub impl ToJson for Tile with to_json(self) {
  { "pos": self.pos.to_json(), "value": self.value.to_json() }
}

///|
pub impl FromJson for Tile with from_json(json, path) {
  match json {
    { "pos": pos, "value": value, .. } =>
      {
        pos: FromJson::from_json(pos, path.add_key("pos")),
        value: FromJson::from_json(value, path.add_key("value")),
        previous_pos: None,
        merged_from: None,
      }
    _ => raise @json.JsonDecodeError((path, "Tile expected"))
  }
}
