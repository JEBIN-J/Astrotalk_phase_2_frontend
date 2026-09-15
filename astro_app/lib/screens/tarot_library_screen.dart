import 'package:flutter/material.dart';
import '../services/tarot_service.dart';

class TarotLibraryScreen extends StatefulWidget {
  @override
  _TarotLibraryScreenState createState() => _TarotLibraryScreenState();
}

class _TarotLibraryScreenState extends State<TarotLibraryScreen> {
  List<dynamic> _allCards = [];
  List<dynamic> _filteredCards = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterArcana = 'All';

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  void _loadCards() async {
    try {
      final cards = await TarotService().getLibrary();
      setState(() {
        _allCards = cards;
        _filteredCards = cards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading library: $e')));
    }
  }

  void _filterCards() {
    setState(() {
      _filteredCards = _allCards.where((card) {
        final matchesSearch = card['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) || 
                              (card['keywords_upright'] as List).join(' ').toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesArcana = _filterArcana == 'All' || card['arcana'] == _filterArcana || card['suit'] == _filterArcana;
        return matchesSearch && matchesArcana;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tarot Library')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search by Name or Keyword',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      _searchQuery = val;
                      _filterCards();
                    },
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Major', 'Minor', 'Wands', 'Cups', 'Swords', 'Pentacles'].map((f) => 
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: _filterArcana == f,
                          onSelected: (selected) {
                            if (selected) {
                              _filterArcana = f;
                              _filterCards();
                            }
                          },
                        ),
                      )
                    ).toList(),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredCards.length,
                    itemBuilder: (context, index) {
                      final card = _filteredCards[index];
                      return ExpansionTile(
                        title: Text(card['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${card['arcana']} Arcana ${card['suit'] != null ? '- ' + card['suit'] : ''}'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Upright: ${card['meaning_upright']}'),
                                SizedBox(height: 8),
                                Text('Reversed: ${card['meaning_reversed']}'),
                                SizedBox(height: 8),
                                Text('Keywords: ${(card['keywords_upright'] as List).join(', ')}'),
                                SizedBox(height: 8),
                                Text('Element: ${card['element']} | Astro: ${card['astrological_correspondence']}'),
                              ],
                            ),
                          )
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
