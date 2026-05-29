import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_classic_serial/flutter_bluetooth_classic.dart';

class BluetoothServico {
  final FlutterBluetoothClassic _bluetooth = FlutterBluetoothClassic();

  // Streams
  StreamSubscription<BluetoothState>? stateSubscription;
  StreamSubscription<BluetoothConnectionState>? connectionSubscription;
  StreamSubscription<BluetoothData>? dataSubscription;
  StreamSubscription<BluetoothDevice>? discoverySubscription;

  // Dados
  final List<BluetoothDevice> pairedDevices = [];
  final List<BluetoothDevice> discoveredDevices = [];

  BluetoothConnectionState? connectionState;
  BluetoothDevice? connectedDevice;

  // Callback para atualizar UI
  VoidCallback? onUpdate;

  // =========================
  // INIT
  // =========================

  Future<void> init() async {
    _setupListeners();
    await loadPairedDevices();
  }

  // =========================
  // STATUS
  // =========================

  Future<bool> isBluetoothEnabled() async {
    return await _bluetooth.isBluetoothEnabled();
  }

  Future<bool> isBluetoothSupported() async {
    return await _bluetooth.isBluetoothSupported();
  }

  Future<void> enableBluetooth() async {
    await _bluetooth.enableBluetooth();
  }

  // =========================
  // DEVICES
  // =========================

  Future<void> loadPairedDevices() async {
    try {
      final devices = await _bluetooth.getPairedDevices();

      pairedDevices.clear();
      pairedDevices.addAll(devices);

      onUpdate?.call();
    } catch (e) {
      debugPrint("Erro ao carregar dispositivos: $e");
    }
  }

  Future<void> startDiscovery() async {
    discoveredDevices.clear();

    try {
      await _bluetooth.startDiscovery();
    } catch (e) {
      debugPrint("Erro ao buscar dispositivos: $e");
    }
  }

  Future<void> stopDiscovery() async {
    await _bluetooth.stopDiscovery();
  }

  // =========================
  // CONNECTION
  // =========================

  Future<void> connect(String address) async {
    try {
      await _bluetooth.connect(address);
    } catch (e) {
      debugPrint("Erro ao conectar: $e");
    }
  }

  Future<void> disconnect() async {
    try {
      await _bluetooth.disconnect();
    } catch (e) {
      debugPrint("Erro ao desconectar: $e");
    }
  }

  bool get isConnected => connectionState?.isConnected ?? false;

  // =========================
  // SEND DATA
  // =========================

  Future<void> sendMessage(String message) async {
    try {
      await _bluetooth.sendString(message);
    } catch (e) {
      debugPrint("Erro ao enviar mensagem: $e");
    }
  }

  // =========================
  // LISTENERS
  // =========================

  void _setupListeners() {
    stateSubscription = _bluetooth.onStateChanged.listen((state) {
      onUpdate?.call();
    });

    connectionSubscription = _bluetooth.onConnectionChanged.listen((state) {
      connectionState = state;

      if (state.isConnected) {
        connectedDevice = pairedDevices.firstWhere(
          (e) => e.address == state.deviceAddress,
          orElse: () => BluetoothDevice(
            name: "Desconhecido",
            address: state.deviceAddress,
            paired: false,
          ),
        );
      } else {
        connectedDevice = null;
      }

      onUpdate?.call();
    });

    dataSubscription = _bluetooth.onDataReceived.listen((data) {
      debugPrint("Dados recebidos: ${data.asString()}");
    });

    discoverySubscription = _bluetooth.onDeviceDiscovered.listen((device) {
      if (!discoveredDevices.any((e) => e.address == device.address)) {
        discoveredDevices.add(device);
        onUpdate?.call();
      }
    });
  }

  // =========================
  // DISPOSE
  // =========================

  void dispose() {
    stateSubscription?.cancel();
    connectionSubscription?.cancel();
    dataSubscription?.cancel();
    discoverySubscription?.cancel();
  }
}
