import 'device_login_info_stub.dart'
    if (dart.library.io) 'device_login_info_io.dart';

Future<Map<String, dynamic>> getDeviceLoginInfo() => getDeviceLoginInfoImpl();
