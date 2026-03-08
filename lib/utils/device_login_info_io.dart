import 'dart:io';

Future<Map<String, dynamic>> getDeviceLoginInfoImpl() async {
  try {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.any,
    );

    String ipV4 = 'indisponivel';
    String ipV6 = 'indisponivel';
    final foundInterfaces = <String>[];

    for (final networkInterface in interfaces) {
      if (networkInterface.addresses.isEmpty) {
        continue;
      }

      foundInterfaces.add(networkInterface.name);

      for (final address in networkInterface.addresses) {
        if (ipV4 == 'indisponivel' &&
            address.type == InternetAddressType.IPv4) {
          ipV4 = address.address;
        }

        if (ipV6 == 'indisponivel' &&
            address.type == InternetAddressType.IPv6) {
          ipV6 = address.address;
        }
      }
    }

    return {
      'platform': Platform.operatingSystem,
      'platform_version': Platform.operatingSystemVersion,
      'local_ip_v4': ipV4,
      'local_ip_v6': ipV6,
      'interfaces': foundInterfaces,
      'mac_address': 'indisponivel',
      'observation':
          'dart:io nao expoe MAC do dispositivo em Flutter mobile por padrao.',
    };
  } catch (e) {
    return {
      'platform': Platform.operatingSystem,
      'local_ip_v4': 'indisponivel',
      'local_ip_v6': 'indisponivel',
      'mac_address': 'indisponivel',
      'error': 'Falha ao coletar informacoes de rede: $e',
    };
  }
}
