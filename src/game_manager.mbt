///|
struct GameManager {
  size : Int
  storage_manager : LocalStorageManager
  actuator : HtmlActuator
  start_tiles : Int
  criteria : Int
  mut grid : Grid
  mut score : Int
  mut over : Bool
  mut won : Bool
  mut keep_playing : Bool
}

///|
pub fn GameManager::new(size : Int, criteria : Int) -> GameManager {
  let self = {
    size,
    storage_manager: LocalStorageManager::new(),
    actuator: HtmlActuator::new(),
    start_tiles: 2,
    criteria,
    grid: Grid::new(0),
    score: 0,
    over: false,
    won: false,
    keep_playing: false,
  }

  KeyboardInputManager::new()
  ..on("move", payload => self.move_(Any::to(payload)))
  ..on("restart", _ => self.restart())
  ..on("undoMove", _ => self.undo_move())
  ..on("restartWithConfirmation", _ => self.restart_with_confirmation())
  ..on("undoWithConfirmation", _ => self.undo_with_confirmation())
  .on("keepPlaying", _ => self.keep_playing())

  self.setup()
  self
}

///|
fn GameManager::restart(self : GameManager) -> Unit {
  self.storage_manager.clear_game_state()
  self.actuator.continue_game()
  self.setup()
}

///|
fn GameManager::init_from_game_state(
  self : GameManager,
  state : GameState,
) -> Unit {
  self.grid = state.grid.copy()
  self.over = state.over
  self.won = state.won
  self.keep_playing = state.keep_playing
  self.score = state.score
}

///|
fn GameManager::generate_actuator_metadata(
  self : GameManager,
) -> ActuatorMetadata {
  {
    score: self.score,
    over: self.over,
    won: self.won,
    best_score: self.storage_manager.get_best_score(),
    terminated: self.is_game_terminated(),
    keep_playing: self.keep_playing,
  }
}

///|
fn GameManager::undo_move(self : GameManager) -> Unit {
  self.actuator.continue_game()
  if self.storage_manager.pop_game_state() is Some(previous_state) {
    self.init_from_game_state(previous_state)
    self.actuator.actuate(self.grid, self.generate_actuator_metadata())
  }
}

///|
fn GameManager::restart_with_confirmation(self : GameManager) -> Unit {
  self.actuator.prompt_restart()
}

///|
fn GameManager::undo_with_confirmation(self : GameManager) -> Unit {
  self.actuator.prompt_undo()
}

///|
fn GameManager::keep_playing(self : GameManager) -> Unit {
  self.keep_playing = true
  self.actuator.continue_game()
  self.actuate()
}

///|
fn GameManager::is_game_terminated(self : GameManager) -> Bool {
  self.over || (self.won && !self.keep_playing)
}

///|
fn GameManager::setup(self : GameManager) -> Unit {
  if self.storage_manager.get_game_state() is Some(previous_state) {
    self.init_from_game_state(previous_state)
  } else {
    self.grid = Grid::new(self.size)
    self.score = 0
    self.over = false
    self.won = false
    self.keep_playing = false
    self.add_start_tiles()
  }
  self.actuate()
}

///|
fn GameManager::add_start_tiles(self : GameManager) -> Unit {
  for _ in 0..<self.start_tiles {
    self.add_random_tile()
  }
}

///|
fn GameManager::add_random_tile(self : GameManager) -> Unit {
  if self.grid.random_available_cell() is Some(cell) {
    let value = if rand.int(limit=10) == 0 { 4 } else { 2 }
    let tile = Tile::new(cell, value)
    self.grid.insert_tile(tile)
  }
}

///|
fn GameManager::actuate(self : GameManager) -> Unit {
  if self.storage_manager.get_best_score() < self.score {
    self.storage_manager.set_best_score(self.score)
  }
  if self.over {
    self.storage_manager.clear_game_state()
  } else {
    self.storage_manager.push_game_state(self.serialize())
  }
  self.actuator.actuate(self.grid, self.generate_actuator_metadata())
}

///|
fn GameManager::serialize(self : GameManager) -> GameState {
  {
    grid: self.grid,
    score: self.score,
    over: self.over,
    won: self.won,
    keep_playing: self.keep_playing,
  }
}

///|
fn GameManager::prepare_tiles(self : GameManager) -> Unit {
  for tile in self.grid.each_cell() {
    if tile is Some(tile) {
      tile.merged_from = None
      tile.save_position()
    }
  }
}

///|
fn GameManager::move_tile(
  self : GameManager,
  tile : Tile,
  cell : Position,
) -> Unit {
  self.grid.remove_tile(tile.pos)
  tile.update_position(cell)
  self.grid.insert_tile(tile)
}

///|
#warnings("-unused_constructor")
priv enum Direction {
  Up = 0
  Right = 1
  Down = 2
  Left = 3
}

///|
fn Direction::get_vector(self : Direction) -> (Int, Int) {
  match self {
    Up => (0, -1)
    Right => (1, 0)
    Down => (0, 1)
    Left => (-1, 0)
  }
}

///|
fn GameManager::build_traversals(
  self : GameManager,
  vector : (Int, Int),
) -> (Array[Int], Array[Int]) {
  let x = (0).until(self.size).collect()
  let y = (0).until(self.size).collect()
  if vector is (1, _) {
    x.rev_in_place()
  }
  if vector is (_, 1) {
    y.rev_in_place()
  }
  (x, y)
}

///|
fn GameManager::move_(self : GameManager, direction : Direction) -> Unit {
  if self.is_game_terminated() {
    return
  }
  let vector = direction.get_vector()
  let traversals = self.build_traversals(vector)
  let mut moved = false
  self.prepare_tiles()
  for x in traversals.0 {
    for y in traversals.1 {
      let cell = { x, y, }
      if self.grid.cell_content(cell) is Some(tile) {
        let positions = self.find_farthest_position(cell, vector)
        if self.grid.cell_content(positions.next) is Some(next) &&
          next.value == tile.value &&
          next.merged_from is None {
          let merged = Tile::new(positions.next, tile.value * 2, merged_from=[
            tile, next,
          ])
          self.grid.insert_tile(merged)
          self.grid.remove_tile(tile.pos)
          tile.update_position(positions.next)
          self.score += merged.value
          if merged.value == self.criteria {
            self.won = true
          }
        } else {
          self.move_tile(tile, positions.farthest)
        }
        if cell != tile.pos {
          moved = true
        }
      }
    }
  }

  if moved {
    self.add_random_tile()
    if !self.moves_available() {
      self.over = true
    }
    self.actuate()
  }
}

///|
priv struct Positions {
  farthest : Position
  next : Position
}

///|
fn GameManager::find_farthest_position(
  self : GameManager,
  cell : Position,
  vector : (Int, Int),
) -> Positions {
  for previous = cell, cell = { x: cell.x + vector.0, y: cell.y + vector.1, }
      self.grid.within_bounds(cell) && self.grid.cell_available(cell)
      previous = cell, cell = { x: cell.x + vector.0, y: cell.y + vector.1, } {

  } nobreak {
    { farthest: previous, next: cell, }
  }
}

///|
fn GameManager::moves_available(self : GameManager) -> Bool {
  self.grid.cells_available() || self.tile_matches_available()
}

///|
fn GameManager::tile_matches_available(self : GameManager) -> Bool {
  for x in 0..<self.size {
    for y in 0..<self.size {
      if self.grid.cell_content({ x, y, }) is Some(tile) {
        for direction in [Up, Right] {
          let (dx, dy) = direction.get_vector()
          let cell = { x: x + dx, y: y + dy, }
          if self.grid.cell_content(cell) is Some(other) &&
            other.value == tile.value {
            return true
          }
        }
      }
    }
  }
  false
}
