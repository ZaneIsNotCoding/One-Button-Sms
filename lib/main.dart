import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      home: const StartupScreen(),
    );
  }
}

class DeviceLocation {
  const DeviceLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  String get mapUrl => 'https://maps.google.com/?q=$latitude,$longitude';
}

class AppServices {
  static const _channel = MethodChannel('one_button_sms/device');

  static Future<bool> requestPermissions() async {
    try {
      final granted = await _channel.invokeMethod<bool>('requestPermissions');
      return granted ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<DeviceLocation?> getLocation() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getLocation',
      );
      if (result == null) return null;
      return DeviceLocation(
        latitude: (result['latitude'] as num).toDouble(),
        longitude: (result['longitude'] as num).toDouble(),
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  static Future<int> sendSms({
    required List<String> recipients,
    required String message,
  }) async {
    try {
      final sent = await _channel.invokeMethod<int>('sendSms', {
        'recipients': recipients,
        'message': message,
      });
      return sent ?? 0;
    } on PlatformException {
      return 0;
    } on MissingPluginException {
      return 0;
    }
  }
}

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController animationController;
  String status = 'Preparing emergency tools...';

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    boot();
  }

  Future<void> boot() async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() => status = 'Requesting phone permissions...');

    final permissionsGranted = await AppServices.requestPermissions();
    final location =
        permissionsGranted ? await AppServices.getLocation() : null;

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          permissionsGranted: permissionsGranted,
          initialLocation: location,
        ),
      ),
    );
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.45, end: 1).animate(
            CurvedAnimation(
              parent: animationController,
              curve: Curves.easeInOut,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: Color(0xFFD71920),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emergency_share,
                  color: Colors.white,
                  size: 46,
                ),
              ),
              const SizedBox(height: 22),
              const CircularProgressIndicator(),
              const SizedBox(height: 18),
              Text(status, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
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

class EmergencyTypeData {
  const EmergencyTypeData({
    required this.id,
    required this.label,
    required this.agency,
    required this.description,
    required this.icon,
    required this.color,
    required this.agencyContacts,
    required this.messagePrefix,
  });

  final String id;
  final String label;
  final String agency;
  final String description;
  final IconData icon;
  final Color color;
  final List<EmergencyContact> agencyContacts;
  final String messagePrefix;
}

const emergencyTypes = <EmergencyTypeData>[
  EmergencyTypeData(
    id: 'robbery',
    label: 'Robbery / Crime',
    agency: 'PNP',
    description: 'Police assistance',
    icon: Icons.local_police,
    color: Color(0xFFD71920),
    agencyContacts: [
      EmergencyContact(
        name: 'Philippine National Police',
        number: '911',
        relationship: 'PNP',
        priority: true,
      ),
      EmergencyContact(
        name: 'PNP Hotline',
        number: '117',
        relationship: 'PNP',
        priority: true,
      ),
    ],
    messagePrefix:
        'SOS ROBBERY/CRIME ALERT! I am in danger and need police assistance immediately.',
  ),
  EmergencyTypeData(
    id: 'fire',
    label: 'Fire',
    agency: 'BFP',
    description: 'Fire emergency',
    icon: Icons.local_fire_department,
    color: Color(0xFFEA580C),
    agencyContacts: [
      EmergencyContact(
        name: 'Bureau of Fire Protection',
        number: '911',
        relationship: 'BFP',
        priority: true,
      ),
      EmergencyContact(
        name: 'BFP Hotline',
        number: '160',
        relationship: 'BFP',
        priority: true,
      ),
    ],
    messagePrefix:
        'SOS FIRE ALERT! There is a fire emergency at my location. Please send help immediately.',
  ),
  EmergencyTypeData(
    id: 'assistance',
    label: 'Need Help',
    agency: 'Barangay / Rescue',
    description: 'General emergency',
    icon: Icons.support_agent,
    color: Color(0xFF0369A1),
    agencyContacts: [
      EmergencyContact(
        name: 'Emergency Hotline',
        number: '911',
        relationship: 'Responder',
        priority: true,
      ),
    ],
    messagePrefix:
        'SOS HELP NEEDED! I need immediate assistance. Please send help.',
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.userName = 'User',
    this.permissionsGranted = false,
    this.initialLocation,
  });

  final String userName;
  final bool permissionsGranted;
  final DeviceLocation? initialLocation;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;
  String selectedEmergencyId = emergencyTypes.first.id;
  bool includeLocation = true;
  late bool permissionsGranted;
  DeviceLocation? currentLocation;
  bool refreshingLocation = false;
  bool sendingAlert = false;
  String emergencyMessage =
      'Emergency Alert! I need assistance. Please contact me immediately.';

  late final Map<String, List<EmergencyContact>> emergencyContacts;
  final logs = <SmsLog>[];

  @override
  void initState() {
    super.initState();
    permissionsGranted = widget.permissionsGranted;
    currentLocation = widget.initialLocation;
    emergencyContacts = {
      for (final type in emergencyTypes) type.id: [...type.agencyContacts],
    };
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardTab(
        contactCount: emergencyContacts[selectedEmergencyId]?.length ?? 0,
        emergencyTypes: emergencyTypes,
        selectedEmergencyId: selectedEmergencyId,
        includeLocation: includeLocation,
        currentLocation: currentLocation,
        permissionsGranted: permissionsGranted,
        sendingAlert: sendingAlert,
        onEmergencySelected: (id) => setState(() => selectedEmergencyId = id),
        onSendAlert: confirmAlert,
        onRefreshLocation: refreshLocation,
      ),
      ContactsTab(
        emergencyTypes: emergencyTypes,
        emergencyContacts: emergencyContacts,
        onAdd: (typeId) => editContact(typeId),
        onEdit: editContact,
        onDelete: (typeId, contact) {
          setState(() => emergencyContacts[typeId]?.remove(contact));
        },
      ),
      MessageTab(
        message: emergencyMessage,
        includeLocation: includeLocation,
        onChanged: (value) => setState(() => emergencyMessage = value),
        onLocationChanged: (value) => setState(() => includeLocation = value),
      ),
      HistoryTab(logs: logs),
      LocationTab(
        location: currentLocation,
        permissionsGranted: permissionsGranted,
        refreshing: refreshingLocation,
        onRefresh: refreshLocation,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('One Button SMS'),
        backgroundColor: const Color(0xFFD71920),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Contacts',
            onPressed: () => setState(() => selectedIndex = 1),
            icon: const Icon(Icons.group),
          ),
          IconButton(
            tooltip: 'Message',
            onPressed: () => setState(() => selectedIndex = 2),
            icon: const Icon(Icons.settings),
          ),
        ],
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
            label: 'SOS',
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
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
        ],
      ),
    );
  }

  Future<void> refreshLocation() async {
    if (refreshingLocation) return;
    setState(() => refreshingLocation = true);

    var granted = permissionsGranted;
    if (!granted) {
      granted = await AppServices.requestPermissions();
    }
    final location = granted ? await AppServices.getLocation() : null;

    if (!mounted) return;
    setState(() {
      permissionsGranted = granted;
      currentLocation = location ?? currentLocation;
      refreshingLocation = false;
    });

    final message = location == null
        ? 'Location unavailable. Turn on GPS and allow location permission.'
        : 'Location updated.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> confirmAlert() async {
    if (sendingAlert) return;

    final messenger = ScaffoldMessenger.of(context);
    final emergencyType = emergencyTypes.firstWhere(
      (type) => type.id == selectedEmergencyId,
      orElse: () => emergencyTypes.first,
    );
    final recipients = emergencyRecipients(emergencyType);

    if (recipients.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Add at least one emergency contact.')),
      );
      return;
    }

    setState(() => sendingAlert = true);

    DeviceLocation? location = currentLocation;
    if (includeLocation) {
      location = await AppServices.getLocation() ?? currentLocation;
      if (!mounted) return;
      setState(() => currentLocation = location);
    }

    final message = buildSosMessage(emergencyType, location);
    final sentCount = await AppServices.sendSms(
      recipients: recipients.map((contact) => contact.number).toList(),
      message: message,
    );

    if (!mounted) return;

    setState(() {
      sendingAlert = false;
      for (final contact in recipients) {
        logs.insert(
          0,
          SmsLog(
            receiver: contact.name,
            message: message,
            sentAt: DateTime.now(),
            status: sentCount > 0 ? 'Sent' : 'Failed',
          ),
        );
      }
    });

    messenger.showSnackBar(
      SnackBar(content: Text('Emergency alert sent to $sentCount contacts.')),
    );
  }

  List<EmergencyContact> emergencyRecipients(EmergencyTypeData emergencyType) {
    final recipients = emergencyContacts[emergencyType.id] ?? [];
    final seen = <String>{};

    return recipients.where((contact) {
      final number = contact.number.trim();
      if (number.isEmpty || seen.contains(number)) return false;
      seen.add(number);
      return true;
    }).toList();
  }

  String buildSosMessage(
      EmergencyTypeData emergencyType, DeviceLocation? location) {
    final locationText = includeLocation && location != null
        ? '\nLocation: ${location.mapUrl}'
        : '';
    final customText = emergencyMessage.trim().isEmpty
        ? ''
        : '\nMessage: ${emergencyMessage.trim()}';

    return '${emergencyType.messagePrefix}$locationText$customText';
  }

  Future<void> editContact(String typeId, [EmergencyContact? existing]) async {
    final saved = await showDialog<EmergencyContact>(
      context: context,
      builder: (context) => ContactDialog(existing: existing),
    );

    if (saved == null || saved.name.isEmpty || saved.number.isEmpty) return;
    if (!mounted) return;

    setState(() {
      final contacts = emergencyContacts[typeId] ??= [];
      if (existing == null) {
        contacts.add(saved);
      } else {
        final index = contacts.indexOf(existing);
        if (index != -1) {
          contacts[index] = saved;
        }
      }
    });
  }
}

class ContactDialog extends StatefulWidget {
  const ContactDialog({super.key, this.existing});

  final EmergencyContact? existing;

  @override
  State<ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<ContactDialog> {
  late final TextEditingController nameController;
  late final TextEditingController numberController;
  late final TextEditingController relationshipController;
  late bool priority;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    nameController = TextEditingController(text: existing?.name ?? '');
    numberController = TextEditingController(text: existing?.number ?? '');
    relationshipController = TextEditingController(
      text: existing?.relationship ?? '',
    );
    priority = existing?.priority ?? false;
  }

  @override
  void dispose() {
    nameController.dispose();
    numberController.dispose();
    relationshipController.dispose();
    super.dispose();
  }

  void save() {
    Navigator.pop(
      context,
      EmergencyContact(
        name: nameController.text.trim(),
        number: numberController.text.trim(),
        relationship: relationshipController.text.trim(),
        priority: priority,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Contact' : 'Edit Contact'),
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
                setState(() => priority = value);
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
          onPressed: save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({
    super.key,
    required this.contactCount,
    required this.emergencyTypes,
    required this.selectedEmergencyId,
    required this.includeLocation,
    required this.currentLocation,
    required this.permissionsGranted,
    required this.sendingAlert,
    required this.onEmergencySelected,
    required this.onSendAlert,
    required this.onRefreshLocation,
  });

  final int contactCount;
  final List<EmergencyTypeData> emergencyTypes;
  final String selectedEmergencyId;
  final bool includeLocation;
  final DeviceLocation? currentLocation;
  final bool permissionsGranted;
  final bool sendingAlert;
  final ValueChanged<String> onEmergencySelected;
  final VoidCallback onSendAlert;
  final VoidCallback onRefreshLocation;

  @override
  Widget build(BuildContext context) {
    final selectedEmergency = emergencyTypes.firstWhere(
      (type) => type.id == selectedEmergencyId,
      orElse: () => emergencyTypes.first,
    );
    final locationLabel = currentLocation == null
        ? 'Location not ready'
        : '${currentLocation!.latitude.toStringAsFixed(5)}, '
            '${currentLocation!.longitude.toStringAsFixed(5)}';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            'Activate SOS and panic alarm to alert emergency contacts',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.black54,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: emergencyTypes.map((type) {
              final selected = type.id == selectedEmergencyId;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onEmergencySelected(type.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? type.color : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              selected ? type.color : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            type.icon,
                            color: selected ? Colors.white : type.color,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            type.agency,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: Center(
            child: GestureDetector(
              onTap: sendingAlert ? null : onSendAlert,
              child: Container(
                width: 224,
                height: 224,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF1F5F9),
                  boxShadow: [
                    BoxShadow(
                      color: selectedEmergency.color.withValues(alpha: 0.22),
                      blurRadius: 34,
                      spreadRadius: 12,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 176,
                    height: 176,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selectedEmergency.color,
                    ),
                    child: Center(
                      child: sendingAlert
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'SOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          child: Column(
            children: [
              Text(
                'Alerting: ${selectedEmergency.agency}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$contactCount ${selectedEmergency.agency} contact(s) ready',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onRefreshLocation,
                      icon: const Icon(Icons.my_location),
                      label: Text(
                        permissionsGranted ? locationLabel : 'Allow Location',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const _QuickStatus(icon: Icons.sms_outlined, label: 'SMS'),
              _QuickStatus(
                icon: includeLocation
                    ? Icons.location_on_outlined
                    : Icons.location_off_outlined,
                label: includeLocation ? 'GPS' : 'No GPS',
              ),
              const _QuickStatus(
                icon: Icons.people_outline,
                label: 'Contacts',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickStatus extends StatelessWidget {
  const _QuickStatus({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFD71920), size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class ContactsTab extends StatelessWidget {
  const ContactsTab({
    super.key,
    required this.emergencyTypes,
    required this.emergencyContacts,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<EmergencyTypeData> emergencyTypes;
  final Map<String, List<EmergencyContact>> emergencyContacts;
  final ValueChanged<String> onAdd;
  final void Function(String typeId, EmergencyContact contact) onEdit;
  final void Function(String typeId, EmergencyContact contact) onDelete;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: emergencyTypes.length,
      child: Scaffold(
        appBar: TabBar(
          isScrollable: true,
          tabs: [
            for (final type in emergencyTypes)
              Tab(icon: Icon(type.icon), text: type.agency),
          ],
        ),
        body: TabBarView(
          children: [
            for (final type in emergencyTypes)
              AgencyContactsList(
                type: type,
                contacts: emergencyContacts[type.id] ?? const [],
                onAdd: () => onAdd(type.id),
                onEdit: (contact) => onEdit(type.id, contact),
                onDelete: (contact) => onDelete(type.id, contact),
              ),
          ],
        ),
      ),
    );
  }
}

class AgencyContactsList extends StatelessWidget {
  const AgencyContactsList({
    super.key,
    required this.type,
    required this.contacts,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final EmergencyTypeData type;
  final List<EmergencyContact> contacts;
  final VoidCallback onAdd;
  final ValueChanged<EmergencyContact> onEdit;
  final ValueChanged<EmergencyContact> onDelete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: contacts.isEmpty
          ? Center(child: Text('No ${type.agency} contacts yet.'))
          : ListView.separated(
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
                      contact.priority ? Icons.star : type.icon,
                      color: contact.priority
                          ? const Color(0xFFD71920)
                          : type.color,
                    ),
                  ),
                  title: Text(contact.name),
                  subtitle: Text('${contact.number} - ${contact.relationship}'),
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
        label: Text('Add ${type.agency} Contact'),
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

class LocationTab extends StatelessWidget {
  const LocationTab({
    super.key,
    required this.location,
    required this.permissionsGranted,
    required this.refreshing,
    required this.onRefresh,
  });

  final DeviceLocation? location;
  final bool permissionsGranted;
  final bool refreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final mapUrl = location?.mapUrl;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Map Location',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 14),
        Container(
          height: 220,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFBAE6FD)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.map, size: 58, color: Color(0xFF0369A1)),
              const SizedBox(height: 12),
              Text(
                mapUrl ?? 'GPS location has not been captured yet.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                permissionsGranted
                    ? 'This location is used in emergency SMS messages.'
                    : 'Allow location permission to attach your real position.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: refreshing ? null : onRefresh,
          icon: refreshing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
          label: Text(refreshing ? 'Finding Location...' : 'Update Location'),
        ),
        if (location != null) ...[
          const SizedBox(height: 14),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            leading: const Icon(Icons.place_outlined),
            title: const Text('Coordinates'),
            subtitle: Text('${location!.latitude}, ${location!.longitude}'),
          ),
        ],
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
