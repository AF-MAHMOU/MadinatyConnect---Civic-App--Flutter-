import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../utils/app_localizations.dart';
import 'comment_section.dart'; // Make sure this is created in widgets/

class AnnouncementCard extends StatelessWidget {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final List<dynamic>? attachments;

  AnnouncementCard({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.attachments,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMM yyyy').format(date);
    final localizations = AppLocalizations.of(context);

    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(content),
            SizedBox(height: 8),
            Text(formattedDate, style: TextStyle(color: Colors.grey)),
            if (attachments != null && attachments!.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                localizations.translate('attachments'),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...attachments!.map(
                (url) => TextButton(
                  onPressed: () => launch(url),
                  child: Text(localizations.translate('view_attachment')),
                ),
              ),
            ],
            SizedBox(height: 12),
            CommentSection(announcementId: id),
          ],
        ),
      ),
    );
  }
}
