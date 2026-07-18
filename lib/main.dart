import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend/app_backend.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppBackend.instance.initialize();
  runApp(const AmbarDirectApp());
}

const _maroon = Color(0xFF641B23);
const _gold = Color(0xFFE9B44C);
const _cream = Color(0xFFFFF8ED);

class RestaurantLocation {
  const RestaurantLocation({
    required this.name,
    required this.neighborhood,
    required this.address,
    required this.services,
  });

  final String name;
  final String neighborhood;
  final String address;
  final List<String> services;
}

class ManagerEntry extends StatefulWidget {
  const ManagerEntry({super.key});

  @override
  State<ManagerEntry> createState() => _ManagerEntryState();
}

class _ManagerEntryState extends State<ManagerEntry> {
  final email = TextEditingController();
  final password = TextEditingController();
  String message = '';
  bool submitting = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    if (!AppBackend.instance.configured) {
      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const ManagerShell()));
      }
      return;
    }
    final client = AppBackend.instance.client;
    if (client == null) return;
    setState(() {
      submitting = true;
      message = '';
    });
    try {
      await client.auth.signInWithPassword(
          email: email.text.trim(), password: password.text);
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const ManagerShell()));
    } on AuthException catch (error) {
      if (mounted) setState(() => message = error.message);
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AppBackend.instance.configured) return const ManagerShell();
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MANAGER ACCESS',
                        style: TextStyle(
                            color: _maroon,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    const Text('Sign in to your workspace',
                        style: TextStyle(
                            fontSize: 27, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 22),
                    TextField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                            labelText: 'Email', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(
                        controller: password,
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder())),
                    if (message.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(message,
                              style: const TextStyle(color: Colors.red))),
                    const SizedBox(height: 16),
                    FilledButton(
                        onPressed: submitting ? null : signIn,
                        style: FilledButton.styleFrom(
                            backgroundColor: _maroon,
                            minimumSize: const Size.fromHeight(50)),
                        child: Text(submitting ? 'Signing in…' : 'Sign in')),
                    const SizedBox(height: 8),
                    const Text(
                        'Your role and location access are loaded from the workspace profile.',
                        style: TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ManagerShell extends StatefulWidget {
  const ManagerShell({super.key});

  @override
  State<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends State<ManagerShell> {
  int section = 0;
  String location = 'Clifton';
  StaffContext? staff;
  List<LocationRecord> liveLocations = const [];
  bool loadingLiveData = false;
  final sections = const [
    'Overview',
    'POS',
    'Kitchen',
    'Analytics',
    'Reservations',
    'Menu',
    'Settings',
  ];
  final icons = const [
    Icons.dashboard_outlined,
    Icons.point_of_sale_outlined,
    Icons.kitchen_outlined,
    Icons.insights_outlined,
    Icons.event_available_outlined,
    Icons.restaurant_menu_outlined,
    Icons.settings_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _loadLiveContext();
  }

  Future<void> _loadLiveContext() async {
    if (!AppBackend.instance.configured) return;
    final client = AppBackend.instance.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;
    setState(() => loadingLiveData = true);
    try {
      final loadedStaff = await loadStaffContext(client, user);
      final loadedLocations = await loadLocations(client,
          organizationId: loadedStaff?.organizationId);
      if (!mounted) return;
      setState(() {
        staff = loadedStaff;
        liveLocations = loadedLocations;
        if (loadedLocations.isNotEmpty)
          location =
              loadedLocations.first.name.replaceFirst('Ambar India ', '');
      });
    } finally {
      if (mounted) setState(() => loadingLiveData = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    final content = _page();
    return Scaffold(
      appBar: AppBar(
        title: Text('Manager · ${sections[section]}'),
        actions: [
          if (loadingLiveData)
            const Padding(
                padding: EdgeInsets.only(right: 12),
                child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: location,
              items: (liveLocations.isEmpty
                      ? const ['Clifton', 'Downtown', 'Events']
                      : liveLocations
                          .map((item) =>
                              item.name.replaceFirst('Ambar India ', ''))
                          .toList())
                  .map((name) =>
                      DropdownMenuItem(value: name, child: Text(name)))
                  .toList(),
              onChanged: (value) => setState(() => location = value!),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        children: [
          if (!compact) _rail(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Padding(
                key: ValueKey(section),
                padding: const EdgeInsets.all(16),
                child: content,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: compact
          ? NavigationBar(
              selectedIndex: section,
              onDestinationSelected: (value) => setState(() => section = value),
              destinations: [
                for (var i = 0; i < sections.length; i++)
                  NavigationDestination(
                    icon: Icon(icons[i]),
                    label: sections[i],
                  ),
              ],
            )
          : null,
    );
  }

  Widget _rail() => NavigationRail(
        selectedIndex: section,
        onDestinationSelected: (value) => setState(() => section = value),
        labelType: NavigationRailLabelType.all,
        destinations: [
          for (var i = 0; i < sections.length; i++)
            NavigationRailDestination(
              icon: Icon(icons[i]),
              label: Text(sections[i]),
            ),
        ],
      );

  Widget _page() {
    switch (section) {
      case 1:
        return LivePosPreview(locationId: _selectedLocationId);
      case 2:
        return LiveKitchenPreview(locationId: _selectedLocationId);
      case 3:
        return const AnalyticsPreview();
      case 4:
        return LiveReservationsPreview(locationId: _selectedLocationId);
      case 5:
        return MenuPreview(locationId: _selectedLocationId);
      case 6:
        return const SettingsPreview();
      default:
        return const OverviewPreview();
    }
  }

  String? get _selectedLocationId {
    for (final item in liveLocations) {
      if (item.name.replaceFirst('Ambar India ', '') == location)
        return item.id;
    }
    return null;
  }
}

class OverviewPreview extends StatelessWidget {
  const OverviewPreview({super.key});
  @override
  Widget build(BuildContext context) => ListView(
        children: [
          const _SectionIntro(
            eyebrow: 'Today at a glance',
            title: 'Service is ready',
            detail: 'Monitor every location from one calm dashboard.',
          ),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.sizeOf(context).width > 800 ? 4 : 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: const [
              _MetricCard('Paid sales', '\$4,280', Icons.payments_outlined),
              _MetricCard('Orders', '86', Icons.receipt_long_outlined),
              _MetricCard('Walk-ins', '31', Icons.storefront_outlined),
              _MetricCard(
                  'Kitchen now', '7', Icons.local_fire_department_outlined),
            ],
          ),
          const SizedBox(height: 16),
          _Panel(
            title: 'Action centre',
            children: [
              ListTile(
                leading: Icon(Icons.circle, color: _gold),
                title: Text('3 new kitchen tickets'),
                subtitle: Text('Review and start preparing orders.'),
                trailing: Icon(Icons.chevron_right),
              ),
              ListTile(
                leading: Icon(Icons.event_available_outlined, color: _maroon),
                title: Text('4 reservations awaiting confirmation'),
                trailing: Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      );
}

class LivePosPreview extends StatefulWidget {
  const LivePosPreview({super.key, this.locationId});
  final String? locationId;
  @override
  State<LivePosPreview> createState() => _LivePosPreviewState();
}

class _LivePosPreviewState extends State<LivePosPreview> {
  List<MenuItemRecord> menu = const [];
  List<MenuItemRecord> cart = const [];
  OrderRecord? openOrder;
  bool loading = false;
  String message = '';
  String guest = '';
  String table = '1';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant LivePosPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locationId != widget.locationId) _load();
  }

  Future<void> _load() async {
    if (!AppBackend.instance.configured || widget.locationId == null) return;
    final client = AppBackend.instance.client;
    if (client == null) return;
    setState(() => loading = true);
    try {
      final next = await loadMenuItems(client, widget.locationId!);
      if (mounted)
        setState(() => menu = next.where((item) => item.available).toList());
    } catch (_) {
      if (mounted) setState(() => message = 'Menu is unavailable.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _add(MenuItemRecord item) => setState(() => cart = [...cart, item]);
  Future<void> _sendOrder() async {
    final client = AppBackend.instance.client;
    if (client == null || widget.locationId == null || cart.isEmpty) return;
    setState(() => message = 'Sending order to the kitchen…');
    try {
      final order = await createWalkInOrder(
          client: client,
          locationId: widget.locationId!,
          orderType: 'dine-in',
          items: cart,
          guestName: guest.isEmpty ? null : guest,
          tableNumber: table);
      if (mounted)
        setState(() {
          openOrder = order;
          message = order == null
              ? 'Could not create the order.'
              : '${order.reference} sent to the kitchen.';
        });
    } catch (_) {
      if (mounted) setState(() => message = 'Could not create the order.');
    }
  }

  Future<void> _pay() async {
    final client = AppBackend.instance.client;
    if (client == null || openOrder == null) return;
    await recordOrderPayment(client, openOrder!.id,
        method: 'cash', amount: openOrder!.total);
    if (mounted) setState(() => message = 'Test payment recorded.');
  }

  @override
  Widget build(BuildContext context) {
    final total = cart.fold<double>(0, (sum, item) => sum + item.price);
    return ListView(children: [
      const _SectionIntro(
          eyebrow: 'Counter station',
          title: 'Fast, clear ordering',
          detail:
              'Create a walk-in order and send it directly to the kitchen.'),
      if (loading) const LinearProgressIndicator(),
      TextField(
          decoration: const InputDecoration(
              labelText: 'Guest name', border: OutlineInputBorder()),
          onChanged: (value) => guest = value),
      const SizedBox(height: 10),
      Wrap(spacing: 8, children: [
        for (final item in ['1', '2', '3', '4', '5', '6'])
          ChoiceChip(
              label: Text('Table $item'),
              selected: table == item,
              onSelected: (_) => setState(() => table = item))
      ]),
      const SizedBox(height: 12),
      _Panel(
          title: 'Menu',
          children: menu.isEmpty
              ? const [
                  ListTile(
                      title: Text('No live menu items'),
                      subtitle:
                          Text('Add available menu items in the web manager.'))
                ]
              : [
                  for (final item in menu.take(30))
                    ListTile(
                        title: Text(item.name),
                        subtitle: Text('\$${item.price.toStringAsFixed(2)}'),
                        trailing: FilledButton(
                            onPressed: () => _add(item),
                            child: const Text('Add')))
                ]),
      _Panel(
          title: 'Current bill · \$${total.toStringAsFixed(2)}',
          children: cart.isEmpty
              ? const [ListTile(title: Text('Select items to begin.'))]
              : [
                  for (final item in cart)
                    ListTile(
                        title: Text(item.name),
                        trailing: Text('\$${item.price.toStringAsFixed(2)}'))
                ]),
      Row(children: [
        Expanded(
            child: FilledButton(
                onPressed:
                    cart.isEmpty || openOrder != null ? null : _sendOrder,
                child: const Text('Send to kitchen'))),
        const SizedBox(width: 10),
        Expanded(
            child: FilledButton(
                onPressed: openOrder == null ? null : _pay,
                child: const Text('Record test payment')))
      ]),
      if (message.isNotEmpty)
        Padding(padding: const EdgeInsets.only(top: 12), child: Text(message)),
    ]);
  }
}

class PosPreview extends StatelessWidget {
  const PosPreview({super.key});
  @override
  Widget build(BuildContext context) => ListView(
        children: [
          const _SectionIntro(
            eyebrow: 'Counter station',
            title: 'Fast, clear ordering',
            detail: 'Designed for touch-first tablet service.',
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final table in [
                'Table 1',
                'Table 2',
                'Table 3',
                'Table 4',
                'Table 5',
                'Table 6',
              ])
                SizedBox(
                  width: 150,
                  child: Card(
                    child: ListTile(
                      title: Text(table),
                      subtitle: const Text('4 seats\nAvailable'),
                      leading: const Icon(Icons.table_restaurant_outlined),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _Panel(
            title: 'Current bill',
            children: [
              ListTile(
                title: Text('Select a table to begin'),
                subtitle: Text('Menu items and payment appear here.'),
              ),
            ],
          ),
        ],
      );
}

class KitchenPreview extends StatelessWidget {
  const KitchenPreview({super.key});
  @override
  Widget build(BuildContext context) => ListView(
        children: [
          const _SectionIntro(
            eyebrow: 'Kitchen display',
            title: 'Keep every order moving',
            detail: 'Tap a ticket to advance it through service.',
          ),
          const _Panel(
            title: 'Preparing now',
            children: [
              ListTile(
                leading: CircleAvatar(child: Text('12')),
                title: Text('Order AI-260718-1042'),
                subtitle: Text('Chicken Tikka Masala · Garlic Naan'),
                trailing: Chip(label: Text('18 min')),
              ),
              ListTile(
                leading: CircleAvatar(child: Text('13')),
                title: Text('Order AI-260718-1043'),
                subtitle: Text('Biryani · Paneer Pakora'),
                trailing: Chip(label: Text('9 min')),
              ),
            ],
          ),
        ],
      );
}

class LiveKitchenPreview extends StatefulWidget {
  const LiveKitchenPreview({super.key, this.locationId});
  final String? locationId;
  @override
  State<LiveKitchenPreview> createState() => _LiveKitchenPreviewState();
}

class _LiveKitchenPreviewState extends State<LiveKitchenPreview> {
  List<OrderRecord> orders = const [];
  bool loading = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant LiveKitchenPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locationId != widget.locationId) _load();
  }

  Future<void> _load() async {
    if (!AppBackend.instance.configured || widget.locationId == null) return;
    final client = AppBackend.instance.client;
    if (client == null) return;
    setState(() => loading = true);
    try {
      final next = await loadOrders(client, locationId: widget.locationId);
      if (mounted) setState(() => orders = next);
    } catch (_) {
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _advance(OrderRecord order) async {
    final next = order.status == 'new'
        ? 'preparing'
        : order.status == 'preparing'
            ? 'ready'
            : 'completed';
    final client = AppBackend.instance.client;
    if (client == null) return;
    await updateOrderStatus(client, order.id, next);
    await _load();
  }

  @override
  Widget build(BuildContext context) => ListView(children: [
        const _SectionIntro(
            eyebrow: 'Kitchen display',
            title: 'Keep every order moving',
            detail: 'Tap a ticket to advance it through service.'),
        if (loading) const LinearProgressIndicator(),
        _Panel(
            title: orders.isEmpty
                ? 'Live tickets'
                : '${orders.length} live orders',
            children: orders.isEmpty
                ? const [
                    ListTile(
                        title: Text('No live tickets'),
                        subtitle:
                            Text('New POS and online orders will appear here.'))
                  ]
                : [
                    for (final order in orders.take(30))
                      ListTile(
                          leading: CircleAvatar(
                              child: Text(order.status == 'new' ? '!' : '✓')),
                          title: Text(order.reference),
                          subtitle: Text(
                              '${order.guestName} · ${order.type} · ${order.status}'),
                          trailing: order.status == 'completed'
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green)
                              : FilledButton(
                                  onPressed: () => _advance(order),
                                  child: Text(order.status == 'new'
                                      ? 'Start'
                                      : order.status == 'preparing'
                                          ? 'Ready'
                                          : 'Complete')))
                  ]),
      ]);
}

class AnalyticsPreview extends StatelessWidget {
  const AnalyticsPreview({super.key});
  @override
  Widget build(BuildContext context) => ListView(
        children: [
          const _SectionIntro(
            eyebrow: 'All locations',
            title: 'Know what needs attention',
            detail: 'Filter by location, channel, period, and status.',
          ),
          const _Panel(
            title: 'Sales by location',
            children: [
              ListTile(
                title: Text('Clifton'),
                subtitle: LinearProgressIndicator(value: .82),
                trailing: Text('\$2,680'),
              ),
              ListTile(
                title: Text('Downtown'),
                subtitle: LinearProgressIndicator(value: .55),
                trailing: Text('\$1,600'),
              ),
            ],
          ),
        ],
      );
}

class LiveReservationsPreview extends StatefulWidget {
  const LiveReservationsPreview({super.key, this.locationId});
  final String? locationId;
  @override
  State<LiveReservationsPreview> createState() =>
      _LiveReservationsPreviewState();
}

class _LiveReservationsPreviewState extends State<LiveReservationsPreview> {
  List<ReservationRecord> reservations = const [];
  bool loading = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant LiveReservationsPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locationId != widget.locationId) _load();
  }

  Future<void> _load() async {
    if (!AppBackend.instance.configured || widget.locationId == null) return;
    final client = AppBackend.instance.client;
    if (client == null) return;
    setState(() => loading = true);
    try {
      final next = await loadReservations(client, widget.locationId!);
      if (mounted) setState(() => reservations = next);
    } catch (_) {
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _confirm(ReservationRecord item) async {
    final client = AppBackend.instance.client;
    if (client == null) return;
    await updateReservationStatus(
        client, item.id, item.status == 'pending' ? 'confirmed' : 'seated');
    await _load();
  }

  @override
  Widget build(BuildContext context) => ListView(children: [
        const _SectionIntro(
            eyebrow: 'Guest book',
            title: 'Reservations at a glance',
            detail: 'Confirm guests and keep the floor plan ready.'),
        if (loading) const LinearProgressIndicator(),
        _Panel(
            title: reservations.isEmpty
                ? 'Today'
                : '${reservations.length} reservations',
            children: reservations.isEmpty
                ? const [
                    ListTile(
                        title: Text('No reservations yet'),
                        subtitle: Text('New guest requests will appear here.'))
                  ]
                : [
                    for (final item in reservations)
                      ListTile(
                          title: Text(
                              '${item.guestName} · ${item.partySize} guests'),
                          subtitle: Text('${item.date} · ${item.time}'),
                          trailing: item.status == 'completed'
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green)
                              : FilledButton(
                                  onPressed: () => _confirm(item),
                                  child: Text(item.status == 'pending'
                                      ? 'Confirm'
                                      : 'Seat')))
                  ]),
      ]);
}

class ReservationsPreview extends StatelessWidget {
  const ReservationsPreview({super.key});
  @override
  Widget build(BuildContext context) => ListView(
        children: [
          const _SectionIntro(
            eyebrow: 'Guest book',
            title: 'Reservations at a glance',
            detail: 'Confirm guests and keep the floor plan ready.',
          ),
          const _Panel(
            title: 'Today',
            children: [
              ListTile(
                title: Text('Priya Singh · 4 guests'),
                subtitle: Text('7:00 PM · Birthday celebration'),
                trailing: Chip(label: Text('Pending')),
              ),
              ListTile(
                title: Text('Daniel Reed · 2 guests'),
                subtitle: Text('7:30 PM'),
                trailing: Chip(label: Text('Confirmed')),
              ),
            ],
          ),
        ],
      );
}

class MenuPreview extends StatefulWidget {
  const MenuPreview({super.key, this.locationId});
  final String? locationId;
  @override
  State<MenuPreview> createState() => _MenuPreviewState();
}

class _MenuPreviewState extends State<MenuPreview> {
  List<MenuItemRecord> items = const [];
  bool loading = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant MenuPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locationId != widget.locationId) _load();
  }

  Future<void> _load() async {
    if (!AppBackend.instance.configured || widget.locationId == null) return;
    final client = AppBackend.instance.client;
    if (client == null) return;
    setState(() => loading = true);
    try {
      final loaded = await loadMenuItems(client, widget.locationId!);
      if (mounted) setState(() => items = loaded);
    } catch (_) {
      if (mounted) setState(() => items = const []);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
        children: [
          const _SectionIntro(
            eyebrow: 'Menu control',
            title: 'Keep every location current',
            detail: 'Edit availability, prices, categories, and custom dishes.',
          ),
          _Panel(
            title: items.isEmpty
                ? 'Popular items'
                : '${items.length} live menu items',
            children: [
              ListTile(
                title: Text('Chicken Tikka Masala'),
                subtitle: Text('\$22.99 · Available'),
                trailing: Icon(Icons.edit_outlined),
              ),
              ListTile(
                title: Text('Garlic Naan'),
                subtitle: Text('\$7.99 · Available'),
                trailing: Icon(Icons.edit_outlined),
              ),
            ],
          ),
        ],
      );
}

class SettingsPreview extends StatelessWidget {
  const SettingsPreview({super.key});
  @override
  Widget build(BuildContext context) => ListView(
        children: [
          const _SectionIntro(
            eyebrow: 'Workspace settings',
            title: 'Make the app fit your team',
            detail:
                'Manage staff access, location details, services, and tables.',
          ),
          _Panel(
            title: 'Quick settings',
            children: [
              ListTile(
                leading: const Icon(Icons.people_outline),
                title: const Text('Team permissions'),
                trailing: Switch(value: true, onChanged: (_) {}),
              ),
              const ListTile(
                leading: Icon(Icons.schedule_outlined),
                title: Text('Location hours'),
              ),
              const ListTile(
                leading: Icon(Icons.table_restaurant_outlined),
                title: Text('Floor plan and tables'),
              ),
            ],
          ),
        ],
      );
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({
    required this.eyebrow,
    required this.title,
    required this.detail,
  });
  final String eyebrow, title, detail;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow.toUpperCase(),
              style: const TextStyle(
                color: _maroon,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(detail, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.label, this.value, this.icon);
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: _maroon),
              Text(label, style: const TextStyle(color: Colors.black54)),
              Text(
                value,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
              ),
            ],
          ),
        ),
      );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ),
              ...children,
            ],
          ),
        ),
      );
}

const locations = <RestaurantLocation>[
  RestaurantLocation(
    name: 'Ambar India Clifton',
    neighborhood: 'Clifton, Cincinnati',
    address: '350 Ludlow Ave',
    services: ['Dine-in', 'Pickup', 'Delivery', 'Catering'],
  ),
  RestaurantLocation(
    name: 'Ambar India Downtown',
    neighborhood: 'Downtown Cincinnati',
    address: 'Coming soon',
    services: ['Pickup', 'Delivery', 'Lunch'],
  ),
  RestaurantLocation(
    name: 'Ambar India Events',
    neighborhood: 'Cincinnati',
    address: 'Coming soon',
    services: ['Catering', 'Private events'],
  ),
];

class MenuItem {
  const MenuItem(
    this.name,
    this.description,
    this.price,
    this.category, {
    this.vegetarian = false,
    this.popular = false,
  });

  final String name;
  final String description;
  final double price;
  final String category;
  final bool vegetarian;
  final bool popular;
}

const menu = <MenuItem>[
  MenuItem(
    'Chicken Tikka Masala',
    'Chargrilled chicken in a rich tomato cream sauce.',
    22.99,
    'Popular',
    popular: true,
  ),
  MenuItem(
    'Garlic Naan',
    'Tandoor-baked bread with fresh garlic and butter.',
    7.99,
    'Popular',
    vegetarian: true,
    popular: true,
  ),
  MenuItem(
    'Saag Paneer',
    'House-made paneer simmered with spinach and spices.',
    22.99,
    'Popular',
    vegetarian: true,
    popular: true,
  ),
  MenuItem(
    'Vegetable Samosa',
    'Crisp pastry filled with seasoned potatoes and peas.',
    9.89,
    'Starters',
    vegetarian: true,
  ),
  MenuItem(
    'Chicken Biryani',
    'Aromatic basmati rice with tender chicken and spices.',
    22.99,
    'Mains',
  ),
  MenuItem(
    'Lamb Rogan Josh',
    'Slow-cooked lamb in a fragrant tomato and yoghurt sauce.',
    26.99,
    'Mains',
  ),
];

class AmbarDirectApp extends StatefulWidget {
  const AmbarDirectApp({super.key});

  @override
  State<AmbarDirectApp> createState() => _AmbarDirectAppState();
}

class _AmbarDirectAppState extends State<AmbarDirectApp> {
  RestaurantLocation? selectedLocation;
  final List<MenuItem> cart = [];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ambar India',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _maroon),
        scaffoldBackgroundColor: _cream,
        useMaterial3: true,
      ),
      home: selectedLocation == null
          ? LocationScreen(
              onSelect: (location) =>
                  setState(() => selectedLocation = location),
            )
          : HomeScreen(
              location: selectedLocation!,
              cart: cart,
              onChangeLocation: () => setState(() => selectedLocation = null),
              onAdd: (item) => setState(() => cart.add(item)),
              onRemove: (item) => setState(() => cart.remove(item)),
            ),
    );
  }
}

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key, required this.onSelect});
  final ValueChanged<RestaurantLocation> onSelect;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Text(
                'AMBAR INDIA',
                style: TextStyle(
                  color: _maroon,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Authentic Northern Indian cuisine',
                style: TextStyle(fontSize: 17),
              ),
              const SizedBox(height: 38),
              const Text(
                'Choose your location',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text('We’ll show the correct menu, services, and offers.'),
              const SizedBox(height: 18),
              Expanded(
                flex: 4,
                child: ListView.separated(
                  itemCount: locations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final location = locations[index];
                    return Card(
                      color: Colors.white,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          location.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            '${location.neighborhood}\n${location.services.join(' · ')}',
                          ),
                        ),
                        isThreeLine: true,
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: _maroon,
                        ),
                        onTap: () => onSelect(location),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const ManagerEntry())),
                icon: const Icon(Icons.dashboard_customize_outlined),
                label: const Text('Open manager preview'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.location,
    required this.cart,
    required this.onChangeLocation,
    required this.onAdd,
    required this.onRemove,
  });
  final RestaurantLocation location;
  final List<MenuItem> cart;
  final VoidCallback onChangeLocation;
  final ValueChanged<MenuItem> onAdd;
  final ValueChanged<MenuItem> onRemove;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;
  String category = 'Popular';

  @override
  Widget build(BuildContext context) {
    final pages = [
      _menuPage(context),
      Center(
        child: Text(
          'Rewards for ${widget.location.name}\nComing next in the MVP',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
      ),
      _cartPage(context),
    ];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          const NavigationDestination(
            icon: Icon(Icons.stars_outlined),
            label: 'Rewards',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text(widget.cart.length.toString()),
              isLabelVisible: widget.cart.isNotEmpty,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            label: 'Cart',
          ),
        ],
      ),
    );
  }

  Widget _menuPage(BuildContext context) {
    final items = menu.where((item) => item.category == category).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'AMBAR INDIA',
                style: TextStyle(
                  color: _maroon,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            IconButton(
              onPressed: widget.onChangeLocation,
              icon: const Icon(Icons.location_on_outlined),
              tooltip: 'Change location',
            ),
          ],
        ),
        Text(
          widget.location.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          '${widget.location.services.join(' · ')}  •  Open today',
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _maroon,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order direct. Earn rewards.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Freshly prepared Northern Indian favourites.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['Popular', 'Starters', 'Mains']
                .map(
                  (name) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(name),
                      selected: category == name,
                      selectedColor: _gold,
                      onSelected: (_) => setState(() => category = name),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        ...items.map((item) => _menuCard(context, item)),
      ],
    );
  }

  Widget _menuCard(BuildContext context, MenuItem item) => Card(
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE6BA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.vegetarian ? Icons.eco_outlined : Icons.restaurant,
                  color: _maroon,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (item.vegetarian)
                          const Icon(Icons.circle,
                              color: Colors.green, size: 13),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '\$${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                onPressed: () => widget.onAdd(item),
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: _maroon,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _cartPage(BuildContext context) {
    final total = widget.cart.fold(0.0, (sum, item) => sum + item.price);
    if (widget.cart.isEmpty) {
      return const Center(
        child: Text(
          'Your cart is empty.\nAdd something delicious from the menu.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your order',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
          ),
          Text(widget.location.name),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: widget.cart
                  .map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.name),
                      subtitle: Text('\$${item.price.toStringAsFixed(2)}'),
                      trailing: IconButton(
                        onPressed: () => widget.onRemove(item),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Checkout will be connected to payments next.'),
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _maroon,
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Continue to checkout'),
          ),
        ],
      ),
    );
  }
}
