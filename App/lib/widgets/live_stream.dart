import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';

class LiveStream extends StatelessWidget {
  final String streamUrl;

  LiveStream({required this.streamUrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 400,
        height: 300,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green, width: 3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Mjpeg(
            stream: streamUrl,
            isLive: true,
            fit: BoxFit.cover,
            error: (context, error, stack) =>
                Center(child: Text('Stream error')),
          ),
        ),
      ),
    );
  }
}
