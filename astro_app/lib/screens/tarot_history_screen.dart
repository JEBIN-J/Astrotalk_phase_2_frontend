import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/tarot_service.dart';
import 'tarot_reading_screen.dart';

class TarotHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reading History')),
      body: FutureBuilder<List<dynamic>>(
        future: TarotService().getHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final records = snapshot.data ?? [];
          if (records.isEmpty) {
            return Center(child: Text('No previous readings found.'));
          }

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return ListTile(
                leading: Icon(Icons.history, color: Theme.of(context).primaryColor),
                title: Text('${record['reading_type']}'),
                subtitle: Text('Date: ${record['created_at'].toString().split('T')[0]}'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  final spreadData = jsonDecode(record['spread_data']);
                  if (record['astrology_snapshot'] != null) {
                    spreadData['astro_snapshot'] = jsonDecode(record['astrology_snapshot']);
                  }
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => TarotReadingScreen(spreadData: spreadData)
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}
