import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/consumer_address.dart';

class AddressStorageService {
  static const _addressesKey = 'consumer_addresses';
  static const _selectedIdKey = 'consumer_selected_address_id';

  Future<List<ConsumerAddress>> getAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_addressesKey);
    if (raw == null) return [];

    final List<dynamic> data = jsonDecode(raw);
    return data.map((json) => ConsumerAddress.fromJson(json)).toList();
  }

  Future<void> addAddress(ConsumerAddress address) async {
    final addresses = await getAddresses();
    addresses.add(address);
    await _saveAddresses(addresses);

    final selectedId = await getSelectedAddressId();
    if (selectedId == null) {
      await setSelectedAddressId(address.id);
    }
  }

  Future<void> deleteAddress(String id) async {
    final addresses = await getAddresses();
    addresses.removeWhere((a) => a.id == id);
    await _saveAddresses(addresses);

    final selectedId = await getSelectedAddressId();
    if (selectedId == id) {
      await setSelectedAddressId(addresses.isEmpty ? null : addresses.first.id);
    }
  }

  Future<String?> getSelectedAddressId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedIdKey);
  }

  Future<void> setSelectedAddressId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_selectedIdKey);
    } else {
      await prefs.setString(_selectedIdKey, id);
    }
  }

  Future<void> _saveAddresses(List<ConsumerAddress> addresses) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(addresses.map((a) => a.toJson()).toList());
    await prefs.setString(_addressesKey, raw);
  }
}
