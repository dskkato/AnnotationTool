import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'dart:convert';

/// Very useful package which is part of Flutter.
/// Also contains a useful functions, such as [mix] and [smoothStep].
import 'package:vector_math/vector_math.dart';

import 'package:http/http.dart' as http;

void main() async => runApp(MaterialApp(home: Root()));

/// Waits till [ui.Image] is generated and renders
/// it using [CustomPaint] to render it. Allows use of [MediaQuery]
class Root extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.Image>(
      future: generateImage(MediaQuery.of(context).size),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return CustomPaint(
            // Passing our image
            painter: ImagePainter(image: snapshot.data),
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
          );
        }
        return Text('Generating image...');
      },
    );
  }
}

/// Paints given [ui.Image] on [ui.Canvas]
/// does not repaint
class ImagePainter extends CustomPainter {
  ui.Image image;

  ImagePainter({this.image});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(image, Offset.zero, Paint());
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

class Message {
  final String message;

  Message({@required this.message});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(message: json['message']);
  }
}

Future<Message> fetchMessage() async {
  final response = await http.get(Uri.http('127.0.0.1:8000', '/'));

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return Message.fromJson(jsonDecode(response.body));
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    debugPrint('Failed to load message');
    throw Exception('Failed to load message');
  }
}

/// Generates a [ui.Image] with certain pixel data
Future<ui.Image> generateImage(Size size) async {
  fetchMessage().then((message) {
    debugPrint('fetchMessage: $message');
  });

  int width = size.width.ceil();
  int height = size.height.ceil();
  var completer = Completer<ui.Image>();

  Int32List pixels = Int32List(width * height);

  for (var x = 0; x < width; x++) {
    for (var y = 0; y < height; y++) {
      int index = y * width + x;
      pixels[index] = generatePixel(x, y, size);
    }
  }

  ui.decodeImageFromPixels(
    pixels.buffer.asUint8List(),
    width,
    height,
    ui.PixelFormat.bgra8888,
    (ui.Image img) {
      completer.complete(img);
    },
  );

  return completer.future;
}

/// Main area of interest, this function will
/// return color for each particular color on our [ui.Image]
int generatePixel(int x, int y, Size size) {
  /// Compute unified vector, values of its components
  /// will be between 0 and 1
  var uv = Vector2(x / size.width, y / size.height);

  /// Mapping unified vector values
  /// to color range of 0..255
  return Color.fromRGBO(
    (uv.x * 255).toInt(),
    0,
    (uv.y * 255).toInt(),
    1.0,
  ).value;
}
