import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_grid_button/flutter_grid_button.dart';

//Helper classes
class BleInfo {
  final BluetoothDevice device;
  final BluetoothService service;
  final BluetoothCharacteristic characteristic;

  const BleInfo(this.device, this.service, this.characteristic);
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CHIP8 BLE NUMPAD',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'CHIP8 Numpad'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final List<BluetoothDevice> devicesList = new List<BluetoothDevice>();
  BluetoothDevice connectedDevice;
  BluetoothService keypadSevice;
  BluetoothCharacteristic keypadChar;
  BleInfo bleInfo;

  @override
  State<StatefulWidget> createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  _addDeviceTolist(final BluetoothDevice device) {
    if (!widget.devicesList.contains(device)) {
      setState(() {
        widget.devicesList.add(device);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    widget.flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        _addDeviceTolist(device);
      }
    });
    widget.flutterBlue.scanResults.listen((List<ScanResult> devices) {
      for (ScanResult result in devices) {
        _addDeviceTolist(result.device);
      }
    });
    widget.flutterBlue.startScan();
  }

  ListView _buildListViewofDevices() {
    var containers = new List<Container>();
    for (BluetoothDevice device in widget.devicesList) {
      containers.add(Container(
        height: 50,
        child: Row(
          children: [
            Expanded(
                child: Column(
              children: [
                Text(device.name == '' ? '(unknown device)' : device.name),
                Text(device.id.toString()),
              ],
            )),
            FlatButton(
                color: Colors.blue,
                child: Text(
                  'Connect',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () async {
                  List<BluetoothService> services;
                  widget.flutterBlue.stopScan();
                  try {
                    await device.connect();
                  } on PlatformException catch (e) {
                    if (e.code != 'already_connected') {
                      throw e;
                    }
                  } finally {
                    services = await device.discoverServices();
                  }
                  for (BluetoothService service in services) {
                    var serUUID = service.uuid.toString();
                    if (serUUID.contains('000000fe')) {
                      widget.keypadSevice = service;
                    }
                    for (var chars in service.characteristics) {
                      var charUUID = chars.uuid.toString();
                      if (charUUID.contains('0000ff01')) {
                        widget.keypadChar = chars;
                      }
                    }
                  }
                  setState(() {
                    widget.connectedDevice = device;
                  });
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SecondRoute(BleInfo(
                              widget.connectedDevice,
                              widget.keypadSevice,
                              widget.keypadChar))));
                })
          ],
        ),
      ));
    }

    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        ...containers,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _buildListViewofDevices(),
    );
  }
}

class SecondRoute extends StatelessWidget {
  final BleInfo _selectedDevice;

  SecondRoute(this._selectedDevice);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("CHIP8 Numpad"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(18.0),
          child: GridButton(
            textStyle: TextStyle(fontSize: 20),
            borderColor: Colors.grey[300],
            borderWidth: 1,
            onPressed: (dynamic ipVal) {
              int valInt;
              if (ipVal != "Back") {
                valInt = int.parse(ipVal.toString(), radix: 16);
              } else {
                valInt = 0xFF;
              }
              debugPrint('$valInt');
              _selectedDevice.characteristic.write([valInt]);
            },
            items: [
              [
                GridButtonItem(child: Image.asset('assets/chip8.png')),
              ],
              [
                GridButtonItem(title: "1", color: Colors.indigoAccent),
                GridButtonItem(title: "2", color: Colors.indigoAccent),
                GridButtonItem(title: "3", color: Colors.indigoAccent),
                GridButtonItem(title: "C", color: Colors.indigoAccent),
              ],
              [
                GridButtonItem(title: "4", color: Colors.indigoAccent),
                GridButtonItem(title: "5", color: Colors.indigoAccent),
                GridButtonItem(title: "6", color: Colors.indigoAccent),
                GridButtonItem(title: "D", color: Colors.indigoAccent),
              ],
              [
                GridButtonItem(title: "7", color: Colors.indigoAccent),
                GridButtonItem(title: "8", color: Colors.indigoAccent),
                GridButtonItem(title: "9", color: Colors.indigoAccent),
                GridButtonItem(title: "E", color: Colors.indigoAccent),
              ],
              [
                GridButtonItem(title: "A", color: Colors.indigoAccent),
                GridButtonItem(title: "0", color: Colors.indigoAccent),
                GridButtonItem(title: "B", color: Colors.indigoAccent),
                GridButtonItem(title: "F", color: Colors.indigoAccent),
              ],
              [
                GridButtonItem(title: "Back", color: Colors.grey),
              ],
            ],
          ),
        ));
  }
}
