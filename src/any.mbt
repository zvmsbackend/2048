///|
#external
pub type Any

///|
pub fn[T] Any::from(obj : T) -> Any = "%identity"

///|
pub fn[T] Any::to(self : Any) -> T = "%identity"

///|
pub extern "js" fn Any::undefined() -> Any =
  #|() => undefined

///|
#external
pub type Nullable[T]

///|
extern "js" fn Nullable::is_null_ffi(self : Any) -> Bool =
  #|self => self === null

///|
pub fn[T] Nullable::is_null(self : Nullable[T]) -> Bool {
  Nullable::is_null_ffi(Any::from(self))
}

///|
pub fn[T] Nullable::unwrap(self : Nullable[T]) -> T = "%identity"

///|
pub fn[T] Nullable::to_option(self : Nullable[T]) -> T? {
  if Nullable::is_null(self) {
    None
  } else {
    Some(self.unwrap())
  }
}
