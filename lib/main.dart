import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:ui';

import 'package:on_audio_query/on_audio_query.dart';
import 'package:rxdart/rxdart.dart';
import 'package:hive_flutter/adapters.dart';

import 'data/database.dart';
const String dataBoxName = "data";

void main() async{
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
      home: const MyHomePage(title: 'Glass Morphism'),
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

  PageStorageKey songsStorageKey = const PageStorageKey("restore_songs_scroll_pos");
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

  //initial state method to request storage permission
  @override
  void initState() {
    super.initState();
    requestStoragePermission();
  }

  //dispose the player when done
  @override
  void dispose(){
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
        margin: const EdgeInsets.only(top:0, bottom:0, left:0, right:0),
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("images/GawrGura.png"),
              fit: BoxFit.cover,
              opacity:0.3
            ),
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
                    colors: [Colors.white60, Colors.white10]
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(width: 2, color: Colors.white30)
                ),
                child: _isPlayerControlsWidgetVisible == true? playerControlsWidget(): tabsControllerWidget(),
              ),
            )
          ),
        ),
      ),
        //home bottom player controls
        bottomSheet: const Visibility(
            visible: false,
            child: Text("Home Player controls")
        ),
    );
  }

  //player position and current playing song duration state stream
  Stream<PositionDurationState> get _positionDurationStateStream =>
    Rx.combineLatest2<Duration, Duration?, PositionDurationState>(
      _player.positionStream, _player.durationStream, (position, duration) => PositionDurationState(
        position: position, duration: duration?? Duration.zero
    ));


  //player control widget
  SingleChildScrollView playerControlsWidget(){
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(top: 56.0, right: 20.0, left: 20.0),
        child: Column(
          children: [
            //controls exit btn and like btn
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: changePlayerControlsWidgetVisibility, //hides the player view
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70,),
                ),
                InkWell(
                  onTap: changePlayerControlsWidgetVisibility, //hides the player view
                  child: const Icon(Icons.favorite_border_outlined, color: Colors.white70,),
                )
              ],
            ),
            //artwork container
            Container(
              width: double.infinity,
              height: 300,
              margin: const EdgeInsets.only(top: 30, bottom: 30),
              child: StreamBuilder<int?>(
                stream: _player.currentIndexStream,
                builder: (context, snapshot){
                  final currentIndex = snapshot.data;
                  if (currentIndex != null) {
                    return QueryArtworkWidget(
                      id: songs[currentIndex].id,
                      type: ArtworkType.AUDIO,
                      artworkBorder: BorderRadius.circular(4.0),
                    );
                  }
                  return const CircularProgressIndicator();
                }
              )
            ),
            //current song title container, the palying song
              Container(
              width: double.infinity,
              height: 50,
              margin: const EdgeInsets.only(top: 30, bottom: 30),
              child: StreamBuilder<int?>(
                stream: _player.currentIndexStream,
                builder: (context, snapshot){
                  final currentIndex = snapshot.data;
                  if (currentIndex != null) {
                    return Text(
                        nameWithoutExtension(songs[currentIndex].displayName),
                        style: const TextStyle(
                            color: Colors.white70, fontWeight: FontWeight.bold)
                    );
                  }
                  return const Text('');
                }
              )
            ),
            //seek bar, current position and total song duration
            Container(
              padding: EdgeInsets.zero,
              margin: const EdgeInsets.only(bottom: 4.0),
                // width: double.infinity,
                // height: 48.0,
              //slider bar duration state stream
              child: StreamBuilder<PositionDurationState>(
                stream: _positionDurationStateStream,
                builder: (context, snapshot){
                  final positionDurationState = snapshot.data;
                  final progress = positionDurationState?.position?? Duration.zero;
                  final duration = positionDurationState?.duration?? Duration.zero;

                  return ProgressBar(
                    progress: progress,
                    total: duration,
                    baseBarColor: const Color(0xEE9E9E9E),
                    progressBarColor: Colors.blue[50],
                    thumbColor: Colors.white60.withBlue(99),
                    timeLabelTextStyle: const TextStyle(
                      color: Color(0xEE9E9E9E),
                    ),
                    onSeek: (duration){
                      _player.seek(duration);
                    },
                  );
                }
              )
            ),

            //repeat mode, shuffle mode, seek pre, play/pause next, list container
            Container(
              margin: const EdgeInsets.only(top: 30, bottom: 4.0),
                // width: double.infinity,
                // height: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  //repeat mode & shuffle
                  InkWell(
                    onTap: (){
                      //player.loopMode == LoopMode.one? _player.setLoopMode(LoopMode.all): _player.setLoopMode(LoopMode.one);
                      final loopMode = _player.loopMode;
                      final shuffle = _player.shuffleModeEnabled;
                      //change to loop one mode
                      if (LoopMode.all == loopMode && !shuffle){
                        _player.setLoopMode(LoopMode.one);
                        //change to shuffle mode
                      } else if (LoopMode.one == loopMode && !shuffle){
                        _player.setLoopMode(LoopMode.all);
                        _player.setShuffleModeEnabled(true);
                      }
                      else {
                        //change to loop all (no shuffle) mode
                        _player.setLoopMode(LoopMode.all);
                        _player.setShuffleModeEnabled(false);
                      }
                    },
                    child: StreamBuilder<LoopMode>(
                      stream: _player.loopModeStream,
                      builder: (context, snapshot){
                        final loopMode = snapshot.data;
                        final shuffle = _player.shuffleModeEnabled;
                        if (LoopMode.all == loopMode && !shuffle){
                          return const Icon(Icons.repeat, color: Colors.white70,);
                        }
                        else if (LoopMode.one == loopMode && !shuffle){
                          return const Icon(Icons.repeat_one, color: Colors.white70,);
                        }
                        else if (LoopMode.all == loopMode && shuffle){
                          return const Icon(Icons.shuffle, color: Colors.white70,);
                        }
                        return const Icon(Icons.shuffle_sharp, color: Colors.white70,);
                      }
                    ),
                  ),

                  //skip to prev
                  InkWell(
                    onTap: (){if (_player.hasPrevious){_player.seekToPrevious();}},
                    child: const Icon(Icons.skip_previous, color: Colors.white70, size: 30,),

                  ),

                  InkWell(
                    onTap: (){
                      if (_player.playing){
                        _player.pause();
                      } else {
                        if (_player.currentIndex != null){
                          _player.play();
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24, width:1, style: BorderStyle.solid),
                        shape: BoxShape.circle,
                      ),
                      child: StreamBuilder<bool>(
                        stream: _player.playingStream,
                        builder: (context, snapshot){
                          bool? playingState = snapshot.data;
                          if (playingState != null && playingState){
                            return const Icon(Icons.pause, size: 36, color: Colors.white70,);
                          }
                          return const Icon(Icons.play_arrow, size: 36, color: Colors.white70,);
                        }
                      )
                    )
                  ),

                  //skipNext
                  InkWell(
                    onTap: (){if (_player.hasNext){_player.seekToNext();}},
                    child: const Icon(Icons.skip_next, color: Colors.white70, size: 30,),
                  ),

                  //go to playList
                  InkWell(
                    onTap: (){changePlayerControlsWidgetVisibility();},
                    child: const Icon(Icons.playlist_play, color: Colors.white70,),
                  ),

                ]
              )
            ),
          ],
        )
      ),
    );
  }

//tabs controller page widget
  DefaultTabController tabsControllerWidget(){
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
          title: const Text('MyPlayer', style: TextStyle(color: Colors.white60),),
        ),
        body: TabBarView(
          children: [
            //Center(child: Text("All songs in your device here...",style: TextStyle(color: Colors.white30, fontSize: 25),),),
            //songs tab content
            songsListView(),
                  //newPlaylistBtn(context),
            ValueListenableBuilder(
              valueListenable: Hive.box(_playlists).listenable(),
              builder: (BuildContext context, Box box, _){
                if (box.keys.isEmpty){
                  return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        //cartHeadWidget("0"),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                          child: const Text(
                            "Empty playlist!!😀 Click + \n Above to add playlists...🚀",
                            style: TextStyle(color: Colors.white70, fontSize: 30, fontWeight:  FontWeight.bold),
                          ),
                        ),

                      ]
                  );
                }
                //list to hold items to show in listview
                List<dynamic> playlistNames = [];
                //playlistNames.add("My playlists");
                //add items and reverse items names to newest first
                playlistNames.addAll(box.values.toList().reversed.toList());
                //list view builder
                return ListView.builder(
                    itemCount: playlistNames.length,
                    itemBuilder: (context, index){
                      // if (index == 0){
                      //   return cartHeadWidget((playlistNames.length-1).toString());
                      // }
                      Playlist p = cast<Playlist>(playlistNames.elementAt(index));
                      return playlistRowItem(playlistNames.elementAt(index));
                    }
                );
              },
            ),
            //newPlaylistBtn(context),
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
                  // await _player.setAudioSource(
                  //     AudioSource.uri(Uri.parse(songs[index].uri!)));
                  await _player.setAudioSource(mainPlayList, initialIndex: index, initialPosition: Duration.zero);
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

//create new playlist btn
  Widget newPlaylistBtn(BuildContext context){
    return InkWell(
      onTap: (){
        //launch add playlist dialog
        newPlaylistDialog(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(color: Colors.white24, width: 1.0, style: BorderStyle.solid),
        ),
        child: Row(
          children: const [
            Flexible(
              child: Icon(Icons.add, color: Colors.lightBlue, size: 30, ),
            ),
            Flexible(
              child: Text("Add New Playlist",
              style: TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              flex: 4,
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
  void changePlayerControlsWidgetVisibility(){
    //Notify the framework that the internal state of this object has changed.
    setState((){
      _isPlayerControlsWidgetVisible = !_isPlayerControlsWidgetVisible;
    });
  }

  void showToast(BuildContext context, String displayName) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text('play $displayName', textAlign: TextAlign.center, style: const TextStyle(color: Colors.lightBlue, fontSize: 14)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0)),
      ),
    );
  }

  String nameWithoutExtension(String fullName){
    return fullName.split(".m").first.toString();
  }

  List<AudioSource> addAudioFromLocal(){
    List<AudioSource> res = [];
    for(int i = 0; i < songs.length; i++){
      res.add(AudioSource.uri(Uri.parse(songs[i].uri!)));
    }
    return res;
  }

  void newPlaylistDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          title: const Text("New Playlist"),
          content: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: TextFormField(
                controller: _controller, //will help get the field value on submit
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Playlist Name',
                ),
                //validator on submit, must return null when every thing ok
                //the validator receives the text that the user has entered
                validator: (value){
                  if (value == null || value.isEmpty){
                    return 'playlist name cannot be empty';
                  } else if (value.trim().isEmpty){
                    return 'playlist name cannot be empty';
                  }
                  return null;
                }
              )
            ),
            
          ),
          actions: [
            //Cancel btn
            TextButton(
                child: const Text('Cancel'),
                onPressed: (){
                  Navigator.of(context).pop(); //dismiss dialog
                }
            ),
            //Create btn
            TextButton(
              child: const Text('Create'),
              onPressed: (){
                //validate returns true of the form is valid, or false otherwise
                if (_formKey.currentState!.validate()){
                  //use put to add a key-value map
                  List<SongModel> playlistSongs = List.empty(growable: true);
                  String playlistName = _controller.text;
                  var playlist = Playlist()
                    ..name =  playlistName;
                  Hive.box(_playlists).put(playlistName, playlist);
                  _controller.clear(); // clear text in field
                  showToast(context, "playlist $playlistName is created");
                  Navigator.of(context).pop(); //dismiss dialog
                }

              }
            ),

          ],
        );
      });
  }

  Widget playlistRowItem(dynamic playlist) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      height: 110,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.indigo[400],
        border: Border.all(width: 1, color: Colors.white70),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Container(
              alignment: Alignment.center,
              height: 40,
              width: 40,
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: const Icon(
                Icons.add_box_outlined,
                size: 20,
              ),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(5)),
                color: const Color(0XFFe5cec6),
                shape: BoxShape.rectangle,
                boxShadow:[
                  BoxShadow(
                    offset: -const Offset(4,4),
                    color: const Color(0xffffffff),
                    blurRadius: 4.0,
                    spreadRadius: 4.0,
                  ),
                  const BoxShadow(
                    offset: Offset(4,4),
                    color: Color(0xFF170b35),
                    blurRadius: 4.0,
                    spreadRadius: 4.0,
                  ),
                ],
              ),
            ),
          ),
          Flexible(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text("$count songs", style: const  TextStyle(color: Colors.white60, fontSize:15, fontWeight: FontWeight.normal)),
              ]
            ),

          ),
          // Flexible(
          //     child: Row(
          //       mainAxisAlignment: MainAxisAlignment.end,
          //       children: [
          //         //edit btn
          //         InkWell(
          //           onTap:(){
          //
          //           }
          //         )
          //       ]
          //     )
          // ),
        ],
      )
    );
  }
}

//position and duration state class
class PositionDurationState{
  Duration position, duration;
  //constructor
  PositionDurationState({this.position = Duration.zero, this.duration = Duration.zero});
}

@HiveType(typeId: 0)
class Playlist extends HiveObject {
  @HiveField(0)
  String name = "";

  @HiveField(1)
  List<SongModel> playlistSongs = List.empty(growable: true);
}




