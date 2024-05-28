import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_circle_color_picker/flutter_circle_color_picker.dart';

class ColorPickerScreen extends StatefulWidget {
  final BluetoothConnection? conexion;
  const ColorPickerScreen({super.key, required this.conexion});

  @override
  // ignore: library_private_types_in_public_api
  _ColorPickerScreenState createState() => _ColorPickerScreenState();
}

class _ColorPickerScreenState extends State<ColorPickerScreen> {
  final _controller = CircleColorPickerController(
    initialColor: Colors.blue,
  );

  Color selectedColor = Colors.blue; // Color inicial
  double redValue = 0.0;
  double greenValue = 0.0;
  double blueValue = 255.0;
  
  bool isOn = false;

  void _sendColor(String data) {
    if (widget.conexion?.isConnected ?? false) {
      widget.conexion?.output.add(ascii.encode(data));
    }
  }

  void updateSelectedColor() {
    // Calcula el color combinado usando los valores de los sliders
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