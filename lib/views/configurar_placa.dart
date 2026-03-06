import 'dart:convert';
import 'dart:io';

import 'package:condotop/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ConfigurarPlaca extends StatefulWidget {
  const ConfigurarPlaca({super.key});

  @override
  State<ConfigurarPlaca> createState() => _ConfigurarPlacaState();
}

class _ConfigurarPlacaState extends State<ConfigurarPlaca> {
  static final Guid _wifiServiceUuid =
      Guid('12345678-1234-1234-1234-1234567890ab');
  static final Guid _wifiCharacteristicUuid =
      Guid('abcdefab-1234-5678-1234-abcdefabcdef');

  final _formKey = GlobalKey<FormState>();
  final _ssidController = TextEditingController();
  final _senhaController = TextEditingController();

  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  List<ScanResult> _scanResults = const [];
  BluetoothDevice? _connectedDevice;
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    FlutterBluePlus.adapterState.listen((state) {
      if (!mounted) {
        return;
      }
      setState(() {
        _adapterState = state;
      });
    });

    FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) {
        return;
      }
      setState(() {
        _scanResults = results;
      });
    });
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _ativarBluetooth() async {
    try {
      if (Platform.isAndroid && _adapterState != BluetoothAdapterState.on) {
        await FlutterBluePlus.turnOn();
      }

      if (!mounted) {
        return;
      }

      final state = await FlutterBluePlus.adapterState.first;
      setState(() {
        _adapterState = state;
      });

      if (state != BluetoothAdapterState.on) {
        if (!mounted) {
          return;
        }
        AppSnackbar.showInfo(
          context,
          'Ative o Bluetooth nas configurações do celular para continuar.',
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      AppSnackbar.showError(context, 'Não foi possível ativar o Bluetooth.');
    }
  }

  Future<void> _buscarDispositivos() async {
    if (_adapterState != BluetoothAdapterState.on) {
      AppSnackbar.showInfo(
        context,
        'Ative o Bluetooth antes de buscar dispositivos.',
      );
      return;
    }

    try {
      setState(() {
        _isScanning = true;
      });
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
      await FlutterBluePlus.isScanning.where((value) => value == false).first;
    } catch (e) {
      if (!mounted) {
        return;
      }
      AppSnackbar.showError(context, 'Falha ao buscar dispositivos próximos.');
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _conectar(BluetoothDevice device) async {
    try {
      setState(() {
        _isConnecting = true;
      });

      await FlutterBluePlus.stopScan();

      await device.disconnect();
      await device.connect(timeout: const Duration(seconds: 12));

      if (!mounted) {
        return;
      }

      setState(() {
        _connectedDevice = device;
      });

      AppSnackbar.showSuccess(
        context,
        'Conectado em ${_deviceName(device)} com sucesso!',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      AppSnackbar.showError(context, 'Não foi possível conectar no hardware.');
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  Future<void> _enviarWifiParaPlaca() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final device = _connectedDevice;
    if (device == null) {
      AppSnackbar.showInfo(context, 'Conecte-se ao hardware primeiro.');
      return;
    }

    try {
      setState(() {
        _isSending = true;
      });

      final services = await device.discoverServices();
      BluetoothCharacteristic? writableCharacteristic;

      for (final service in services) {
        for (final characteristic in service.characteristics) {
          final isTarget = service.uuid == _wifiServiceUuid &&
              characteristic.uuid == _wifiCharacteristicUuid;
          if (isTarget &&
              (characteristic.properties.write ||
                  characteristic.properties.writeWithoutResponse)) {
            writableCharacteristic = characteristic;
            break;
          }

          if (writableCharacteristic == null &&
              (characteristic.properties.write ||
                  characteristic.properties.writeWithoutResponse)) {
            writableCharacteristic = characteristic;
          }
        }
      }

      if (writableCharacteristic == null) {
        if (!mounted) {
          return;
        }
        AppSnackbar.showError(
          context,
          'Não foi possível localizar uma característica BLE para envio.',
        );
        return;
      }

      final payload = {
        'ssid': _ssidController.text.trim(),
        'password': _senhaController.text,
      };

      final bytes = utf8.encode(jsonEncode(payload));
      await writableCharacteristic.write(
        bytes,
        withoutResponse: writableCharacteristic.properties.writeWithoutResponse,
      );

      if (!mounted) {
        return;
      }
      AppSnackbar.showSuccess(context, 'Credenciais enviadas para a placa!');
    } catch (e) {
      if (!mounted) {
        return;
      }
      AppSnackbar.showError(
          context, 'Falha ao enviar dados de Wi‑Fi para a placa.');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  String _deviceName(BluetoothDevice device) {
    if (device.platformName.trim().isNotEmpty) {
      return device.platformName;
    }
    return device.remoteId.str;
  }

  @override
  Widget build(BuildContext context) {
    const blueColor = Color.fromARGB(225, 0, 68, 170);
    const orangeColor = Color.fromARGB(255, 255, 102, 1);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        ),
        backgroundColor: blueColor,
        centerTitle: true,
        title: const Text(
          'Configurar placa',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Text(
                _adapterState == BluetoothAdapterState.on
                    ? 'Bluetooth ativado. Busque e conecte no hardware.'
                    : 'Bluetooth desativado. Ative para buscar dispositivos próximos.',
                style: const TextStyle(
                  color: Color.fromARGB(225, 0, 68, 170),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _ativarBluetooth,
                icon: const Icon(Icons.bluetooth, color: Colors.white),
                label: const Text(
                  'Ativar Bluetooth',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blueColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isScanning ? null : _buscarDispositivos,
                icon: _isScanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.search_rounded, color: Colors.white),
                label: Text(
                  _isScanning ? 'Buscando...' : 'Listar conexões próximas',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (_scanResults.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade100,
                ),
                child: const Text(
                  'Nenhum dispositivo listado ainda. Toque em "Listar conexões próximas".',
                  style: TextStyle(fontSize: 13),
                ),
              )
            else
              ..._scanResults.map((result) {
                final device = result.device;
                final isConnected =
                    _connectedDevice?.remoteId == device.remoteId;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(
                      Icons.memory_rounded,
                      color: isConnected ? Colors.green : Colors.grey.shade700,
                    ),
                    title: Text(
                      _deviceName(device),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('RSSI: ${result.rssi}'),
                    trailing: ElevatedButton(
                      onPressed: (_isConnecting || isConnected)
                          ? null
                          : () => _conectar(device),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isConnected ? Colors.green : blueColor,
                      ),
                      child: Text(
                        isConnected ? 'Conectado' : 'Conectar',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _ssidController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da rede Wi‑Fi (SSID)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.wifi_rounded),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o nome da rede';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _senhaController,
                    decoration: const InputDecoration(
                      labelText: 'Senha do Wi‑Fi',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe a senha';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _enviarWifiParaPlaca,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSending ? Colors.grey : orangeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Enviar Wi‑Fi para a placa',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Se o firmware usar UUIDs BLE específicos, ajuste os valores em ConfigurarPlaca.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                    textAlign: TextAlign.center,
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
