import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/address.dart';

class AddressBookScreen extends StatelessWidget {
  const AddressBookScreen({super.key});

  String get _userEmail =>
      Hive.box('settings').get('currentUser', defaultValue: '');

  List<Address> get _addresses => Hive.box<Address>('addresses')
      .values
      .where((a) => a.userEmail == _userEmail)
      .toList();

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final primaryBlue = Theme.of(context).colorScheme.primary;
    final darkText = Theme.of(context).colorScheme.onSurface;
    final greyText = Theme.of(context).colorScheme.onSurface.withAlpha(150);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: Colors.white.withAlpha(38), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('My Addresses', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box<Address>('addresses').listenable(),
                builder: (context, box, _) {
                  final addresses = _addresses;
                  return addresses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_off_outlined, size: 64, color: greyText.withAlpha(100)),
                              const SizedBox(height: 16),
                              Text('No addresses yet',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: darkText)),
                              const SizedBox(height: 6),
                              Text('Add your delivery address',
                                  style: TextStyle(fontSize: 14, color: greyText)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: addresses.length,
                          itemBuilder: (context, index) =>
                              _buildAddressCard(context, addresses[index]),
                        );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddressSheet(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Address', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, Address address) {
    final primaryBlue = Theme.of(context).colorScheme.primary;
    final darkText = Theme.of(context).colorScheme.onSurface;
    final greyText = Theme.of(context).colorScheme.onSurface.withAlpha(150);
    final cardWhite = Theme.of(context).cardColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: address.isDefault ? Border.all(color: primaryBlue, width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded, color: primaryBlue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(address.fullName,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: darkText)),
              ),
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primaryBlue.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('DEFAULT',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: primaryBlue)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${address.line1}, ${address.city} - ${address.pincode}',
                    style: TextStyle(fontSize: 13, color: greyText, height: 1.4)),
                Text(address.phone, style: TextStyle(fontSize: 13, color: greyText)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (!address.isDefault)
                      GestureDetector(
                        onTap: () async {
                          final box = Hive.box<Address>('addresses');
                          for (final a in box.values.where((a) => a.userEmail == address.userEmail)) {
                            a.isDefault = false;
                            await a.save();
                          }
                          address.isDefault = true;
                          await address.save();
                        },
                        child: Text('Set as Default',
                            style: TextStyle(fontSize: 13, color: primaryBlue, fontWeight: FontWeight.w600)),
                      ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showAddressSheet(context, existing: address),
                      child: Text('Edit', style: TextStyle(fontSize: 13, color: primaryBlue, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () async => await address.delete(),
                      child: const Text('Delete', style: TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddressSheet(BuildContext context, {Address? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressFormSheet(
        existing: existing,
        userEmail: Hive.box('settings').get('currentUser', defaultValue: ''),
      ),
    );
  }
}

class _AddressFormSheet extends StatefulWidget {
  final Address? existing;
  final String userEmail;

  const _AddressFormSheet({this.existing, required this.userEmail});

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _line1Controller;
  late final TextEditingController _cityController;
  late final TextEditingController _pincodeController;
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.fullName ?? '');
    _phoneController = TextEditingController(text: widget.existing?.phone ?? '');
    _line1Controller = TextEditingController(text: widget.existing?.line1 ?? '');
    _cityController = TextEditingController(text: widget.existing?.city ?? '');
    _pincodeController = TextEditingController(text: widget.existing?.pincode ?? '');
    _isDefault = widget.existing?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _line1Controller.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final box = Hive.box<Address>('addresses');

    if (_isDefault) {
      for (final a in box.values.where((a) => a.userEmail == widget.userEmail)) {
        a.isDefault = false;
        await a.save();
      }
    }

    if (widget.existing != null) {
      widget.existing!
        ..fullName = _nameController.text.trim()
        ..phone = _phoneController.text.trim()
        ..line1 = _line1Controller.text.trim()
        ..city = _cityController.text.trim()
        ..pincode = _pincodeController.text.trim()
        ..isDefault = _isDefault;
      await widget.existing!.save();
    } else {
      await box.add(Address(
        id: const Uuid().v4(),
        userEmail: widget.userEmail,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        line1: _line1Controller.text.trim(),
        city: _cityController.text.trim(),
        pincode: _pincodeController.text.trim(),
        isDefault: _isDefault,
      ));
    }

    setState(() => _isLoading = false);
    if (mounted) Navigator.of(context).pop();
  }

  Widget _field(TextEditingController c, String label,
      {TextInputType? type, String? Function(String?)? validator}) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final darkText = Theme.of(context).colorScheme.onSurface;
    final greyText = Theme.of(context).colorScheme.onSurface.withAlpha(150);
    final errorColor = Theme.of(context).colorScheme.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        validator: validator ?? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null,
        style: TextStyle(fontSize: 15, color: darkText),
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.never,
          labelStyle: TextStyle(color: greyText, fontSize: 14),
          filled: true,
          fillColor: bgColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: errorColor, width: 1.5)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryBlue = Theme.of(context).colorScheme.primary;
    final darkText = Theme.of(context).colorScheme.onSurface;
    final cardWhite = Theme.of(context).cardColor;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.existing != null ? 'Edit Address' : 'Add New Address',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: darkText)),
                const SizedBox(height: 20),
                _field(_nameController, 'Full Name'),
                _field(_phoneController, 'Phone', type: TextInputType.phone,
                    validator: (v) => (v == null || !RegExp(r'^\d{10}$').hasMatch(v.trim()))
                        ? 'Enter valid 10-digit number'
                        : null),
                _field(_line1Controller, 'Address Line 1'),
                _field(_cityController, 'City'),
                _field(_pincodeController, 'Pincode', type: TextInputType.number,
                    validator: (v) => (v == null || !RegExp(r'^\d{6}$').hasMatch(v.trim()))
                        ? 'Enter valid 6-digit pincode'
                        : null),
                Row(
                  children: [
                    Checkbox(
                      value: _isDefault,
                      onChanged: (v) => setState(() => _isDefault = v ?? false),
                      activeColor: primaryBlue,
                    ),
                    Text('Set as default address',
                        style: TextStyle(fontSize: 14, color: darkText)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Text(widget.existing != null ? 'Save Changes' : 'Add Address',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}