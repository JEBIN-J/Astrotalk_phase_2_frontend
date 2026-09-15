import 'package:flutter/material.dart';
import '../services/tarot_service.dart';
import 'tarot_reading_screen.dart';

class AstroTarotFormScreen extends StatefulWidget {
  @override
  _AstroTarotFormScreenState createState() => _AstroTarotFormScreenState();
}

class _AstroTarotFormScreenState extends State<AstroTarotFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _question = '';
  String _birthDate = '';
  String _birthTime = '';
  String _latitude = '';
  String _longitude = '';
  String _timezone = '';

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      showDialog(context: context, builder: (_) => Center(child: CircularProgressIndicator()));
      
      try {
        final payload = {
          'question': _question,
          'birth_date': _birthDate,
          'birth_time': _birthTime,
          'latitude': double.parse(_latitude),
          'longitude': double.parse(_longitude),
          'timezone': double.parse(_timezone),
        };
        
        final reading = await TarotService().getAstroTarotReading(payload);
        
        Navigator.pop(context); // close dialog
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => TarotReadingScreen(spreadData: reading['tarot_spread']..['astro_snapshot'] = {
            'natal': reading['natal_snapshot'],
            'transit': reading['transit_snapshot']
          })
        ));
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Astro-Tarot Reading')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter Birth Details for Astrological Overlay',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Question (Optional)', border: OutlineInputBorder()),
                onSaved: (v) => _question = v ?? '',
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Birth Date (YYYY-MM-DD)', border: OutlineInputBorder(), hintText: '1990-05-15'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => _birthDate = v!,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Birth Time (HH:MM)', border: OutlineInputBorder(), hintText: '14:30'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => _birthTime = v!,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Latitude', border: OutlineInputBorder(), hintText: '28.6139'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                      onSaved: (v) => _latitude = v!,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Longitude', border: OutlineInputBorder(), hintText: '77.2090'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                      onSaved: (v) => _longitude = v!,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Timezone Offset (e.g., 5.5 for IST)', border: OutlineInputBorder(), hintText: '5.5'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => _timezone = v!,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Generate Astro-Tarot Reading', style: TextStyle(fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
