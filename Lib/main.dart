import 'package:flutter/material.dart';
import 'package:apivideo_live_stream/apivideo_live_stream.dart';

void main() {
  runApp(const CricketLiveApp());
}

class CricketLiveApp extends StatelessWidget {
  const CricketLiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cricket Live Streamer',
      theme: ThemeData.dark(),
      home: const LiveStreamScreen(),
    );
  }
}

class LiveStreamScreen extends StatefulWidget {
  const LiveStreamScreen({super.key});

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  late ApiVideoLiveStreamController _controller;
  bool _isStreaming = false;

  final TextEditingController _rtmpUrlController = TextEditingController(
    text: "rtmps://live-api-s.facebook.com:443/rtmp/",
  );
  final TextEditingController _streamKeyController = TextEditingController();

  int runs = 0;
  int wickets = 0;
  int overs = 0;
  int balls = 0;
  String teamA = "Team A";
  String teamB = "Team B";

  void updateScore(int runChange, bool isWicket, bool isBall) {
    setState(() {
      runs += runChange;
      if (isWicket && wickets < 10) wickets++;
      if (isBall) {
        balls++;
        if (balls == 6) {
          overs++;
          balls = 0;
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = ApiVideoLiveStreamController(
      initialAudioConfig: AudioConfig(),
      initialVideoConfig: VideoConfig.withBackupWithAudio(
        bitrate: 3000000,
        fps: 30,
        resolution: Resolution.RESOLUTION_720,
      ),
      onConnectionSuccess: () {
        setState(() => _isStreaming = true);
      },
      onConnectionFailed: (error) {
        setState(() => _isStreaming = false);
      },
      onDisconnection: () {
        setState(() => _isStreaming = false);
      },
    );
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleStreaming() async {
    if (_isStreaming) {
      await _controller.stopStreaming();
      setState(() => _isStreaming = false);
    } else {
      if (_streamKeyController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("برائے مہربانی Facebook Stream Key درج کریں")),
        );
        return;
      }
      await _controller.startStreaming(
        streamKey: _streamKeyController.text,
        url: _rtmpUrlController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ApiVideoCameraPreview(controller: _controller),
          Positioned(
            top: 40,
            left: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.yellow, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$teamA vs $teamB",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    color: Colors.yellow,
                    child: Text(
                      "$runs / $wickets",
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  Text(
                    "Overs: $overs.$balls",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 10,
            right: 10,
            child: Column(
              children: [
                if (!_isStreaming)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: _streamKeyController,
                      decoration: const InputDecoration(
                        hintText: "Paste Facebook Stream Key Here",
                        filled: true,
                        fillColor: Colors.black87,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ElevatedButton(
                  onPressed: _toggleStreaming,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isStreaming ? Colors.red : Colors.green,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  child: Text(_isStreaming ? "STOP LIVE" : "START FACEBOOK LIVE"),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _scoreBtn("0", () => updateScore(0, false, true)),
                    _scoreBtn("+1", () => updateScore(1, false, true)),
                    _scoreBtn("+2", () => updateScore(2, false, true)),
                    _scoreBtn("+4", () => updateScore(4, false, true)),
                    _scoreBtn("+6", () => updateScore(6, false, true)),
                    _scoreBtn("W", () => updateScore(0, true, true), color: Colors.red),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreBtn(String label, VoidCallback onPressed, {Color color = Colors.blue}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(40, 40),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}
