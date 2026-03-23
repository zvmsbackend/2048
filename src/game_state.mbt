///|
pub(all) struct GameState {
  grid : Grid
  score : Int
  over : Bool
  won : Bool
  keep_playing : Bool
} derive(ToJson, FromJson)
