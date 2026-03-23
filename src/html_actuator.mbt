///|
#external
priv type DomElement

///|
#external
priv type ClassList

///|
extern "js" fn DomElement::from_selector(
  selector : String,
) -> Nullable[DomElement] =
  #|(selector) => document.querySelector(selector)

///|
extern "js" fn DomElement::query_selector(
  self : DomElement,
  selector : String,
) -> Nullable[DomElement] =
  #|(self, selector) => self.querySelector(selector)

///|
extern "js" fn DomElement::create(tag : String) -> DomElement =
  #|(tag) => document.createElement(tag)

///|
extern "js" fn DomElement::class_list(self : DomElement) -> ClassList =
  #|(self) => self.classList

///|
extern "js" fn DomElement::apply_classes_ffi(
  self : DomElement,
  classes : String,
) -> Unit =
  #|(self, classes) => self.setAttribute("class", classes)

///|
extern "js" fn DomElement::set_text_content(
  self : DomElement,
  text : String,
) -> Unit =
  #|(self, text) => self.textContent = text

///|
fn DomElement::apply_classes(self : DomElement, classes : Iter[String]) -> Unit {
  self.apply_classes_ffi(classes.join(" "))
}

///|
extern "js" fn DomElement::append_child(
  self : DomElement,
  inner : DomElement,
) -> Unit =
  #|(self, inner) => self.appendChild(inner)

///|
extern "js" fn DomElement::clear(self : DomElement) -> Unit =
  #|(self) => {
  #|  while (self.firstChild) {
  #|    self.removeChild(self.firstChild);
  #|  }
  #|}

///|
extern "js" fn ClassList::remove(self : ClassList, class_name : String) -> Unit =
  #|(self, className) => self.remove(className)

///|
extern "js" fn ClassList::add(self : ClassList, class_name : String) -> Unit =
  #|(self, className) => self.add(className)

///|
struct HtmlActuator {
  tile_container : DomElement
  score_container : DomElement
  best_container : DomElement
  message_container : DomElement
  mut score : Int
}

///|
pub fn HtmlActuator::new() -> HtmlActuator {
  {
    tile_container: DomElement::from_selector(".tile-container").unwrap(),
    score_container: DomElement::from_selector(".score-container").unwrap(),
    best_container: DomElement::from_selector(".best-container").unwrap(),
    message_container: DomElement::from_selector(".game-message").unwrap(),
    score: 0,
  }
}

///|
pub(all) struct ActuatorMetadata {
  score : Int
  best_score : Int
  terminated : Bool
  over : Bool
  won : Bool
  keep_playing : Bool
}

///|
extern "js" fn request_animation_frame(callback : () -> Unit) -> Unit =
  #|(callback) => window.requestAnimationFrame(callback)

///|
pub fn HtmlActuator::actuate(
  self : HtmlActuator,
  grid : Grid,
  metadata : ActuatorMetadata,
) -> Unit {
  request_animation_frame(() => {
    self.tile_container.clear()

    for cell in grid.each_cell() {
      if cell is Some(tile) {
        self.add_tile(tile, false)
      }
    }

    self.update_score(metadata.score)
    self.update_best_score(metadata.best_score)

    if metadata.terminated {
      if metadata.over {
        if metadata.won && !metadata.keep_playing {
          self.message(true)
        } else {
          self.message(false)
        }
      } else if metadata.won {
        self.message(true)
      }
    }
  })
}

///|
pub fn HtmlActuator::continue_game(self : HtmlActuator) -> Unit {
  self.clear_message()
}

///|
pub fn HtmlActuator::add_tile(
  self : HtmlActuator,
  tile : Tile,
  ephemeral : Bool,
) -> Unit {
  let wrapper = DomElement::create("div")
  let inner = DomElement::create("div")
  let position = tile.previous_pos.unwrap_or(tile.pos)
  let pos_class = position_class(position)

  let classes = ["tile", "tile-\{tile.value}", pos_class]

  if tile.value > 2048 {
    classes.push("tile-super")
  }

  wrapper.apply_classes(classes.iter())

  inner.class_list().add("tile-inner")
  inner.set_text_content(tile.value.to_string())

  if tile.previous_pos is Some(_) {
    let new_pos_class = position_class(tile.pos)
    if new_pos_class != classes[2] {
      request_animation_frame(() => {
        classes[2] = new_pos_class
        wrapper.apply_classes(classes.iter())
      })
    }
  } else if tile.merged_from is Some(merged_from) {
    classes.push("tile-merged")
    wrapper.apply_classes(classes.iter())

    for merged in merged_from {
      self.add_tile(merged, true)
    }
  } else {
    classes.push("tile-new")
    wrapper.apply_classes(classes.iter())
  }
  if ephemeral {
    request_animation_frame(() => {
      classes.push("tile-removed")
      wrapper.apply_classes(classes.iter())
    })
  }

  wrapper.append_child(inner)
  self.tile_container.append_child(wrapper)
}

///|
fn normalize_position(pos : Position) -> Position {
  { x: pos.x + 1, y: pos.y + 1 }
}

///|
fn position_class(pos : Position) -> String {
  let { x, y } = normalize_position(pos)
  "tile-position-\{x}-\{y}"
}

///|
fn HtmlActuator::update_score(self : HtmlActuator, score : Int) -> Unit {
  self.score_container.clear()

  let difference = score - self.score
  self.score = score

  self.score_container.set_text_content(self.score.to_string())

  if difference > 0 {
    let addition = DomElement::create("div")
    addition.class_list().add("score-addition")
    addition.set_text_content("+\{difference}")

    self.score_container.append_child(addition)
  }
}

///|
extern "js" fn to_fixed(n : Double, fraction_digits : Int) -> String =
  #|(n, fractionDigits) => n.toFixed(fractionDigits)

///|
fn HtmlActuator::update_best_score(
  self : HtmlActuator,
  best_score : Int,
) -> Unit {
  self.best_container.set_text_content(
    to_fixed(best_score.to_double() * 1.33, 2),
  )
}

///|
fn HtmlActuator::message(self : HtmlActuator, won : Bool) -> Unit {
  let (ty, message) = if won {
    ("game-won", i18n("you_win"))
  } else {
    ("game-over", i18n("game_over"))
  }
  self.message_container.class_list().add(ty)
  self.message_container.query_selector("p").unwrap().set_text_content(message)
}

///|
pub fn HtmlActuator::prompt_restart(self : HtmlActuator) -> Unit {
  self.clear_message()
  let message = i18n("start_a_new_game")
  self.message_container.class_list().add("restart-game")
  self.message_container.query_selector("p").unwrap().set_text_content(message)
}

///|
fn HtmlActuator::clear_message(self : HtmlActuator) -> Unit {
  self.message_container
  .class_list()
  ..remove("game-won")
  ..remove("game-over")
  ..remove("restart-game")
  .remove("undo-move")
}

///|
pub fn HtmlActuator::prompt_undo(self : HtmlActuator) -> Unit {
  self.clear_message()
  let message = i18n("undo_the_current_move")
  self.message_container.class_list().add("undo-move")
  self.message_container.query_selector("p").unwrap().set_text_content(message)
}
