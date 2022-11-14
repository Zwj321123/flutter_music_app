import 'package:hive_flutter/hive_flutter.dart';
import 'package:on_audio_query/on_audio_query.dart';

const _playlists = "playlists";

class PlaylistDataBase {
  List<SongModel> toDoList = [];

  // reference our box
  final _myBox = Hive.box(_playlists);

  // load the data from database
  void loadData(String key) {
    toDoList = _myBox.get(key);
  }

  // update the database
  void updateDataBase(String key) {
    _myBox.put(key, toDoList);
  }
}