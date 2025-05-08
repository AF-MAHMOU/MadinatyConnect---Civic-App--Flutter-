import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/dark_mode_helper.dart';

class EmergencyScreen extends StatelessWidget {
  final emergencyNumbers = {
    'Police': '122',
    'Ambulance': '123',
    'Fire Department': '180',
  };

  @override
  Widget build(BuildContext context) {
    return DarkModeHelper.addDarkModeToggle(
      Scaffold(
        appBar: AppBar(title: Text('Emergency Numbers')),
        body: ListView(
          children:
              emergencyNumbers.entries.map((entry) {
                return ListTile(
                  title: Text(entry.key),
                  subtitle: Text(entry.value),
                  trailing: IconButton(
                    icon: Icon(Icons.call),
                    onPressed: () => launch('tel:${entry.value}'),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}
