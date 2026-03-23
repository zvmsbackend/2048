///|
priv trait Storage {
  set_item(Self, String, String) -> Unit
  get_item(Self, String) -> String?
  remove_item(Self, String) -> Unit
}

///|
#external
priv type LocalStorage

///|
extern "js" fn LocalStorage::get_instance() -> LocalStorage =
  #|() => window.localStorage

///|
extern "js" fn LocalStorage::set_item_ffi(
  self : LocalStorage,
  id : String,
  val : String,
) -> Unit =
  #|(self, id, val) => self.setItem(id, val)

///|
impl Storage for LocalStorage with set_item(self, id, val) {
  self.set_item_ffi(id, val)
}

///|
extern "js" fn LocalStorage::get_item_ffi(
  self : LocalStorage,
  id : String,
) -> Nullable[String] =
  #|(self, id) => self.getItem(id)

///|
impl Storage for LocalStorage with get_item(self, id) {
  self.get_item_ffi(id).to_option()
}

///|
extern "js" fn LocalStorage::remove_item_ffi(
  self : LocalStorage,
  id : String,
) -> Unit =
  #|(self, id) => self.removeItem(id)

///|
impl Storage for LocalStorage with remove_item(self, id) {
  self.remove_item_ffi(id)
}

///|
priv struct FakeStorage {
  data : Map[String, String]
}

///|
fn FakeStorage::new() -> FakeStorage {
  { data: {} }
}

///|
impl Storage for FakeStorage with set_item(self, id, val) {
  self.data[id] = val
}

///|
impl Storage for FakeStorage with get_item(self, id) {
  self.data.get(id)
}

///|
impl Storage for FakeStorage with remove_item(self, id) {
  self.data.remove(id)
}

///|
struct LocalStorageManager {
  best_score_key : String
  game_states_stack_key : String
  storage : &Storage
}

///|
extern "js" fn local_storage_supported() -> Bool =
  #|() => {
  #|  var testKey = "test";
  #|
  #|  try {
  #|    var storage = window.localStorage;
  #|    storage.setItem(testKey, "1");
  #|    storage.removeItem(testKey);
  #|    return true;
  #|  } catch (error) {
  #|    return false;
  #|  }
  #|}

///|
pub fn LocalStorageManager::new() -> LocalStorageManager {
  {
    best_score_key: "bestScore",
    game_states_stack_key: "gameStatesStack",
    storage: if local_storage_supported() {
      LocalStorage::get_instance() as &Storage
    } else {
      FakeStorage::new()
    },
  }
}

///|
pub fn LocalStorageManager::get_best_score(self : LocalStorageManager) -> Int {
  (self.storage.get_item(self.best_score_key).unwrap_or("0")
  |> @strconv.parse_int) catch {
    _ => 0
  }
}

///|
pub fn LocalStorageManager::set_best_score(
  self : LocalStorageManager,
  score : Int,
) -> Unit {
  self.storage.set_item(self.best_score_key, score.to_string())
}

///|
fn LocalStorageManager::get_game_states_stack(
  self : LocalStorageManager,
) -> Array[GameState] {
  let game_states_stack_json = match
    self.storage.get_item(self.game_states_stack_key) {
    Some(json) => json
    None => return []
  }
  (game_states_stack_json |> @json.parse |> @json.from_json) catch {
    _ => []
  }
}

///|
pub fn LocalStorageManager::get_game_state(
  self : LocalStorageManager,
) -> GameState? {
  self.get_game_states_stack().last()
}

///|
pub fn LocalStorageManager::set_game_state(
  self : LocalStorageManager,
  game_state : GameState,
) -> Unit {
  self.storage.set_item(
    self.game_states_stack_key,
    (self.get_game_states_stack() + [game_state]).to_json().stringify(),
  )
}

///|
pub fn LocalStorageManager::clear_game_state(
  self : LocalStorageManager,
) -> Unit {
  self.storage.remove_item(self.game_states_stack_key)
}

///|
pub fn LocalStorageManager::pop_game_state(
  self : LocalStorageManager,
) -> GameState? {
  match self.get_game_states_stack() {
    [] => None
    [state] => Some(state)
    [.. init, prev, _curr] => {
      self.storage.set_item(
        self.game_states_stack_key,
        init.to_json().stringify(),
      )
      Some(prev)
    }
  }
}

///|
pub fn LocalStorageManager::push_game_state(
  self : LocalStorageManager,
  state : GameState,
) -> Unit {
  let game_states_stack = self.get_game_states_stack()
  if game_states_stack.length() > 50 {
    game_states_stack.remove(0) |> ignore
  }
  game_states_stack.push(state)
  self.storage.set_item(
    self.game_states_stack_key,
    game_states_stack.to_json().stringify(),
  )
}

///|
pub fn LocalStorageManager::get_length_of_game_states_stack(
  self : LocalStorageManager,
) -> Int {
  self.get_game_states_stack().length()
}
