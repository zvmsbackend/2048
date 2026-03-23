///|
let messages : Map[String, String] = {}

///|
let default_messages : Map[String, String] = {
  "intro": "Join the tiles!",
  "new_game": "New Game",
  "undo": "Undo",
  "keep_going": "Keep Going",
  "try_again": "Try Again",
  "ok": "OK",
  "cancel": "Cancel",
  "start_a_new_game": "Start a new game?",
  "undo_the_current_move": "Undo the current move?",
  "you_win": "You win!",
  "game_over": "Game over!",
}

///|
extern "js" fn find_get_parameter(name : String) -> Nullable[String] =
  #|name => {
  #|	var r = null, tmp = [];
  #|	var items = location.search.substr(1).split('&');
  #|	for (var index = 0; index < items.length; index++) {
  #|		tmp = items[index].split('=');
  #|		if (tmp[0] === name) {
  #|			r = decodeURIComponent(tmp[1]);
  #|		}
  #|	}
  #|	return r;
  #|}

///|
pub fn init_i18n_messages() -> Unit {
  let lang = find_get_parameter("lang").to_option().unwrap_or("cn")
  let localized_messages = match lang {
    "cn" =>
      {
        "intro": "合并数字，得到 <strong>2048!</strong>",
        "new_game": "新游戏",
        "undo": "撤销",
        "keep_going": "继续游戏",
        "try_again": "重新开始",
        "ok": "确定",
        "cancel": "取消",
        "start_a_new_game": "开始新游戏？",
        "undo_the_current_move": "撤销当前移动？",
        "you_win": "你赢了！",
        "game_over": "游戏结束！",
      }
    _ => {}
  }
  messages.merge_in_place(default_messages)
  messages.merge_in_place(localized_messages)
}

///|
pub fn i18n(key : String) -> String {
  messages.get(key).unwrap_or("")
}
