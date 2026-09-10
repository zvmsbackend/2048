///|
let rand : @random.Rand = @random.Rand::new()

///|
struct Grid {
  size : Int
  cells : FixedArray[FixedArray[Tile?]]
} derive(ToJson, FromJson)

///|
fn empty_cells(size : Int) -> FixedArray[FixedArray[Tile?]] {
  FixedArray::makei(size, _ => FixedArray::make(size, None))
}

///|
pub fn Grid::new(size : Int) -> Grid {
  { size, cells: empty_cells(size), }
}

///|
pub fn Grid::copy(grid : Grid) -> Grid {
  let cells = FixedArray::makei(grid.size, i => {
    FixedArray::makei(grid.size, j => grid.cells[i][j])
  })
  { size: grid.size, cells, }
}

///|
pub fn Grid::random_available_cell(self : Grid) -> Position? {
  match self.available_cells().collect() {
    [] => None
    cells => Some(cells[rand.int(limit=cells.length())])
  }
}

///|
pub fn Grid::available_cells(self : Grid) -> Iter[Position] {
  (0)
  .until(self.size)
  .flat_map(x => {
    (0)
    .until(self.size)
    .filter_map(y => {
      if self.cells[x][y] is None {
        Some({ x, y, })
      } else {
        None
      }
    })
  })
}

///|
pub fn Grid::each_cell(self : Grid) -> Iter[Tile?] {
  self.cells.iter().flat_map(row => row.iter())
}

///|
pub fn Grid::cells_available(self : Grid) -> Bool {
  self.available_cells().any(_ => true)
}

///|
pub fn Grid::cell_available(self : Grid, pos : Position) -> Bool {
  !self.cell_occupied(pos)
}

///|
pub fn Grid::cell_occupied(self : Grid, pos : Position) -> Bool {
  self.cell_content(pos) is Some(_)
}

///|
pub fn Grid::cell_content(self : Grid, pos : Position) -> Tile? {
  if self.within_bounds(pos) {
    self.cells[pos.x][pos.y]
  } else {
    None
  }
}

///|
pub fn Grid::insert_tile(self : Grid, tile : Tile) -> Unit {
  self.cells[tile.pos.x][tile.pos.y] = Some(tile)
}

///|
pub fn Grid::remove_tile(self : Grid, pos : Position) -> Unit {
  self.cells[pos.x][pos.y] = None
}

///|
pub fn Grid::within_bounds(self : Grid, pos : Position) -> Bool {
  pos.x >= 0 && pos.x < self.size && pos.y >= 0 && pos.y < self.size
}
