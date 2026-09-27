import 'package:flutter/material.dart';
import 'package:pop_media/pages/annual_recap.dart';
import 'package:pop_media/text_speech/tts_service.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class RecapCard extends StatelessWidget {
  final String year;

  RecapCard({
    super.key,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
    children: [ 
      Padding(
          padding: const EdgeInsets.all(2.5),
          child: GestureDetector(
            onTap: () {
              context.read<TtsService>().speak("Opening Annual Recap");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AnnualRecap(year: year),
                ),
              );
            },
            child: Card(
                shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            margin: EdgeInsets.zero,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: 130,  
                child: year == '2024' ? Image.asset('assets/recaps/Recap2024.png', fit: BoxFit.contain,): Image.asset('assets/recaps/Recap2025.png', fit: BoxFit.contain,),
            ),
            ),
          ),
        ),
        ]
    );
  }
}