import 'package:flutter/material.dart';

class BadmintonScoreScreen extends StatefulWidget {
  const BadmintonScoreScreen({super.key});

  @override
  State<BadmintonScoreScreen> createState() => _BadmintonScoreScreenState();
}

class _BadmintonScoreScreenState extends State<BadmintonScoreScreen> {
  int scoreA = 0;
  int scoreB = 0;
  bool serverIsA = true;

  // Đội A (Dưới): Điểm chẵn bên phải màn hình, lẻ bên trái màn hình.
  // Đội B (Trên): Điểm chẵn bên trái màn hình (là bên phải của họ), lẻ bên phải màn hình.
  int get positionA => scoreA % 2 == 0 ? 1 : 0; // 1: Phải, 0: Trái
  int get positionB => scoreB % 2 == 0 ? 0 : 1; // 0: Trái (của màn hình), 1: Phải (của màn hình)

  void _incrementA() {
    setState(() {
      scoreA++;
      serverIsA = true;
    });
  }

  void _decrementA() {
    if (scoreA > 0) {
      setState(() {
        scoreA--;
      });
    }
  }

  void _incrementB() {
    setState(() {
      scoreB++;
      serverIsA = false;
    });
  }

  void _decrementB() {
    if (scoreB > 0) {
      setState(() {
        scoreB--;
      });
    }
  }

  void _reset() {
    setState(() {
      scoreA = 0;
      scoreB = 0;
      serverIsA = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tính điểm Cầu lông"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _reset, icon: const Icon(Icons.refresh))
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Bảng điểm
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildScoreColumn("Đội A", scoreA, Colors.blue, _incrementA, _decrementA, serverIsA),
              _buildScoreColumn("Đội B", scoreB, Colors.red, _incrementB, _decrementB, !serverIsA),
            ],
          ),
          const SizedBox(height: 40),
          // Sân cầu lông
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green[700],
                border: Border.all(color: Colors.white, width: 4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Nửa sân B (Trên)
                  Expanded(
                    child: Stack(
                      children: [
                        _buildCourtLines(),
                        // Người chơi B
                        AnimatedAlign(
                          duration: const Duration(milliseconds: 300),
                          // positionB == 0 (chẵn) -> Trái màn hình (phải của B)
                          // positionB == 1 (lẻ) -> Phải màn hình (trái của B)
                          alignment: positionB == 0 ? const Alignment(-0.5, 0.5) : const Alignment(0.5, 0.5),
                          child: _buildPlayerIcon(Colors.red, !serverIsA),
                        ),
                      ],
                    ),
                  ),
                  // Lưới
                  Container(height: 4, color: Colors.white.withOpacity(0.8)),
                  // Nửa sân A (Dưới)
                  Expanded(
                    child: Stack(
                      children: [
                        _buildCourtLines(),
                        // Người chơi A
                        AnimatedAlign(
                          duration: const Duration(milliseconds: 300),
                          // positionA == 1 (chẵn) -> Phải màn hình (phải của A)
                          // positionA == 0 (lẻ) -> Trái màn hình (trái của A)
                          alignment: positionA == 1 ? const Alignment(0.5, -0.5) : const Alignment(-0.5, -0.5),
                          child: _buildPlayerIcon(Colors.blue, serverIsA),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              "Luật: Giao bóng bên phải khi điểm chẵn, bên trái khi điểm lẻ (theo góc nhìn của người chơi).",
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreColumn(String team, int score, Color color, VoidCallback onAdd, VoidCallback onSub, bool isServing) {
    return Column(
      children: [
        Row(
          children: [
            if (isServing) const Icon(Icons.star, color: Colors.amber, size: 18),
            const SizedBox(width: 4),
            Text(team, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 10),
        Text("$score", style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold)),
        Row(
          children: [
            IconButton(
              onPressed: onSub,
              icon: const Icon(Icons.remove_circle_outline, size: 35),
              color: Colors.grey,
            ),
            IconButton(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle, size: 50),
              color: color,
            ),
          ],
        )
      ],
    );
  }

  Widget _buildCourtLines() {
    return Row(
      children: [
        Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white.withOpacity(0.5))))),
        Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white.withOpacity(0.5))))),
      ],
    );
  }

  Widget _buildPlayerIcon(Color color, bool hasShuttle) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasShuttle) const Icon(Icons.sports_tennis, color: Colors.white, size: 16),
        Icon(Icons.person_pin, size: 50, color: color),
      ],
    );
  }
}
