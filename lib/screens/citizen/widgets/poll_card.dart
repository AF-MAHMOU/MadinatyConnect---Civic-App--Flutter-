import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/app_localizations.dart';
import '../../../utils/app_theme.dart';

class PollCard extends StatefulWidget {
  final String question;
  final List<String> options;
  final String pollId;

  PollCard({
    required this.question,
    required this.options,
    required this.pollId,
  });

  @override
  _PollCardState createState() => _PollCardState();
}

class _PollCardState extends State<PollCard> {
  String? _userVote;

  @override
  void initState() {
    super.initState();
    _loadUserVote();
  }

  Future<void> _loadUserVote() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final voteDoc = await FirebaseFirestore.instance
          .collection('polls')
          .doc(widget.pollId)
          .collection('votes')
          .doc(userId)
          .get();

      if (voteDoc.exists) {
        setState(() {
          _userVote = voteDoc.data()?['option'];
        });
      }
    }
  }

  Future<void> _vote(String option) async {
    final localizations = AppLocalizations.of(context);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('please_login_to_vote')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check user role first
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists || userDoc.data()?['role'] != 'citizen') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('only_citizens_can_vote')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Add or update the vote
      await FirebaseFirestore.instance
          .collection('polls')
          .doc(widget.pollId)
          .collection('votes')
          .doc(userId)
          .set({
        'option': option,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _userVote = option;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_userVote == null 
            ? localizations.translate('vote_success')
            : localizations.translate('vote_updated')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localizations.translate('vote_error')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withOpacity(isDarkMode ? 0.2 : 0.1),
                  Colors.transparent
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(isDarkMode ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.poll, color: AppTheme.primaryBlue),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.question,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppTheme.darkGrey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Options
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: widget.options.map((option) {
                final isSelected = option == _userVote;
                return Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: ElevatedButton(
                    onPressed: () => _vote(option),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected 
                        ? AppTheme.primaryBlue.withOpacity(isDarkMode ? 0.3 : 0.2)
                        : AppTheme.primaryBlue.withOpacity(isDarkMode ? 0.1 : 0.05),
                      foregroundColor: isSelected 
                        ? AppTheme.primaryBlue
                        : (isDarkMode ? Colors.white70 : AppTheme.primaryBlue),
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle : Icons.check_circle_outline,
                          color: isSelected ? AppTheme.primaryBlue : null,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Results
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('polls')
                .doc(widget.pollId)
                .collection('votes')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return LinearProgressIndicator();

              final totalVotes = snapshot.data!.docs.length;
              final votesMap = <String, int>{};

              for (var doc in snapshot.data!.docs) {
                final option = doc['option'];
                votesMap[option] = (votesMap[option] ?? 0) + 1;
              }

              return Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bar_chart, size: 16, color: isDarkMode ? Colors.white70 : AppTheme.mediumGrey),
                        SizedBox(width: 8),
                        Text(
                          localizations.translate('poll_results'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white70 : AppTheme.mediumGrey,
                          ),
                        ),
                        Spacer(),
                        Text(
                          '$totalVotes ${localizations.translate('votes')}',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : AppTheme.mediumGrey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    ...votesMap.entries.map(
                      (entry) => PollResultRow(
                        option: entry.key,
                        count: entry.value,
                        total: totalVotes,
                        isSelected: entry.key == _userVote,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class PollResultRow extends StatelessWidget {
  final String option;
  final int count;
  final int total;
  final bool isSelected;

  PollResultRow({
    required this.option,
    required this.count,
    required this.total,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total == 0 ? 0.0 : count / total;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : AppTheme.darkGrey,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${(percentage * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : AppTheme.mediumGrey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                height: 8,
                width: MediaQuery.of(context).size.width * 0.7 * percentage,
                decoration: BoxDecoration(
                  color: isSelected 
                    ? AppTheme.primaryBlue.withOpacity(isDarkMode ? 0.7 : 0.5)
                    : AppTheme.primaryBlue.withOpacity(isDarkMode ? 0.4 : 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
