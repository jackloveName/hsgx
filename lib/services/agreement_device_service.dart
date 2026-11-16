import 'package:flutter_contacts/flutter_contacts.dart';

class AgreementContactReadResult {
  const AgreementContactReadResult({
    required this.hasPermission,
    required this.contacts,
  });

  final bool hasPermission;
  final List<AgreementContactRow> contacts;
}

class AgreementContactRow {
  const AgreementContactRow({required this.name, required this.phone});

  final String name;
  final String phone;

  Map<String, String> toJson() => {'name': name, 'phone': phone};
}

class AgreementDeviceService {
  Future<AgreementContactReadResult> readContacts() async {
    try {
      final status = await FlutterContacts.permissions.request(
        PermissionType.read,
      );
      final granted =
          status == PermissionStatus.granted ||
          status == PermissionStatus.limited;
      if (!granted) {
        return const AgreementContactReadResult(
          hasPermission: false,
          contacts: [],
        );
      }
      final contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.phone},
      );
      final rows = <AgreementContactRow>[];
      for (final contact in contacts) {
        final name = contact.displayName?.trim().isNotEmpty == true
            ? contact.displayName!.trim()
            : '未知姓名';
        for (final phone in contact.phones) {
          final number = phone.number.replaceAll(RegExp(r'[\s-]'), '');
          if (number.isNotEmpty) {
            rows.add(AgreementContactRow(name: name, phone: number));
          }
        }
      }
      return AgreementContactReadResult(hasPermission: true, contacts: rows);
    } on Object {
      return const AgreementContactReadResult(
        hasPermission: false,
        contacts: [],
      );
    }
  }

  Future<void> openContactSettings() =>
      FlutterContacts.permissions.openSettings();
}
