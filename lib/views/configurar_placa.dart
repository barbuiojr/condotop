import 'dart:convert';
import 'dart:io';

import 'package:condotop/utils/app_snackbar.dart';
import 'package:flutter/material.dart';

import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;

import 'package:flutter_bluetooth_classic_serial/flutter_bluetooth_classic.dart'
    as classic;

class ConfigurarPlaca extends StatefulWidget {
  const ConfigurarPlaca({super.key});

  @override
  State<ConfigurarPlaca> createState() => _ConfigurarPlacaState();
}

class _ConfigurarPlacaState extends State<ConfigurarPlaca> {
  // =========================================================
  // BLE
  // =========================================================

  static final ble.Guid _wifiServiceUuid =
      ble.Guid('12345678-1234-1234-1234-1234567890ab');

  static final ble.Guid _wifiCharacteristicUuid =
      ble.Guid('abcdefab-1234-5678-1234-abcdefabcdef');

  ble.BluetoothAdapterState _adapterState = ble.BluetoothAdapterState.unknown;

  List<ble.ScanResult> _scanResults = [];

  ble.BluetoothDevice? _connectedBleDevice;

  bool _isBleScanning = false;

  // =========================================================
  // CLASSIC
  // =========================================================

  final classic.FlutterBluetoothClassic _bluetoothClassic =
      classic.FlutterBluetoothClassic();

  List<classic.BluetoothDevice> _classicDevices = [];

  // classic.BluetoothConnection? _classicConnection;

  bool _classicConnected = false;

  classic.BluetoothDevice? _connectedClassicDevice;

  bool _isClassicScanning = false;

  // =========================================================
  // FORM
  // =========================================================

  final _formKey = GlobalKey<FormState>();

  final _ssidController = TextEditingController();

  final _senhaController = TextEditingController();

  bool _isSending = false;

  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();

    // BLE STATE
    ble.FlutterBluePlus.adapterState.listen((state) {
      if (!mounted) return;

      setState(() {
        _adapterState = state;
      });
    });

    // BLE RESULTS
    ble.FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;

      setState(() {
        _scanResults = results;
      });
    });
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _senhaController.dispose();

    // _classicConnection?.dispose();

    super.dispose();
  }

  // =========================================================
  // BLUETOOTH
  // =========================================================

  Future<void> _ativarBluetooth() async {
    try {
      if (Platform.isAndroid && _adapterState != ble.BluetoothAdapterState.on) {
        await ble.FlutterBluePlus.turnOn();
      }

      final state = await ble.FlutterBluePlus.adapterState.first;

      setState(() {
        _adapterState = state;
      });

      if (state != ble.BluetoothAdapterState.on) {
        if (!mounted) return;

        AppSnackbar.showInfo(
          context,
          'Ative o Bluetooth para continuar.',
        );
      }
    } catch (e) {
      AppSnackbar.showError(
        context,
        'Erro ao ativar Bluetooth.',
      );
    }
  }

  // =========================================================
  // BLE
  // =========================================================

  Future<void> _buscarBle() async {
    if (_adapterState != ble.BluetoothAdapterState.on) {
      AppSnackbar.showInfo(
        context,
        'Ative o Bluetooth primeiro.',
      );
      return;
    }

    try {
      setState(() {
        _isBleScanning = true;
      });

      await ble.FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 8),
      );

      await ble.FlutterBluePlus.isScanning
          .where((value) => value == false)
          .first;
    } catch (e) {
      AppSnackbar.showError(
        context,
        'Erro ao buscar BLE.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBleScanning = false;
        });
      }
    }
  }

  Future<void> _conectarBle(ble.BluetoothDevice device) async {
    try {
      setState(() {
        _isConnecting = true;
      });

      await ble.FlutterBluePlus.stopScan();

      await device.disconnect();

      await device.connect(
        timeout: const Duration(seconds: 10),
      );

      setState(() {
        _connectedBleDevice = device;
      });

      AppSnackbar.showSuccess(
        context,
        'BLE conectado!',
      );
    } catch (e) {
      AppSnackbar.showError(
        context,
        'Erro ao conectar BLE.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  // =========================================================
  // CLASSIC
  // =========================================================

  Future<void> _listarClassicPareados() async {
    try {
      final devices = await _bluetoothClassic.getPairedDevices();

      setState(() {
        _classicDevices = devices;
      });

      if (devices.isEmpty) {
        AppSnackbar.showInfo(
          context,
          'Nenhum bluetooth classic pareado.',
        );
      }
    } catch (e) {
      AppSnackbar.showError(
        context,
        'Erro ao listar bluetooth classic.',
      );
    }
  }

  Future<void> _buscarClassic() async {
    try {
      setState(() {
        _isClassicScanning = true;
        _classicDevices.clear();
      });

      await _bluetoothClassic.startDiscovery();

      _bluetoothClassic.onDeviceDiscovered.listen((device) {
        final exists = _classicDevices.any(
          (d) => d.address == device.address,
        );

        if (!exists) {
          setState(() {
            _classicDevices.add(device);
          });
        }
      });
    } catch (e) {
      AppSnackbar.showError(
        context,
        'Erro ao buscar bluetooth classic.',
      );
    } finally {
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) {
          setState(() {
            _isClassicScanning = false;
          });
        }
      });
    }
  }

  Future<void> _conectarClassic(
    classic.BluetoothDevice device,
  ) async {
    try {
      setState(() {
        _isConnecting = true;
      });

      final connected = await _bluetoothClassic.connect(
        device.address,
      );

      setState(() {
        _classicConnected = connected;
        _connectedClassicDevice = device;
      });

      AppSnackbar.showSuccess(
        context,
        'Classic conectado!',
      );
    } catch (e) {
      AppSnackbar.showError(
        context,
        'Erro ao conectar classic.',
      );
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  // =========================================================
  // ENVIAR WIFI
  // =========================================================

  Future<void> _enviarWifi() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isSending = true;
      });

      // final payload = {
      //   'ssid': _ssidController.text.trim(),
      //   'senha': _senhaController.text,
      // };

      // final jsonString = jsonEncode(payload);

      print('==========================');
      print('ENVIANDO VIA BLUETOOTH');
      print('WIFI:${_ssidController.text.trim()}');
      print('PASSWORD:${_senhaController.text}');
      // print('JSON: $jsonString');
      // print('BYTES: ${utf8.encode(jsonString)}');
      print('==========================');
      print('WIFI:${_ssidController.text};PASSWORD:${_senhaController.text}');

      // =====================================================
      // CLASSIC
      // =====================================================

      if (_classicConnected) {
        await _bluetoothClassic.sendString(
          'WIFI:${_ssidController.text};PASSWORD:${_senhaController.text}',
        );

        AppSnackbar.showSuccess(
          context,
          'Wi-Fi enviado via Bluetooth Classic!',
        );

        return;
      }

      // =====================================================
      // BLE
      // =====================================================

      final bleDevice = _connectedBleDevice;

      if (bleDevice != null) {
        final services = await bleDevice.discoverServices();

        ble.BluetoothCharacteristic? characteristic;

        for (final service in services) {
          for (final c in service.characteristics) {
            final isTarget = service.uuid == _wifiServiceUuid &&
                c.uuid == _wifiCharacteristicUuid;

            if (isTarget &&
                (c.properties.write || c.properties.writeWithoutResponse)) {
              characteristic = c;
              break;
            }
          }
        }

        if (characteristic != null) {
          // await characteristic.write(
          //     // utf8.encode(jsonString),
          //     // withoutResponse: characteristic.properties.writeWithoutResponse,
          //     );

          AppSnackbar.showSuccess(
            context,
            'Wi-Fi enviado via BLE!',
          );
          return;
        }
      }

      AppSnackbar.showError(
        context,
        'Nenhum dispositivo conectado.',
      );
    } catch (e) {
      AppSnackbar.showError(
        context,
        'Erro ao enviar Wi-Fi.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  String _deviceName(dynamic device) {
    try {
      if (device.name != null && device.name.toString().trim().isNotEmpty) {
        return device.name;
      }
    } catch (_) {}

    try {
      if (device.platformName != null &&
          device.platformName.toString().trim().isNotEmpty) {
        return device.platformName;
      }
    } catch (_) {}

    try {
      return device.address;
    } catch (_) {}

    try {
      return device.remoteId.str;
    } catch (_) {}

    return 'Dispositivo';
  }

  @override
  Widget build(BuildContext context) {
    const blueColor = Color.fromARGB(225, 0, 68, 170);

    const orangeColor = Color.fromARGB(255, 255, 102, 1);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: blueColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Configurar placa',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _ativarBluetooth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: blueColor,
                ),
                icon: const Icon(
                  Icons.bluetooth,
                  color: Colors.white,
                ),
                label: const Text(
                  'Ativar Bluetooth',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // BLE

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isBleScanning ? null : _buscarBle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor,
                ),
                icon: const Icon(
                  Icons.wifi_tethering,
                  color: Colors.white,
                ),
                label: const Text(
                  'Buscar BLE',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // CLASSIC

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _listarClassicPareados,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                ),
                icon: const Icon(
                  Icons.devices,
                  color: Colors.white,
                ),
                label: const Text(
                  'Listar Classic Pareados',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isClassicScanning ? null : _buscarClassic,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                ),
                icon: const Icon(
                  Icons.search,
                  color: Colors.white,
                ),
                label: const Text(
                  'Buscar Classic',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // =====================================================
            // BLE LIST
            // =====================================================

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'BLE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),

            const SizedBox(height: 10),

            ..._scanResults.map((result) {
              final device = result.device;

              final connected =
                  _connectedBleDevice?.remoteId == device.remoteId;

              return Card(
                child: ListTile(
                  title: Text(_deviceName(device)),
                  subtitle: Text(device.remoteId.str),
                  trailing: ElevatedButton(
                    onPressed: connected ? null : () => _conectarBle(device),
                    child: Text(
                      connected ? 'Conectado' : 'Conectar',
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            // =====================================================
            // CLASSIC LIST
            // =====================================================

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Bluetooth Classic',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),

            const SizedBox(height: 10),

            ..._classicDevices.map((device) {
              final connected =
                  _connectedClassicDevice?.address == device.address;

              return Card(
                child: ListTile(
                  title: Text(_deviceName(device)),
                  subtitle: Text(device.address),
                  trailing: ElevatedButton(
                    onPressed:
                        connected ? null : () => _conectarClassic(device),
                    child: Text(
                      connected ? 'Conectado' : 'Conectar',
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            // =====================================================
            // FORM
            // =====================================================

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _ssidController,
                    decoration: const InputDecoration(
                      labelText: 'SSID',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o SSID';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _senhaController,
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe a senha';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _enviarWifi,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orangeColor,
                      ),
                      child: _isSending
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'Enviar Wi-Fi',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
