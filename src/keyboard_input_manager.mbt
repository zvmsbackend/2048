///|
struct KeyboardInputManager {
  events : Map[String, Array[(Any) -> Unit]]
  event_touch_start : String
  event_touch_move : String
  event_touch_end : String
}

///|
extern "js" fn is_ie() -> Bool =
  #|() => window.navigator.msPointerEnabled

///|
pub fn KeyboardInputManager::new() -> KeyboardInputManager {
  let self = if is_ie() {
    {
      events: {},
      event_touch_start: "MSPointerDown",
      event_touch_move: "MSPointerMove",
      event_touch_end: "MSPointerUp",
    }
  } else {
    {
      events: {},
      event_touch_start: "touchstart",
      event_touch_move: "touchmove",
      event_touch_end: "touchend",
    }
  }
  self.listen()
  self
}

///|
pub fn KeyboardInputManager::on(
  self : KeyboardInputManager,
  event : String,
  callback : (Any) -> Unit,
) -> Unit {
  let handlers = self.events
    .get(event)
    .unwrap_or_else(() => {
      let handlers = []
      self.events[event] = handlers
      handlers
    })
  handlers.push(callback)
}

///|
pub fn KeyboardInputManager::emit(
  self : KeyboardInputManager,
  event : String,
  data? : Any,
) -> Unit {
  if self.events.get(event) is Some(handlers) {
    for handler in handlers {
      if data is Some(data) {
        handler(data)
      } else {
        handler(Any::undefined())
      }
    }
  }
}

///|
#external
pub type Event

///|
pub extern "js" fn Event::prevent_default(self : Event) -> Unit =
  #|self => self.preventDefault()

///|
extern "js" fn install_keydown_listener(
  move_ : (Int) -> Unit,
  restart : (Event) -> Unit,
) -> Unit =
  #|(move, restart) => {
  #|  let map = {
  #|    38: 0, // Up
  #|    39: 1, // Right
  #|    40: 2, // Down
  #|    37: 3, // Left
  #|    75: 0, // Vim up
  #|    76: 1, // Vim right
  #|    74: 2, // Vim down
  #|    72: 3, // Vim left
  #|    87: 0, // W
  #|    68: 1, // D
  #|    83: 2, // S
  #|    65: 3  // A
  #|  };
  #|  document.addEventListener("keydown", function (event) {
  #|    var modifiers = event.altKey || event.ctrlKey || event.metaKey ||
  #|                    event.shiftKey;
  #|    var mapped    = map[event.which];
  #|
  #|    if (!modifiers) {
  #|      if (mapped !== undefined) {
  #|        event.preventDefault();
  #|        move(mapped);
  #|      }
  #|    }
  #|
  #|    // R key restarts the game
  #|    if (!modifiers && event.which === 82) {
  #|      restart(event);
  #|    }
  #|  });
  #|}

///|
extern "js" fn KeyboardInputManager::install_touch_listeners(
  self : KeyboardInputManager,
  move_ : (Int) -> Unit,
) -> Unit =
  #|(self, move) => {
  #|  var touchStartClientX, touchStartClientY;
  #|  var gameContainer = document.getElementsByClassName("container")[0];
  #|
  #|  gameContainer.addEventListener(self.event_touch_start, function (event) {
  #|    if ((!window.navigator.msPointerEnabled && event.touches.length > 1) ||
  #|        event.targetTouches.length > 1) {
  #|      return; // Ignore if touching with more than 1 finger
  #|    }
  #|
  #|    if (window.navigator.msPointerEnabled) {
  #|      touchStartClientX = event.pageX;
  #|      touchStartClientY = event.pageY;
  #|    } else {
  #|      touchStartClientX = event.touches[0].clientX;
  #|      touchStartClientY = event.touches[0].clientY;
  #|    }
  #|
  #|    event.preventDefault();
  #|  });
  #|
  #|  gameContainer.addEventListener(self.event_touch_move, function (event) {
  #|    event.preventDefault();
  #|  });
  #|
  #|  gameContainer.addEventListener(self.event_touch_end, function (event) {
  #|    if ((!window.navigator.msPointerEnabled && event.touches.length > 0) ||
  #|        event.targetTouches.length > 0) {
  #|      return; // Ignore if still touching with one or more fingers
  #|    }
  #|
  #|    var touchEndClientX, touchEndClientY;
  #|
  #|    if (window.navigator.msPointerEnabled) {
  #|      touchEndClientX = event.pageX;
  #|      touchEndClientY = event.pageY;
  #|    } else {
  #|      touchEndClientX = event.changedTouches[0].clientX;
  #|      touchEndClientY = event.changedTouches[0].clientY;
  #|    }
  #|
  #|    var dx = touchEndClientX - touchStartClientX;
  #|    var absDx = Math.abs(dx);
  #|
  #|    var dy = touchEndClientY - touchStartClientY;
  #|    var absDy = Math.abs(dy);
  #|
  #|    if (Math.max(absDx, absDy) > 10) {
  #|      // (right : left) : (down : up)
  #|      move(absDx > absDy ? (dx > 0 ? 1 : 3) : (dy > 0 ? 2 : 0));
  #|    }
  #|  });
  #|}

///|
pub fn KeyboardInputManager::listen(self : KeyboardInputManager) -> Unit {
  install_keydown_listener(data => self.emit("move", data=Any::from(data)), e => {
    self.restart_with_confirmation(e)
  })
  self.bind_button_press(".retry-button", e => self.restart(Any::to(e)))
  self.bind_button_press(".restart-button", e => {
    self.restart_with_confirmation(Any::to(e))
  })
  self.bind_button_press(".undo-button", e => {
    self.undo_with_confirmation(Any::to(e))
  })
  self.bind_button_press(".keep-playing-button", e => {
    self.keep_playing(Any::to(e))
  })
  self.bind_button_press(".undo-move-button", e => self.undo_move(Any::to(e)))
  self.bind_button_press(".confirm-button", e => self.restart(Any::to(e)))
  self.bind_button_press(".cancel-button", e => self.keep_playing(Any::to(e)))
  self.install_touch_listeners(data => self.emit("move", data=Any::from(data)))
}

///|
fn KeyboardInputManager::undo_move(
  self : KeyboardInputManager,
  e : Event,
) -> Unit {
  e.prevent_default()
  self.emit("undoMove")
}

///|
fn KeyboardInputManager::restart(
  self : KeyboardInputManager,
  e : Event,
) -> Unit {
  e.prevent_default()
  self.emit("restart")
}

///|
fn KeyboardInputManager::restart_with_confirmation(
  self : KeyboardInputManager,
  e : Event,
) -> Unit {
  e.prevent_default()
  self.emit("restartWithConfirmation")
}

///|
fn KeyboardInputManager::undo_with_confirmation(
  self : KeyboardInputManager,
  e : Event,
) -> Unit {
  e.prevent_default()
  self.emit("undoWithConfirmation")
}

///|
fn KeyboardInputManager::keep_playing(
  self : KeyboardInputManager,
  e : Event,
) -> Unit {
  e.prevent_default()
  self.emit("keepPlaying")
}

///|
extern "js" fn KeyboardInputManager::bind_button_press(
  self : KeyboardInputManager,
  selector : String,
  fun : (Any) -> Unit,
) -> Unit =
  #|(self, selector, fun) => {
  #|  var button = document.querySelector(selector);
  #|  button.addEventListener("click", fun);
  #|  button.addEventListener(self.event_touch_start, fun);
  #|}
