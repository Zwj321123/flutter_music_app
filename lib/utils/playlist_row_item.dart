import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../data/database.dart';

const _playlists = "playlists";

class PlaylistRowItem extends StatelessWidget {
  final String name;
  final int count;
  final PlaylistDataBase db;
  const PlaylistRowItem(this.name, this.count, this.db, {super.key});

  @override
  Widget build(BuildContext context) {
    int playlistLen = (Hive.box(_playlists).get(name) != null)
        ? Hive.box(_playlists).get(name).length
        : -1;
    return Container(
        margin: const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
        padding:
            const EdgeInsets.only(top: 20.0, bottom: 20.0, right: 5, left: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(
              color: Colors.white70, width: 1.0, style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Flexible(
            //   child: Container(
            //     alignment: Alignment.center,
            //     height: 40,
            //     width: 40,
            //     padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
            //     margin: const EdgeInsets.symmetric(vertical: 5),
            //     child: const Icon(
            //       Icons.add_box_sharp,
            //       color: Colors.white60,
            //       size: 20,
            //     ),
            //   ),
            // ),
            Flexible(
              flex: 2,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Center(
                      child: Text("$playlistLen songs",
                          style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 15,
                              fontWeight: FontWeight.normal)),
                    ),
                  ]),
            ),
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  //Edit btn
                  InkWell(
                    onTap: () {
                      //edit btn clicked
                      showToast(context, "Edit the playlist $name");
                    },
                    child: Container(
                      alignment: Alignment.center,
                      height: 40,
                      padding: const EdgeInsets.symmetric(
                          vertical: 1, horizontal: 10),
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white60,
                        size: 20,
                      ),
                    ),
                  ),
                  //delete btn
                  InkWell(
                      onTap: () {
                        //delete btn clicked
                        deletePlayListItem(context, name);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        height: 40,
                        padding: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 8),
                        margin: const EdgeInsets.only(
                            top: 10, bottom: 10, left: 10),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white60,
                          size: 20,
                        ),
                      )),
                ],
              ),
            ),
          ],
        ));
  }

  //delete a shopping item from the shopping box
  void deletePlayListItem(BuildContext context, String item) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Are You Sure ??"),
            content: Text("Confirm to remove playlist \"$item\""),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // dismiss dialog
                  },
                  child: const Text("Cancel")),
              TextButton(
                child: const Text("Remove"),
                onPressed: () {
                  if (item != "Favorite") {
                    db.deleteItem(item);
                  } else {
                    showToast(context, "You cannot delete this playlist!");
                  }
                  Navigator.of(context).pop(); // dismiss dialog
                },
              ),
            ],
          );
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
}
