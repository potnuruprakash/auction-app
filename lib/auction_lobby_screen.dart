import 'package:flutter/material.dart';

class AuctionLobbyScreen extends StatelessWidget {

  final String userName;
  final String teamName;
  final String auctionMode;

  const AuctionLobbyScreen({
    super.key,
    required this.userName,
    required this.teamName,
    required this.auctionMode,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Auction Lobby"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Text(
              "Room: SLWFND",
              style: TextStyle(color: Colors.orange,fontSize:18),
            ),

            const SizedBox(height:20),

            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "Invite Friends",
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height:30),

            Text(
              "Selected Team: $teamName",
              style: const TextStyle(color: Colors.white),
            ),

            const SizedBox(height:10),

            Text(
              "Auction Mode: $auctionMode",
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height:30),

            const Text(
              "Chat",
              style: TextStyle(color: Colors.white,fontSize:18),
            ),

            const SizedBox(height:10),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height:15),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                onPressed: (){},
                child: const Text("Start Auction"),
              ),
            )

          ],
        ),
      ),
    );
  }
}