import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

class SongsListView extends StatelessWidget{
  final OnAudioQuery audioQuery;
  List<SongModel> songs;
  AudioSource mainPlayList;
  final AudioPlayer _player;
  SongsListView(this.audioQuery, this.songs, this.mainPlayList, this._player, {super.key});

  @override
  Widget build(BuildContext context) {
    //use future builder to create a list view with songs
    return FutureBuilder<List<SongModel>>(
      future: audioQuery.querySongs(
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


  List<AudioSource> addAudioFromLocal(){
    List<AudioSource> res = [];
    for(int i = 0; i < songs.length; i++){
      res.add(AudioSource.uri(Uri.parse(songs[i].uri!)));
    }
    return res;
  }

}