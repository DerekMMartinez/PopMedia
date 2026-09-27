import 'package:flutter/material.dart';
import 'package:pop_media/service/data_service.dart';
import 'package:pop_media/session/user_session.dart';
import 'package:pop_media/text_speech/tts_service.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/widgets/comic_title.dart';
import 'package:provider/provider.dart';

class ReportPopUp extends StatefulWidget {
  final String? associatedId;
  final String type;

  ReportPopUp({super.key, this.associatedId, required this.type});

  @override
  State<ReportPopUp> createState() => _ReportPopUpState();
}


class _ReportPopUpState extends State<ReportPopUp> {
  String _errorText = "";

  @override
  Widget build(BuildContext context) {
    final _issueController = TextEditingController();
    final theme = context.watch<ThemeController>().currentTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.primaryColor, width: 2,),
        color: theme.mainBackgroundColor,
        image: theme.mainBackgroundImage != null
            ? DecorationImage(
                image: AssetImage(theme.mainBackgroundImage!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child:
      Stack( 
        children: [
        Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ComicTitle(title: 'Report A ${widget.type} Issue'),
            SizedBox(height: 10),
            Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Finding: ',
                  style: TextStyle(
                    fontFamily: theme.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 260,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('issue_controller'),
                        controller: _issueController,
                        onTap: () {context.read<TtsService>().speak("Typing Report");},
                        expands: true,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          hintText: 'Explain the Issue...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if(_errorText != "")...[
                Text(_errorText, style: TextStyle(color: Colors.red))
              ],
              TextButton(
                onPressed: () async {
                  //Upload report logic
                  try {
                    if(_issueController.text != ""){
                      await DataService.postReport(
                        associated_id: widget.associatedId ?? "",
                        type: widget.type,
                        reason: _issueController.text,
                        reporter: UserSession.uid!,
                        created_at: DateTime.now(),
                      );

                      Navigator.of(context).pop();
                      context.read<TtsService>().speak("Report Successfully Submitted");

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Report Successfully Submitted. Thanks for helping PopMedia be a safe and fun app!")),
                      ); 
                    }
                    else{
                      setState(() {
                        _errorText = "Reason cannot be empty, please be as specific as possible";
                        context.read<TtsService>().speak("Error: ${_errorText}");
                      });
                    }
                  } catch (e) {
                    setState(() {
                      _errorText = "Error posting review: $e";
                      context.read<TtsService>().speak("Error: ${_errorText}");
                    });
                  }
                },
                child: ComicTitle(title: 'Report'),
              ),
          ],
      )
    ),    
    Positioned(
      right: 0,
      top: 0,
      child: IconButton(
        icon: Icon(Icons.close, color: theme.primaryColor),
        onPressed: () => {
          context.read<TtsService>().speak("Closed Report PopUp"),
          Navigator.pop(context),
        }
      ),
      ),],),
      )
    );
  }
}