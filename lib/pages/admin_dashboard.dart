import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pop_media/models/report.dart';
import 'package:pop_media/pages/login_page.dart';
import 'package:pop_media/service/data_service.dart';
import 'package:pop_media/session/user_session.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/widgets/comic_title.dart';
import 'package:pop_media/widgets/report_card.dart';
import 'package:provider/provider.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<Report> _reports = [];
  bool _showResolved = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final reports = await DataService.getReport(resolved: _showResolved);
      if (!mounted) return;
      setState(() {
        _reports = reports;
      });
    } catch (e) {
      print("Error loading reports: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reloadReports(Report report) async {
    try {
      if (!mounted) return;
      setState(() {
        _reports.removeWhere((r) => r.issue_id == report.issue_id);
      });
    } catch (e) {
      print("Error resolving report: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>().currentTheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: theme.topBarColor,
        centerTitle: true,
        title: Image.asset(theme.logo, height: 60, fit: BoxFit.contain),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () async {
              UserSession.clear();
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginPage()),
              );
            },
            child: ComicTitle(title: "Logout"),
          ),
        ],
      ),
      body: Stack(
      children: [
        Positioned.fill(
          child: theme.mainBackgroundImage != null
              ? Opacity(
                  opacity: theme.imageOpactity,
                  child: Image.asset(
                    theme.mainBackgroundImage!,
                    fit: BoxFit.cover,
                  ),
                )
              : Container(color: theme.mainBackgroundColor),
        ),
        SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenHeight),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      ComicTitle(title: "Admin Dashboard"),
                      Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showResolved = !_showResolved;
                          });
                          _loadReports();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(color: Colors.red, width: 4),
                          ),
                        ),
                        child: Text(
                          _showResolved ? "Show Unresolved" : "Show Resolved",
                          style: TextStyle(
                            fontFamily: theme.fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _reports.isEmpty
                          ? const Center(child: Text("No reports found"))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (var report in _reports) ...[
                                  ReportCard(
                                    report: report,
                                    onResolved: () => _reloadReports(report),
                                  ),
                                  SizedBox(height: 10),
                                ],
                              ],
                            ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
    );
  }
}