import 'package:flutter/material.dart';
import '../services/tarot_service.dart';
import 'tarot_reading_screen.dart';
import 'tarot_history_screen.dart';
import 'tarot_library_screen.dart';
import 'astro_tarot_form_screen.dart';

class TarotDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tarot'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TarotHistoryScreen())),
          ),
          IconButton(
            icon: Icon(Icons.library_books),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TarotLibraryScreen())),
          )
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildCard(context, 'Daily Card', Icons.today, () => _openDaily(context)),
          _buildCard(context, 'Single Card', Icons.filter_1, () => _openSpread(context, 'single')),
          _buildCard(context, 'Three Card', Icons.filter_3, () => _openSpread(context, 'three-card')),
          _buildCard(context, 'Yes / No', Icons.thumbs_up_down, () => _openSpread(context, 'yes-no')),
          _buildCard(context, 'Love', Icons.favorite, () => _openSpread(context, 'love')),
          _buildCard(context, 'Career', Icons.work, () => _openSpread(context, 'career')),
          _buildCard(context, 'Celtic Cross', Icons.api, () => _openSpread(context, 'celtic-cross')),
          _buildCard(context, 'Year Ahead', Icons.calendar_month, () => _openSpread(context, 'year-ahead')),
          _buildCard(context, 'Astro-Tarot', Icons.star, () => Navigator.push(context, MaterialPageRoute(builder: (_) => AstroTarotFormScreen()))),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).primaryColor),
            SizedBox(height: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  void _openDaily(BuildContext context) async {
    try {
      showDialog(context: context, builder: (_) => Center(child: CircularProgressIndicator()));
      final tzOffset = DateTime.now().timeZoneOffset.inHours.toDouble();
      final reading = await TarotService().getDailyReading(tzOffset);
      Navigator.pop(context); // close dialog
      
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => TarotReadingScreen(spreadData: {
          'spread_type': 'Daily',
          'positions': [
            {'position_name': 'Daily Insight', 'card': reading['reading']}
          ]
        })
      ));
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _openSpread(BuildContext context, String endpoint) async {
    try {
      showDialog(context: context, builder: (_) => Center(child: CircularProgressIndicator()));
      final reading = await TarotService().drawSpread(endpoint, question: "General Reading");
      Navigator.pop(context); // close dialog
      
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => TarotReadingScreen(spreadData: reading)
      ));
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
