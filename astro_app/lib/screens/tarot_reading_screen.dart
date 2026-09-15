import 'package:flutter/material.dart';

class TarotReadingScreen extends StatefulWidget {
  final Map<String, dynamic> spreadData;

  const TarotReadingScreen({Key? key, required this.spreadData}) : super(key: key);

  @override
  _TarotReadingScreenState createState() => _TarotReadingScreenState();
}

class _TarotReadingScreenState extends State<TarotReadingScreen> {
  // To track which cards have been "revealed" by the user tapping on them
  Set<int> _revealedIndices = {};

  @override
  Widget build(BuildContext context) {
    final positions = widget.spreadData['positions'] as List<dynamic>;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.spreadData['spread_type']} Reading'),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: positions.length,
        itemBuilder: (context, index) {
          final pos = positions[index];
          final card = pos['card'];
          final isRevealed = _revealedIndices.contains(index);

          return Card(
            margin: EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () {
                setState(() {
                  _revealedIndices.add(index);
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: isRevealed
                    ? _buildRevealedCard(pos, card)
                    : _buildFaceDownCard(pos['position_name']),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFaceDownCard(String positionName) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.indigo.shade900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber, width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, color: Colors.amber, size: 48),
            SizedBox(height: 16),
            Text(
              positionName,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text('Tap to Reveal', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildRevealedCard(Map<String, dynamic> pos, Map<String, dynamic> card) {
    final astroContext = pos['astro_context'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pos['position_name'],
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).primaryColor),
        ),
        Divider(),
        Text(
          '${card['name']} (${card['orientation']})',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 4,
          children: (card['keywords'] as List<dynamic>).map((k) => Chip(label: Text(k.toString()))).toList(),
        ),
        SizedBox(height: 12),
        Text('Core Meaning', style: TextStyle(fontWeight: FontWeight.w600)),
        Text(card['core_meaning']),
        SizedBox(height: 12),
        Text('Contextual Reading', style: TextStyle(fontWeight: FontWeight.w600)),
        Text(card['context_meaning']),
        
        if (astroContext != null) ...[
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Astro-Tarot Alignment', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                SizedBox(height: 8),
                Text('Correspondence: ${astroContext['correspondence']}'),
                if (astroContext['current_transit'] != null)
                  Text('Current Transit: ${astroContext['current_transit']['planet']} in ${astroContext['current_transit']['sign']} at ${astroContext['current_transit']['degree']}°'),
                if (astroContext['natal_placement'] != null)
                  Text('Natal Placement: ${astroContext['natal_placement']['planet']} in ${astroContext['natal_placement']['sign']} (House ${astroContext['natal_placement']['house']})'),
              ],
            ),
          )
        ]
      ],
    );
  }
}
