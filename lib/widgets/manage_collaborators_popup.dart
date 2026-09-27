import 'package:flutter/material.dart' hide Badge;
import 'package:pop_media/service/data_service.dart';
import 'package:pop_media/session/user_session.dart';
import 'package:pop_media/widgets/ajax_search.dart';
import 'package:pop_media/widgets/comic_title.dart';

class ManageCollaboratorsPopup extends StatefulWidget {
  final int pid;

  const ManageCollaboratorsPopup({super.key, required this.pid});

  @override
  State<ManageCollaboratorsPopup> createState() => _ManageCollaboratorsPopupState();
}

class _ManageCollaboratorsPopupState extends State<ManageCollaboratorsPopup> {
  final TextEditingController _nameController = TextEditingController();
  Map<String, dynamic>? _selectedCollaborator;
  String _errorMessage = "";
  bool collaboratorAdded = false;
  List<Map<String, dynamic>> _allCollaborators = [];

  @override
  void initState() {
    super.initState();
    _loadCollaborators();
  }

  Future<void> _loadCollaborators() async {
    final users = await DataService.getCollaborators(widget.pid, true, UserSession.uid!);
    setState(() {
      _allCollaborators = users;
    });
  }

  List<Map<String, dynamic>> _filterUsersFromList(String query) {
    if (query.isEmpty) return _allCollaborators;

    return _allCollaborators.where((user) {
      final username = user['username']?.toLowerCase() ?? '';
      final name = user['name']?.toLowerCase() ?? '';

      return username.contains(query.toLowerCase()) ||
            name.contains(query.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 3),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const ComicTitle(title: 'Manage Collaborators'),
              SizedBox(height: 14),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => _addBuild(),
                      );
                    }, 
                    child: const ComicTitle(title: "Add", size: 16)),
                  TextButton(
                    onPressed: () async {
                      await _loadCollaborators();
                      showDialog(
                        context: context,
                        builder: (context) => _deleteBuild(),
                      );
                    }, 
                    child: const ComicTitle(title: "Delete", size: 16)),
                ]
              ),
              SizedBox(height: 14),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, collaboratorAdded);
                }, 
                child: const ComicTitle(title: "Close", size: 16)
              ),
            ]
          )
        ),
      ),
    );
  }

  Widget _addBuild() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black, width: 3),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const ComicTitle(title: 'Add Collaborators'),
                  SizedBox(height: 14),

                  // --- Title Ajax Search  ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ComicTitle(title: 'User: *', size: 14),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 3),
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.9),
                                Colors.grey.shade200.withOpacity(0.9),
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(3),
                          child: AjaxSearchField(
                            controller: _nameController,
                            hintText: "Username or Name",
                            onSearch: (query) async {
                              try {
                                final userList =
                                    await DataService.discoverSearch(query, 'u');
                                final normalized = userList.map((item) {
                                  final map = Map<String, dynamic>.from(item);
                                  map['image'] = map['image']?.toString() ??
                                      'assets/profile/profile.jpg';
                                  return map;
                                }).toList();

                                return normalized;
                              } catch (e) {
                                print("Error fetching users: $e");
                                return [];
                              }
                            },
                            displayStringForOption: (Map<String, dynamic> user) =>
                                user['username']?.toString() ?? '',
                            onSelected: (Map<String, dynamic> user) {
                              setDialogState(() {
                                _selectedCollaborator = user;
                                _nameController.text =
                                    user['username']?.toString() ?? '';
                                _errorMessage = "";
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),

                  // --- Buttons ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () async {
                          if (_selectedCollaborator == null) {
                            setDialogState(() {
                              _errorMessage = "Please select a user.";
                            });
                            return;
                          }

                          try {
                            final success =
                                await DataService.addCollaboratorToPlaylist(
                              widget.pid,
                              _selectedCollaborator!['uid'],
                            );

                            setDialogState(() {
                              _errorMessage = success
                                  ? "Successfully added. Please select another person or close."
                                  : "Failed to add collaborator.";
                            });

                            if (success) collaboratorAdded = true;
                          } catch (e) {
                            setDialogState(() {
                              _errorMessage = "Error adding collaborator.";
                            });
                          }
                        },
                        child:
                            const ComicTitle(title: "Add", size: 16),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, collaboratorAdded);
                          Navigator.pop(context, collaboratorAdded);
                        },
                        child: const ComicTitle(title: "Close", size: 16),
                      ),
                    ],
                  ),

                  // --- Error message display ---
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _errorMessage,
                        style: _errorMessage.contains("Success") 
                          ? TextStyle(color: Colors.black) 
                          : const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _deleteBuild() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black, width: 3),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const ComicTitle(title: 'Delete Collaborators'),
                  SizedBox(height: 14),

                  // --- AjaxSearch field (same as addBuild) ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ComicTitle(title: 'User: *', size: 14),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 3),
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.9),
                                Colors.grey.shade200.withOpacity(0.9),
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(3),
                          child: AjaxSearchField(
                            controller: _nameController,
                            hintText: "Username or Name",
                            onSearch: (query) async {
                              try {
                                final userList = _filterUsersFromList(query);
                                final normalized = userList.map((item) {
                                  final map = Map<String, dynamic>.from(item);
                                  map['image'] = map['image']?.toString() ??
                                      'assets/profile/profile.jpg';
                                  return map;
                                }).toList();

                                return normalized;
                              } catch (e) {
                                print("Error fetching users: $e");
                                return [];
                              }
                            },
                            displayStringForOption: (Map<String, dynamic> user) =>
                                user['username']?.toString() ?? '',
                            onSelected: (Map<String, dynamic> user) {
                              setDialogState(() {
                                _selectedCollaborator = user;
                                _nameController.text =
                                    user['username']?.toString() ?? '';
                                _errorMessage = "";
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),

                  // --- Buttons ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () async {
                          if (_selectedCollaborator == null) {
                            setDialogState(() {
                              _errorMessage = "Please select a user.";
                            });
                            return;
                          }

                          try {
                            final success =
                                await DataService.deleteCollaboratorFromPlaylist(
                              widget.pid,
                              _selectedCollaborator!['uid'],
                            );

                            setDialogState(() {
                              _errorMessage = success
                                  ? "Successfully deleted. Please select another person or close."
                                  : "Failed to delete collaborator.";
                            });

                            if (success) {
                              collaboratorAdded = true;

                              setState(() {
                                _allCollaborators.removeWhere(
                                  (c) => c['uid'] == _selectedCollaborator!['uid'],
                                );
                            });
                            };
                          } catch (e) {
                            setDialogState(() {
                              _errorMessage = "Error deleting collaborator.";
                            });
                          }
                        },
                        child: const ComicTitle(title: "Delete", size: 16),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, collaboratorAdded);
                          Navigator.pop(context, collaboratorAdded);
                        },
                        child: const ComicTitle(title: "Close", size: 16),
                      ),
                    ],
                  ),

                  // --- Error message display ---
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _errorMessage,
                        style: _errorMessage.contains("Success") 
                          ? TextStyle(color: Colors.black) 
                          : const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

}
