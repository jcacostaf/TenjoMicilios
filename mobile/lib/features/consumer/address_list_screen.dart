import 'package:flutter/material.dart';
import '../../core/models/consumer_address.dart';
import '../../core/services/address_storage_service.dart';
import 'address_form_screen.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  final _storage = AddressStorageService();
  List<ConsumerAddress> _addresses = [];
  String? _selectedId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final addresses = await _storage.getAddresses();
    final selectedId = await _storage.getSelectedAddressId();
    setState(() {
      _addresses = addresses;
      _selectedId = selectedId;
      _loading = false;
    });
  }

  Future<void> _select(String id) async {
    await _storage.setSelectedAddressId(id);
    setState(() => _selectedId = id);
  }

  Future<void> _delete(String id) async {
    await _storage.deleteAddress(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis direcciones')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? const Center(child: Text('Todavia no tienes direcciones guardadas'))
              : ListView.builder(
                  itemCount: _addresses.length,
                  itemBuilder: (context, index) {
                    final address = _addresses[index];
                    final housingLabel = address.housingType == HousingType.casa
                        ? 'Casa'
                        : 'Apartamento';
                    return RadioListTile<String>(
                      value: address.id,
                      groupValue: _selectedId,
                      onChanged: (value) => _select(value!),
                      title: Text(address.label),
                      subtitle: Text(
                        '${address.addressText}\n$housingLabel'
                        '${address.additionalInfo != null ? ' · ${address.additionalInfo}' : ''}',
                      ),
                      isThreeLine: true,
                      secondary: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(address.id),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddressFormScreen()),
          );
          _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
