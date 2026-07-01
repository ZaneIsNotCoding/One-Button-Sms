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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD71920),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const HomeScreen(),
    );
  }
}

class EmergencyContact {
  const EmergencyContact({
    required this.name,
    required this.number,
    required this.relationship,
    this.priority = false,
  });

  final String name;
  final String number;
  final String relationship;
  final bool priority;

  EmergencyContact copyWith({
    String? name,
    String? number,
    String? relationship,
    bool? priority,
  }) {
    return EmergencyContact(
      name: name ?? this.name,
      number: number ?? this.number,
      relationship: relationship ?? this.relationship,
      priority: priority ?? this.priority,
    );
  }
}

class SmsLog {
  const SmsLog({
    required this.receiver,
    required this.message,
    required this.sentAt,
    required this.status,
  });

  final String receiver;
  final String message;
  final DateTime sentAt;
  final String status;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.userName = 'User'});

  final String userName;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;
  bool includeLocation = true;
  String emergencyMessage =
      'Emergency Alert! I need assistance. Please contact me immediately.';

  final contacts = <EmergencyContact>[
    const EmergencyContact(
      name: 'Mother',
      number: '09123456789',
      relationship: 'Family',
      priority: true,
    ),
    const EmergencyContact(
      name: 'Brother',
      number: '09987654321',
      relationship: 'Family',
      priority: true,
    ),
    const EmergencyContact(
      name: 'Security',
      number: '09111111111',
      relationship: 'Responder',
    ),
  ];

  final logs = <SmsLog>[
    SmsLog(
      receiver: 'Mother',
      message: 'Emergency Alert',
      sentAt: DateTime(2026, 6, 29, 20, 30),
      status: 'Sent',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardTab(
        userName: widget.userName.isEmpty ? 'User' : widget.userName,
        contacts: contacts,
        logs: logs,
        message: emergencyMessage,
        includeLocation: includeLocation,
        onSendAlert: confirmAlert,
      ),
      ContactsTab(
        contacts: contacts,
        onAdd: () => editContact(),
        onEdit: editContact,
        onDelete: (contact) {
          setState(() => contacts.remove(contact));
        },
      ),
      MessageTab(
        message: emergencyMessage,
        includeLocation: includeLocation,
        onChanged: (value) => setState(() => emergencyMessage = value),
        onLocationChanged: (value) => setState(() => includeLocation = value),
      ),
      HistoryTab(logs: logs),
      AdminTab(users: 12, alertsToday: logs.length, contacts: contacts.length),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('One Button SMS'),
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.contacts_outlined),
            selectedIcon: Icon(Icons.contacts),
            label: 'Contacts',
          ),
          NavigationDestination(
            icon: Icon(Icons.message_outlined),
            selectedIcon: Icon(Icons.message),
            label: 'Message',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Logs',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
        ],
      ),
    );
  }

  Future<void> confirmAlert() async {
    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one emergency contact.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send emergency alert?'),
        content: Text(
          'This will send your emergency message to ${contacts.length} contacts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.sms),
            label: const Text('Send Alert'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final message = includeLocation
        ? '$emergencyMessage\nLocation: https://maps.google.com/?q=14.5995,120.9842'
        : emergencyMessage;

    setState(() {
      for (final contact in contacts) {
        logs.insert(
          0,
          SmsLog(
            receiver: contact.name,
            message: message,
            sentAt: DateTime.now(),
            status: 'Sent',
          ),
        );
      }
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Emergency alert sent to ${contacts.length} contacts.')),
    );
  }

  Future<void> editContact([EmergencyContact? existing]) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final numberController =
        TextEditingController(text: existing?.number ?? '');
    final relationshipController =
        TextEditingController(text: existing?.relationship ?? '');
    var priority = existing?.priority ?? false;

    final saved = await showDialog<EmergencyContact>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Contact' : 'Edit Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Contact name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: numberController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: relationshipController,
                  decoration: const InputDecoration(
                    labelText: 'Relationship',
                    border: OutlineInputBorder(),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Priority contact'),
                  value: priority,
                  onChanged: (value) {
                    setDialogState(() => priority = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  EmergencyContact(
                    name: nameController.text.trim(),
                    number: numberController.text.trim(),
                    relationship: relationshipController.text.trim(),
                    priority: priority,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    numberController.dispose();
    relationshipController.dispose();

    if (saved == null || saved.name.isEmpty || saved.number.isEmpty) return;

    setState(() {
      if (existing == null) {
        contacts.add(saved);
      } else {
        final index = contacts.indexOf(existing);
        contacts[index] = saved;
      }
    });
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({
    super.key,
    required this.userName,
    required this.contacts,
    required this.logs,
    required this.message,
    required this.includeLocation,
    required this.onSendAlert,
  });

  final String userName;
  final List<EmergencyContact> contacts;
  final List<SmsLog> logs;
  final String message;
  final bool includeLocation;
  final VoidCallback onSendAlert;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Welcome, $userName',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              FilledButton(
                onPressed: onSendAlert,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD71920),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(132),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 46),
                    SizedBox(height: 10),
                    Text(
                      'SEND EMERGENCY ALERT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                includeLocation
                    ? '$message\nLocation link will be included.'
                    : message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            StatTile(
              icon: Icons.contacts,
              label: 'Contacts',
              value: '${contacts.length}',
            ),
            StatTile(
              icon: Icons.priority_high,
              label: 'Priority',
              value: '${contacts.where((item) => item.priority).length}',
            ),
            StatTile(
              icon: Icons.history,
              label: 'Last Alert',
              value: logs.isEmpty ? 'None' : formatDateTime(logs.first.sentAt),
            ),
          ],
        ),
      ],
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class ContactsTab extends StatelessWidget {
  const ContactsTab({
    super.key,
    required this.contacts,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<EmergencyContact> contacts;
  final VoidCallback onAdd;
  final ValueChanged<EmergencyContact> onEdit;
  final ValueChanged<EmergencyContact> onDelete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemBuilder: (context, index) {
          final contact = contacts[index];
          return ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            leading: CircleAvatar(
              backgroundColor: contact.priority
                  ? const Color(0xFFFFE4E6)
                  : const Color(0xFFE0F2FE),
              child: Icon(
                contact.priority ? Icons.star : Icons.person,
                color: contact.priority
                    ? const Color(0xFFD71920)
                    : const Color(0xFF0369A1),
              ),
            ),
            title: Text(contact.name),
            subtitle: Text('${contact.number} • ${contact.relationship}'),
            trailing: Wrap(
              children: [
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () => onEdit(contact),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () => onDelete(contact),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemCount: contacts.length,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add Contact'),
      ),
    );
  }
}

class MessageTab extends StatelessWidget {
  const MessageTab({
    super.key,
    required this.message,
    required this.includeLocation,
    required this.onChanged,
    required this.onLocationChanged,
  });

  final String message;
  final bool includeLocation;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool> onLocationChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Emergency Message',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: message,
          maxLines: 6,
          onChanged: onChanged,
          decoration: const InputDecoration(
            labelText: 'Message content',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          title: const Text('Include location link'),
          subtitle: const Text('Adds a map link to the emergency SMS.'),
          value: includeLocation,
          onChanged: onLocationChanged,
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Message saved.')),
            );
          },
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save Message'),
        ),
      ],
    );
  }
}

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key, required this.logs});

  final List<SmsLog> logs;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Center(child: Text('No emergency alerts sent yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemBuilder: (context, index) {
        final log = logs[index];
        return ListTile(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          leading: const Icon(Icons.sms_outlined),
          title: Text(log.receiver),
          subtitle: Text('${formatDateTime(log.sentAt)}\n${log.message}'),
          isThreeLine: true,
          trailing: Chip(
            label: Text(log.status),
            avatar: const Icon(Icons.check_circle, size: 18),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemCount: logs.length,
    );
  }
}

class AdminTab extends StatelessWidget {
  const AdminTab({
    super.key,
    required this.users,
    required this.alertsToday,
    required this.contacts,
  });

  final int users;
  final int alertsToday;
  final int contacts;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Admin Dashboard',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            StatTile(
                icon: Icons.group_outlined, label: 'Users', value: '$users'),
            StatTile(
              icon: Icons.notification_important_outlined,
              label: 'Alerts Today',
              value: '$alertsToday',
            ),
            StatTile(
              icon: Icons.contact_phone_outlined,
              label: 'Contacts',
              value: '$contacts',
            ),
          ],
        ),
        const SizedBox(height: 20),
        ListTile(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          leading: const Icon(Icons.manage_accounts_outlined),
          title: const Text('Manage users'),
          subtitle: const Text('Organization accounts and access control'),
          trailing: const Icon(Icons.chevron_right),
        ),
        const SizedBox(height: 10),
        ListTile(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          leading: const Icon(Icons.analytics_outlined),
          title: const Text('SMS activity'),
          subtitle: const Text('Monitor sent alerts and delivery status'),
          trailing: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

String formatDateTime(DateTime value) {
  final hour = value.hour > 12 ? value.hour - 12 : value.hour;
  final displayHour = hour == 0 ? 12 : hour;
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '${monthName(value.month)} ${value.day}, $displayHour:$minute $suffix';
}

String monthName(int month) {
  const names = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return names[month - 1];
}
