import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:rxdart/rxdart.dart';

class PlayerControls extends StatelessWidget {
  final AudioPlayer player;
  final List<SongModel> songs;
  final Function callbackFunction;
  //player position and current playing song duration state stream
  Stream<PositionDurationState> get _positionDurationStateStream =>
      Rx.combineLatest2<Duration, Duration?, PositionDurationState>(
          player.positionStream,
          player.durationStream,
          (position, duration) => PositionDurationState(
              position: position, duration: duration ?? Duration.zero));

  PlayerControls(this.player, this.songs, this.callbackFunction, {super.key});

  @override
  Widget build(BuildContext context) {
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
                    onTap: changePlayerControlsWidgetVisibility,
                    //hides the player view
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white70,
                    ),
                  ),
                  InkWell(
                    onTap: changePlayerControlsWidgetVisibility,
                    //hides the player view
                    child: const Icon(
                      Icons.favorite_border_outlined,
                      color: Colors.white70,
                    ),
                  )
                ],
              ),
              //artwork container
              Container(
                  width: double.infinity,
                  height: 300,
                  margin: const EdgeInsets.only(top: 30, bottom: 30),
                  child: StreamBuilder<int?>(
                      stream: player.currentIndexStream,
                      builder: (context, snapshot) {
                        final currentIndex = snapshot.data;
                        if (currentIndex != null) {
                          return QueryArtworkWidget(
                            id: songs[currentIndex].id,
                            type: ArtworkType.AUDIO,
                            artworkBorder: BorderRadius.circular(4.0),
                          );
                        }
                        return const CircularProgressIndicator();
                      })),
              //current song title container, the palying song
              Container(
                  width: double.infinity,
                  height: 50,
                  margin: const EdgeInsets.only(top: 30, bottom: 30),
                  child: StreamBuilder<int?>(
                      stream: player.currentIndexStream,
                      builder: (context, snapshot) {
                        final currentIndex = snapshot.data;
                        if (currentIndex != null) {
                          return Text(
                              nameWithoutExtension(
                                  songs[currentIndex].displayName),
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold));
                        }
                        return const Text('');
                      })),
              //seek bar, current position and total song duration
              Container(
                  padding: EdgeInsets.zero,
                  margin: const EdgeInsets.only(bottom: 4.0),
                  // width: double.infinity,
                  // height: 48.0,
                  //slider bar duration state stream
                  child: StreamBuilder<PositionDurationState>(
                      stream: _positionDurationStateStream,
                      builder: (context, snapshot) {
                        final positionDurationState = snapshot.data;
                        final progress =
                            positionDurationState?.position ?? Duration.zero;
                        final duration =
                            positionDurationState?.duration ?? Duration.zero;

                        return ProgressBar(
                          progress: progress,
                          total: duration,
                          baseBarColor: const Color(0xEE9E9E9E),
                          progressBarColor: Colors.blue[50],
                          thumbColor: Colors.white60.withBlue(99),
                          timeLabelTextStyle: const TextStyle(
                            color: Color(0xEE9E9E9E),
                          ),
                          onSeek: (duration) {
                            player.seek(duration);
                          },
                        );
                      })),

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
                          onTap: () {
                            //player.loopMode == LoopMode.one? _player.setLoopMode(LoopMode.all): _player.setLoopMode(LoopMode.one);
                            final loopMode = player.loopMode;
                            final shuffle = player.shuffleModeEnabled;
                            //change to loop one mode
                            if (LoopMode.all == loopMode && !shuffle) {
                              player.setLoopMode(LoopMode.one);
                              //change to shuffle mode
                            } else if (LoopMode.one == loopMode && !shuffle) {
                              player.setLoopMode(LoopMode.all);
                              player.setShuffleModeEnabled(true);
                            } else {
                              //change to loop all (no shuffle) mode
                              player.setLoopMode(LoopMode.all);
                              player.setShuffleModeEnabled(false);
                            }
                          },
                          child: StreamBuilder<LoopMode>(
                              stream: player.loopModeStream,
                              builder: (context, snapshot) {
                                final loopMode = snapshot.data;
                                final shuffle = player.shuffleModeEnabled;
                                if (LoopMode.all == loopMode && !shuffle) {
                                  return const Icon(
                                    Icons.repeat,
                                    color: Colors.white70,
                                  );
                                } else if (LoopMode.one == loopMode &&
                                    !shuffle) {
                                  return const Icon(
                                    Icons.repeat_one,
                                    color: Colors.white70,
                                  );
                                } else if (LoopMode.all == loopMode &&
                                    shuffle) {
                                  return const Icon(
                                    Icons.shuffle,
                                    color: Colors.white70,
                                  );
                                }
                                return const Icon(
                                  Icons.shuffle_sharp,
                                  color: Colors.white70,
                                );
                              }),
                        ),

                        //skip to prev
                        InkWell(
                          onTap: () {
                            if (player.hasPrevious) {
                              player.seekToPrevious();
                            }
                          },
                          child: const Icon(
                            Icons.skip_previous,
                            color: Colors.white70,
                            size: 30,
                          ),
                        ),

                        InkWell(
                            onTap: () {
                              if (player.playing) {
                                player.pause();
                              } else {
                                if (player.currentIndex != null) {
                                  player.play();
                                }
                              }
                            },
                            child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.white24,
                                      width: 1,
                                      style: BorderStyle.solid),
                                  shape: BoxShape.circle,
                                ),
                                child: StreamBuilder<bool>(
                                    stream: player.playingStream,
                                    builder: (context, snapshot) {
                                      bool? playingState = snapshot.data;
                                      if (playingState != null &&
                                          playingState) {
                                        return const Icon(
                                          Icons.pause,
                                          size: 36,
                                          color: Colors.white70,
                                        );
                                      }
                                      return const Icon(
                                        Icons.play_arrow,
                                        size: 36,
                                        color: Colors.white70,
                                      );
                                    }))),

                        //skipNext
                        InkWell(
                          onTap: () {
                            if (player.hasNext) {
                              player.seekToNext();
                            }
                          },
                          child: const Icon(
                            Icons.skip_next,
                            color: Colors.white70,
                            size: 30,
                          ),
                        ),

                        //go to playList
                        InkWell(
                          onTap: () {
                            changePlayerControlsWidgetVisibility();
                          },
                          child: const Icon(
                            Icons.playlist_play,
                            color: Colors.white70,
                          ),
                        ),
                      ])),
            ],
          )),
    );
  }

  //player widget visibility
  void changePlayerControlsWidgetVisibility() {
    //Notify the framework that the internal state of this object has changed.
    callbackFunction();
  }

  String nameWithoutExtension(String fullName) {
    return fullName.split(".m").first.toString();
  }
}

class PositionDurationState {
  Duration position, duration;
  //constructor
  PositionDurationState(
      {this.position = Duration.zero, this.duration = Duration.zero});
}
