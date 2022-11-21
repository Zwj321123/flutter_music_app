import 'package:hive_flutter/hive_flutter.dart';
import 'package:on_audio_query/on_audio_query.dart';

const _playlists = "playlists";

class PlaylistDataBase {
  List<SongModel> songList = [];

  // reference our box
  final _myBox = Hive.box(_playlists);

  // run this method if this is the 1st time ever opening this app
  void initDatabase() {
    //init my default songlist: my favourite
    if (_myBox.get("Favorite") == null) {
      _myBox.put("Favorite", songList);
    }
  }

  // load the data from database
  List<SongModel> loadData(String key) {
    songList = _myBox.get(key);
    return songList;
  }

  void deleteItem(String key) {
    _myBox.delete(key);
  }

  // update the database
  void updateDataBase(String key) {
    _myBox.put(key, songList);
  }

  void updateDataBaseWithVal(String key, List<SongModel> val) {
    songList = val;
    updateDataBase(key);
  }
}
