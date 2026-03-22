import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LobbyScreen extends StatefulWidget {
  final String roomId;
  final String userName;

  const LobbyScreen({super.key, required this.roomId, required this.userName});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {

  final TextEditingController chatController = TextEditingController();

  String selectedTeam = "";

  List<String> teams = [
    "MI",
    "CSK",
    "RCB",
    "GT",
    "RR",
    "SRH",
    "KKR",
    "LSG",
    "PBKS",
    "DC"
  ];

  void joinTeam(String team) async {
    setState(() {
      selectedTeam = team;
    });

    await FirebaseFirestore.instance
        .collection("rooms")
        .doc(widget.roomId)
        .collection("players")
        .doc(widget.userName)
        .set({
      "name": widget.userName,
      "team": team,
      "purse": 100000000
    });

    await FirebaseFirestore.instance
        .collection("rooms")
        .doc(widget.roomId)
        .collection("chat")
        .add({
      "message": "<$team> ${widget.userName} joined room",
      "time": FieldValue.serverTimestamp()
    });
  }

  void sendMessage() async {

    if (chatController.text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection("rooms")
        .doc(widget.roomId)
        .collection("chat")
        .add({
      "message": "<$selectedTeam> ${widget.userName}: ${chatController.text}",
      "time": FieldValue.serverTimestamp()
    });

    chatController.clear();
  }

  void startAuction() async {

    await FirebaseFirestore.instance
        .collection("rooms")
        .doc(widget.roomId)
        .update({
      "status": "auction"
    });

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.black,

      appBar: AppBar(
        title: Text("Room: ${widget.roomId}"),
        backgroundColor: Colors.red,
      ),

      body: Column(
        children: [

          const SizedBox(height: 10),

          const Text(
            "Select Your Team",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),

          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: teams.length,
              itemBuilder: (context, index) {

                String team = teams[index];

                return GestureDetector(
                  onTap: () => joinTeam(team),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selectedTeam == team
                          ? Colors.green
                          : Colors.grey[800],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      team,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(color: Colors.white),

          const Text(
            "Players Joined",
            style: TextStyle(color: Colors.white),
          ),

          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("rooms")
                  .doc(widget.roomId)
                  .collection("players")
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var players = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {

                    var data = players[index];

                    return ListTile(
                      title: Text(
                        "<${data["team"]}> ${data["name"]}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const Divider(color: Colors.white),

          const Text(
            "Chat",
            style: TextStyle(color: Colors.white),
          ),

          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("rooms")
                  .doc(widget.roomId)
                  .collection("chat")
                  .orderBy("time")
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var messages = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {

                    return ListTile(
                      title: Text(
                        messages[index]["message"],
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Row(
            children: [

              Expanded(
                child: TextField(
                  controller: chatController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Message",
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ),

              IconButton(
                onPressed: sendMessage,
                icon: const Icon(Icons.send, color: Colors.white),
              )

            ],
          ),

          ElevatedButton(
            onPressed: startAuction,
            child: const Text("START AUCTION"),
          ),

        ],
      ),
    );
  }
}