import 'package:flutter/material.dart';

void main() {
  runApp(const OneButtonSmsApp());
}

class OneButtonSmsApp extends StatelessWidget {
  const OneButtonSmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'One Button SMS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class EmergencyContact {
  const EmergencyContact({required this.name, required this.phone});

  final String name;
  final String phone;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<EmergencyContact> _contacts = [];
  int _selectedPage = 0;
  String _status = 'Ready to send';

  void _sendMessage() {
    setState(() {
      _status = 'SMS sending is not connected yet';
    });
  }

  void _sendToAddedContacts() {
    setState(() {
      if (_contacts.isEmpty) {
        _status = 'Add a contact before using Contact SOS';
        _selectedPage = 1;
        return;
      }

      _status = 'Contact SOS ready for ${_contacts.length} contact(s)';
    });
  }

  void _addContact(EmergencyContact contact) {
    setState(() {
      _contacts.add(contact);
      _status = 'Added ${contact.name}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      SmsHomePage(
        status: _status,
        contactCount: _contacts.length,
        onSendMessage: _sendMessage,
        onSendToContacts: _sendToAddedContacts,
      ),
      ContactsPage(contacts: _contacts, onAddContact: _addContact),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('One Button SMS'), centerTitle: true),
      body: pages[_selectedPage],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedPage,
        onDestinationSelected: (index) {
          setState(() => _selectedPage = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sms_outlined),
            selectedIcon: Icon(Icons.sms),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.contacts_outlined),
            selectedIcon: Icon(Icons.contacts),
            label: 'Contacts',
          ),
        ],
      ),
    );
  }
}

class SmsHomePage extends StatelessWidget {
  const SmsHomePage({
    super.key,
    required this.status,
    required this.contactCount,
    required this.onSendMessage,
    required this.onSendToContacts,
  });

  final String status;
  final int contactCount;
  final VoidCallback onSendMessage;
  final VoidCallback onSendToContacts;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.sms_outlined, size: 72, color: colors.primary),
            const SizedBox(height: 24),
            Text(
              'Send your preset SMS with one tap.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              status,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              '$contactCount added contact(s)',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 36),
            FilledButton.icon(
              onPressed: onSendMessage,
              icon: const Icon(Icons.send),
              label: const Text('Send SMS'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                textStyle: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: onSendToContacts,
              icon: const Icon(Icons.emergency_share),
              label: const Text('Contact SOS'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                textStyle: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContactsPage extends StatelessWidget {
  const ContactsPage({
    super.key,
    required this.contacts,
    required this.onAddContact,
  });

  final List<EmergencyContact> contacts;
  final ValueChanged<EmergencyContact> onAddContact;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: contacts.isEmpty
            ? const Center(child: Text('No contacts added yet.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: contacts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  return ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(contact.name),
                    subtitle: Text(contact.phone),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddContactDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Contact'),
      ),
    );
  }

  Future<void> _showAddContactDialog(BuildContext context) async {
    final contact = await showDialog<EmergencyContact>(
      context: context,
      builder: (context) => const AddContactDialog(),
    );

    if (contact != null) {
      onAddContact(contact);
    }
  }
}

class AddContactDialog extends StatefulWidget {
  const AddContactDialog({super.key});

  @override
  State<AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<AddContactDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      return;
    }

    Navigator.pop(context, EmergencyContact(name: name, phone: phone));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Contact'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone number',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
