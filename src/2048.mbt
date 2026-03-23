///|
pub fn start_game(size : Int, criteria : Int) -> Unit {
  init_i18n_messages()
  install_night_mode_handler()
  request_animation_frame(() => GameManager::new(size, criteria) |> ignore)
}
