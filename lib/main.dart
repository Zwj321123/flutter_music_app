import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/utils/player_controls.dart';
import 'package:music_app/utils/playlist_row_item.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:rxdart/rxdart.dart';

import 'data/database.dart';

const String dataBoxName = "data";

void main() async {
  //initialize hive db
  await Hive.initFlutter();
  //open the playlists
  await Hive.openBox("playlists");
  //run your app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(
        title: 'Glass Morphism',
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
//on audio query plugin
  final OnAudioQuery _audioQuery = OnAudioQuery();

//player
  final AudioPlayer _player = AudioPlayer();

  PageStorageKey songsStorageKey =
      const PageStorageKey("restore_songs_scroll_pos");
  bool _isPlayerControlsWidgetVisible = false;
  List<SongModel> songs = <SongModel>[];

  //define a variable to shopping box reference
  final _playlists = "playlists";

  //database
  PlaylistDataBase db = PlaylistDataBase();

  //form key for validating the form fields
  final _formKey = GlobalKey<FormState>();

  //define a text controller and use it to retrieve the current value of the TextField
  final TextEditingController _controller = TextEditingController();
  int currIndex = 0;
  late AudioSource mainPlayList;

  callback() {
    setState(() {
      _isPlayerControlsWidgetVisible = !_isPlayerControlsWidgetVisible;
    });
  }

  //initial state method to request storage permission
  @override
  void initState() {
    super.initState();
    db.initDatabase();
    requestStoragePermission();
  }

  //dispose the player when done
  @override
  void dispose() {
    Hive.close(); //close all open boxes
    _player.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black12,
      body: Container(
        margin: const EdgeInsets.only(top: 0, bottom: 0, left: 0, right: 0),
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage("images/GawrGura.png"),
                fit: BoxFit.cover,
                opacity: 0.3),
          ),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: double.infinity,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white60, Colors.white10]),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(width: 2, color: Colors.white30)),
                  child: _isPlayerControlsWidgetVisible == true
                      ? PlayerControls(
                          _player, songs, callback) //playerControlsWidget()
                      : tabsControllerWidget(),
                ),
              )),
        ),
      ),
      //home bottom player controls
      bottomSheet:
          const Visibility(visible: false, child: Text("Home Player controls")),
    );
  }

  //player position and current playing song duration state stream
  Stream<PositionDurationState> get _positionDurationStateStream =>
      Rx.combineLatest2<Duration, Duration?, PositionDurationState>(
          _player.positionStream,
          _player.durationStream,
          (position, duration) => PositionDurationState(
              position: position, duration: duration ?? Duration.zero));

//tabs controller page widget
  DefaultTabController tabsControllerWidget() {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.indigo[700]?.withOpacity(0.4),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.music_note_outlined),
                text: "Songs",
              ),
              Tab(
                icon: Icon(Icons.playlist_play),
                text: "Playlists",
              ),
              Tab(
                icon: Icon(Icons.folder_outlined),
                text: "Folders",
              ),
            ],
          ),
          title: const Text(
            'MyPlayer',
            style: TextStyle(color: Colors.white60),
          ),
        ),
        body: TabBarView(
          children: [
            //Center(child: Text("All songs in your device here...",style: TextStyle(color: Colors.white30, fontSize: 25),),),
            //songs tab content
            songsListView(),
            playListWidget(context),
            const Center(
              child: Text(
                "Songs in their bags goes here...",
                style: TextStyle(color: Colors.white30, fontSize: 25),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget songsListView() {
    //use future builder to create a list view with songs
    return FutureBuilder<List<SongModel>>(
      future: _audioQuery.querySongs(
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      ),
      builder: (context, item) {
        //loading content indicator
        if (item.data == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (item.data!.isEmpty) {
          return const Center(
            child: Text(
              "No Songs Found!!, Add Some",
              style: TextStyle(color: Colors.white30),
            ),
          );
        }
        //songs are available build list view
        songs = item.data!;

        mainPlayList = ConcatenatingAudioSource(
          // Start loading next item just before reaching it
          useLazyPreparation: true,
          // Customise the shuffle algorithm
          shuffleOrder: DefaultShuffleOrder(),
          // Specify the playlist items
          children: addAudioFromLocal(),
        );

        return ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            //   return Text(songs.elementAt(index).displayName, style: const TextStyle(color: Colors.white60),);

            return InkWell(
                onTap: () async {
                  changePlayerControlsWidgetVisibility();
                  //updateCurrIndex
                  currIndex = index;
                  showToast(context, songs[index].displayName);

                  //play song (default main list)
                  await _player.setAudioSource(mainPlayList,
                      initialIndex: index, initialPosition: Duration.zero);
                  await _player.play();
                },
                child: Container(
                  margin:
                      const EdgeInsets.only(top: 10.0, left: 15.0, right: 15.0),
                  padding: const EdgeInsets.only(
                      top: 20.0, bottom: 20.0, right: 10, left: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(
                        color: Colors.white70,
                        width: 1.0,
                        style: BorderStyle.solid),
                  ),
                  child: Text(
                    songs.elementAt(index).displayName,
                    style: const TextStyle(color: Colors.white60),
                  ),
                ));
          },
        );
      },
    );
    // return const Center(child: Text("Text brother"),);
  }

  Widget playListWidget(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        newPlaylistBtn(context),
        Expanded(
            child: ValueListenableBuilder(
          valueListenable: Hive.box(_playlists).listenable(),
          builder: (BuildContext context, Box box, _) {
            if (box.keys.isEmpty) {
              return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //cartHeadWidget("0"),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 20),
                      child: const Text(
                        "Empty playlist!!😀 Click + \n Above to add playlists...🚀",
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ]);
            }
            //list to hold items to show in listview
            List<dynamic> playlistNames = [];
            //playlistNames.add("My playlists");
            //add items and reverse items names to newest first
            playlistNames.addAll(box.keys.toList().reversed.toList());
            //list view builder
            return ListView.builder(
                itemCount: playlistNames.length,
                itemBuilder: (context, index) {
                  return PlaylistRowItem(
                      playlistNames.elementAt(index).toString(), 0, db);
                });
          },
        ))
      ],
    );
  }

//create new playlist btn
  Widget newPlaylistBtn(BuildContext context) {
    return InkWell(
      onTap: () {
        //launch add playlist dialog
        newPlaylistDialog(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(
              color: Colors.white24, width: 1.0, style: BorderStyle.solid),
        ),
        child: Row(
          children: const [
            Flexible(
              child: Icon(
                Icons.add,
                color: Colors.lightBlue,
                size: 30,
              ),
            ),
            Flexible(
              flex: 4,
              child: Text(
                "Add New Playlist",
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //request permission
  void requestStoragePermission() async {
    //only if the application was not compiled to run on the web.
    if (!kIsWeb) {
      //check if not permission status
      bool status = await _audioQuery.permissionsStatus();
      //request it if not given
      if (!status) {
        await _audioQuery.permissionsRequest();
      }
      //make sure set state method is called
      setState(() {});
    }
  }

//player widget visibility
  void changePlayerControlsWidgetVisibility() {
    //Notify the framework that the internal state of this object has changed.
    setState(() {
      _isPlayerControlsWidgetVisible = !_isPlayerControlsWidgetVisible;
    });
  }

  void showToast(BuildContext context, String displayName) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text('play $displayName',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.lightBlue, fontSize: 14)),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0)),
      ),
    );
  }

  List<AudioSource> addAudioFromLocal() {
    List<AudioSource> res = [];
    for (int i = 0; i < songs.length; i++) {
      res.add(AudioSource.uri(Uri.parse(songs[i].uri!)));
    }
    return res;
  }

  void newPlaylistDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("New Playlist"),
            content: Form(
              key: _formKey,
              child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: TextFormField(
                      controller: _controller,
                      //will help get the field value on submit
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Playlist Name',
                      ),
                      //validator on submit, must return null when every thing ok
                      //the validator receives the text that the user has entered
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'playlist name cannot be empty';
                        } else if (value.trim().isEmpty) {
                          return 'playlist name cannot be empty';
                        }
                        return null;
                      })),
            ),
            actions: [
              //Cancel btn
              TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(); //dismiss dialog
                  }),
              //Create btn
              TextButton(
                  child: const Text('Create'),
                  onPressed: () {
                    //validate returns true of the form is valid, or false otherwise
                    if (_formKey.currentState!.validate()) {
                      //use put to add a key-value map
                      List<SongModel> playlistSongs =
                          List.empty(growable: true);
                      String playlistName = _controller.text;
                      db.updateDataBaseWithVal(playlistName, playlistSongs);
                      _controller.clear(); // clear text in field
                      showToast(context, "playlist $playlistName is created");
                      Navigator.of(context).pop(); //dismiss dialog
                    }
                  }),
            ],
          );
        });
  }
}
