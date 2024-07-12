import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_circle_color_picker/flutter_circle_color_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

class ColorPickerScreen extends StatefulWidget {
  final BluetoothConnection? conexion;
  const ColorPickerScreen({super.key, required this.conexion});

  @override
  _ColorPickerScreenState createState() => _ColorPickerScreenState();
}

class _ColorPickerScreenState extends State<ColorPickerScreen> {
  final _controller = CircleColorPickerController(
    initialColor: Colors.blue,
  );

  void getToken() async {
  String? token = await FirebaseMessaging.instance.getToken();
  print("Device Token: $token");
  // Aquí puedes enviar el token a tu backend para almacenarlo
}

  Color selectedColor = Colors.blue; // Color inicial
  double redValue = 0.0;
  double greenValue = 0.0;
  double blueValue = 255.0;

  bool isOn = false;

  @override
  void initState() {
    super.initState();
      getToken();
    
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        showDialog(
          context: context,
          builder: (_) {
            return AlertDialog(
              title: Text(notification.title ?? ''),
              content: Text(notification.body ?? ''),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    });
  }

  void _sendColor(String data) {
    if (widget.conexion?.isConnected ?? false) {
      widget.conexion?.output.add(ascii.encode(data));
    }
    _sendNotification(data);
  }

  Future<void> _sendNotification(String colorCode) async {
  final String serverUrl = 'http://192.168.1.10:5000/send_notification'; // Cambia a tu URL de servidor
  final String? deviceToken = await FirebaseMessaging.instance.getToken(); // Obtener el token actual

  if (deviceToken == null) {
    print('Error al obtener el token de dispositivo');
    return;
  }

  try {
    final response = await http.post(
      Uri.parse(serverUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'title': 'LED cambiado',
        'body': 'Color: $colorCode',
        'token': deviceToken,
      }),
    );

    if (response.statusCode == 200) {
      print('Notificación enviada exitosamente');
    } else {
      print('Error al enviar notificación: ${response.statusCode}');
    }
  } catch (e) {
    print('Error al conectar con el servidor: $e');
  }
}


  void updateSelectedColor() {
    _controller.color = Color.fromARGB(255, redValue.toInt(), greenValue.toInt(), blueValue.toInt());
  }

  void toggleLed() {
    setState(() {
      isOn = !isOn;
      !isOn ? _sendColor("000000") : _sendColor("FFFFFF");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Picker'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 100,
                  icon: const Icon(Icons.lightbulb_outline),
                  color: isOn ? Colors.green : Colors.grey,
                  onPressed: toggleLed,
                  tooltip: Text(isOn ? 'Apagar' : 'Encender').toString(),
                ),
                const SizedBox(height: 20),
              ],
            ),
            CircleColorPicker(
              controller: _controller,
              onChanged: (color) {
                setState(() {
                  selectedColor = color;
                  redValue = color.red.toDouble();
                  greenValue = color.green.toDouble();
                  blueValue = color.blue.toDouble();
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String hexCode = selectedColor.value.toRadixString(16).substring(2).toUpperCase();
                _sendColor(hexCode); // Envía el color seleccionado
              },
              child: const Text('Enviar color al Arduino'),
            ),
          ],
        ),
      ),
    );
  }
}
