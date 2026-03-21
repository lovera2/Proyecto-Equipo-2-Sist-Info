import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_list_page.dart';
import 'profile_page.dart';
import 'package:provider/provider.dart';
import '../viewmodels/admin_user_management_viewmodel.dart';
import '../viewmodels/admin_material_viewmodel.dart';
import '../services/admin_material_service.dart';
import 'admin_user_management_page.dart';
import 'admin_material_management_page.dart';

class AdminDashboardView extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback? onOpenMenu;

  const AdminDashboardView({
    super.key,
    required this.onBack,
    this.onOpenMenu,
  });

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);

  bool _hasNewNotifications = true;

  DateTimeRange? _range;
  String _preset = '30d';
  String _materialCategory = 'Todas';

  late Future<_DashboardData> _future;
  Map<String, int> _lastPieCounts = const {};

  @override
  void initState() {
    super.initState();
    _applyPreset('30d');
  }

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> _mostrarMenuAdmin(BuildContext context) async {
    final value = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 90, 20, 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      items: const [
        PopupMenuItem(
          value: 'dashboard',
          child: Row(
            children: [
              Icon(Icons.dashboard, color: Color(0xFF1B3A57), size: 20),
              SizedBox(width: 12),
              Text('Dashboard'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'perfiles',
          child: Row(
            children: [
              Icon(Icons.people, color: Color(0xFF1B3A57), size: 20),
              SizedBox(width: 12),
              Text('Gestión de Usuarios'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'materiales',
          child: Row(
            children: [
              Icon(Icons.book, color: Color(0xFF1B3A57), size: 20),
              SizedBox(width: 12),
              Text('Gestión de Material'),
            ],
          ),
        ),
      ],
    );

    if (!context.mounted || value == null) return;

    if (value == 'dashboard') {
      return;
    } else if (value == 'perfiles') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => AdminUserManagementViewModel(),
            child: const AdminUserManagementPage(),
          ),
        ),
      );
      return;
    } else if (value == 'materiales') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => AdminMaterialViewModel(AdminMaterialService()),
            child: const AdminMaterialManagementPage(),
          ),
        ),
      );
    }
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final h = MediaQuery.of(dialogContext).size.height;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Términos y Condiciones",
            style: TextStyle(
              color: unimetBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 520,
            height: h * 0.62,
            child: const SingleChildScrollView(
              child: Text(
                "Al usar BookLoop aceptas lo siguiente:\n\n"
                "1) Acceso y verificación\n"
                "• Solo se permite el uso de correos institucionales UNIMET (docente y estudiante).\n"
                "• La cuenta es personal e intransferible.\n\n"
                "2) Uso responsable\n"
                "• Mantén un trato respetuoso en publicaciones y mensajes.\n"
                "• Está prohibido publicar contenido ofensivo, engañoso o spam.\n"
                "• BookLoop puede limitar o suspender cuentas ante evidencias de abuso.\n\n"
                "3) Préstamos y devoluciones\n"
                "• Al solicitar/aceptar un préstamo te comprometes a cumplir fecha, condiciones y lugar acordados.\n"
                "• Quien recibe el material es responsable de cuidarlo y devolverlo en el estado acordado.\n"
                "• En caso de pérdida o daño, las partes deben coordinar una solución (reposición o acuerdo).\n\n"
                "4) Seguridad y reportes\n"
                "• BookLoop puede limitar funciones (publicar/solicitar) si detecta patrones de incumplimiento.\n\n"
                "5) Privacidad y datos\n"
                "• Se almacenan datos mínimos para operar la plataforma.\n"
                "• No se publican datos sensibles.\n\n"
                "6) Alcance del servicio\n"
                "• BookLoop es una herramienta de coordinación; no garantiza la disponibilidad de material.\n"
                "• La UNIMET y el equipo de BookLoop no se responsabilizan por acuerdos fuera de la plataforma.\n",
                style: TextStyle(fontSize: 14, height: 1.35),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                "Entendido",
                style: TextStyle(color: unimetOrange),
              ),
            ),
          ],
        );
      },
    );
  }

  void _applyPreset(String preset) {
    final now = DateTime.now();
    DateTime start;

    if (preset == '7d') {
      start = now.subtract(const Duration(days: 7));
    } else if (preset == '30d') {
      start = now.subtract(const Duration(days: 30));
    } else if (preset == '90d') {
      start = now.subtract(const Duration(days: 90));
    } else if (preset == 'ytd') {
      start = DateTime(now.year, 1, 1);
    } else {
      start = now.subtract(const Duration(days: 30));
    }

    setState(() {
      _preset = preset;
      _range = DateTimeRange(
        start: DateTime(start.year, start.month, start.day),
        end: now,
      );
      _future = _loadDashboard();
    });
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initial = _range ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: unimetOrange,
              onPrimary: Colors.white,
              secondary: unimetOrange,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _preset = 'custom';
      _range = picked;
      _future = _loadDashboard();
    });
  }

  Timestamp _tsStart() {
    final r = _range;
    if (r == null) {
      return Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 30)),
      );
    }

    return Timestamp.fromDate(
      DateTime(r.start.year, r.start.month, r.start.day),
    );
  }

  Timestamp _tsEndExclusive() {
    final r = _range;
    if (r == null) return Timestamp.fromDate(DateTime.now());

    final endNextDay = DateTime(
      r.end.year,
      r.end.month,
      r.end.day,
    ).add(const Duration(days: 1));

    return Timestamp.fromDate(endNextDay);
  }

  DateTime? _readDateFromAny(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  bool _inRange(DateTime dt) {
    final r = _range;
    if (r == null) return true;

    final start = DateTime(r.start.year, r.start.month, r.start.day);
    final endNext = DateTime(
      r.end.year,
      r.end.month,
      r.end.day,
    ).add(const Duration(days: 1));

    return (dt.isAtSameMomentAs(start) || dt.isAfter(start)) &&
        dt.isBefore(endNext);
  }

  String _normCat(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'Otros';

    final s = trimmed.toLowerCase();
    if (s == 'faces' || s == 'f.a.c.e.s') return 'Faces';
    if (s == 'ingenieria' || s == 'ingeniería') return 'Ingeniería';
    if (s == 'humanidades') return 'Humanidades';
    if (s == 'derecho') return 'Derecho';
    if (s == 'otros') return 'Otros';

    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  bool _catPass(String cat) {
    if (_materialCategory == 'Todas') return true;
    return cat == _materialCategory;
  }

  DateTime? _readMaterialDate(Map<String, dynamic> data) {
    return _readDateFromAny(data['createdAt']) ??
        _readDateFromAny(data['updatedAt']) ??
        _readDateFromAny(data['fecha_registro']);
  }

  List<String> _buildCategoryOrder({
    required List<String> categoriesFromCollection,
    required Set<String> categoriesFromMaterials,
  }) {
    final ordered = <String>[];
    final seen = <String>{};

    void addCat(String raw) {
      final cat = _normCat(raw);
      final key = cat.toLowerCase();
      if (seen.contains(key)) return;
      seen.add(key);
      ordered.add(cat);
    }

    for (final cat in categoriesFromCollection) {
      addCat(cat);
    }

    for (final cat in categoriesFromMaterials) {
      addCat(cat);
    }

    if (!seen.contains('otros')) {
      ordered.add('Otros');
    }

    ordered.sort((a, b) {
      if (a == 'Otros' && b != 'Otros') return 1;
      if (a != 'Otros' && b == 'Otros') return -1;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });

    return ordered;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _safeRangeQuery(
    String collection,
    String fieldName,
  ) async {
    try {
      final qs = await FirebaseFirestore.instance
          .collection(collection)
          .where(fieldName, isGreaterThanOrEqualTo: _tsStart())
          .where(fieldName, isLessThan: _tsEndExclusive())
          .get();
      return qs.docs;
    } catch (_) {
      final qs = await FirebaseFirestore.instance.collection(collection).get();
      return qs.docs;
    }
  }

  int _rangeDays() {
    final r = _range;
    if (r == null) return 30;

    final start = DateTime(r.start.year, r.start.month, r.start.day);
    final end = DateTime(r.end.year, r.end.month, r.end.day);
    return end.difference(start).inDays + 1;
  }

  bool get _useDailyBuckets => _rangeDays() <= 45;

  DateTime _startOfWeek(DateTime d) {
    final normalized = DateTime(d.year, d.month, d.day);
    final weekday = normalized.weekday;
    return normalized.subtract(Duration(days: weekday - 1));
  }

  String _keyDaily(DateTime d) {
    final dt = DateTime(d.year, d.month, d.day);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _keyWeekly(DateTime d) {
    final w = _startOfWeek(d);
    return 'W:${w.year}-${w.month.toString().padLeft(2, '0')}-${w.day.toString().padLeft(2, '0')}';
  }

  List<String> _bucketKeysInRange() {
    final r = _range;
    final now = DateTime.now();
    final start = r?.start ?? now.subtract(const Duration(days: 30));
    final end = r?.end ?? now;

    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);

    final keys = <String>[];

    if (_useDailyBuckets) {
      var cur = s;
      while (!cur.isAfter(e)) {
        keys.add(_keyDaily(cur));
        cur = cur.add(const Duration(days: 1));
      }
      return keys;
    }

    var cur = _startOfWeek(s);
    final endW = _startOfWeek(e);
    while (!cur.isAfter(endW)) {
      keys.add(_keyWeekly(cur));
      cur = cur.add(const Duration(days: 7));
    }
    return keys;
  }

  String _bucketLabel(String key) {
    if (key.startsWith('W:')) {
      final s = key.substring(2);
      final parts = s.split('-');
      if (parts.length == 3) return '${parts[2]}/${parts[1]}';
      return s;
    }

    final p = key.split('-');
    if (p.length == 3) return '${p[2]}/${p[1]}';
    return key;
  }

  String _compactBucketLabel(String key, int index, int total) {
    return _bucketLabel(key);
  }

  double _bottomInterval(int n) {
    if (n <= 0) return 1;
    const targetLabels = 7;
    final rawStep = (n / targetLabels).ceil();
    return rawStep < 1 ? 1 : rawStep.toDouble();
  }

  Future<_DashboardData> _loadDashboard() async {
    final bucketKeys = _bucketKeysInRange();

    final categoriesSnapshot =
        await FirebaseFirestore.instance.collection('categories').get();

    final categoriesFromCollection = categoriesSnapshot.docs
        .map((d) => _normCat((d.data()['name'] ?? '').toString()))
        .where((c) => c.trim().isNotEmpty)
        .toList();

    // USUARIOS
    final userDocs = await _safeRangeQuery('usuarios', 'fecha_registro');
    final usersByBucket = <String, int>{};
    final usersByType = <String, int>{
      'Estudiante': 0,
      'Docente': 0,
      'Otros': 0,
    };

    for (final d in userDocs) {
      final data = d.data();
      final dt = _readDateFromAny(data['fecha_registro']);
      if (dt == null || !_inRange(dt)) continue;

      final email = (data['email'] ?? '').toString().trim().toLowerCase();
      if (email.endsWith('@correo.unimet.edu.ve')) {
        usersByType['Estudiante'] = (usersByType['Estudiante'] ?? 0) + 1;
      } else if (email.endsWith('@unimet.edu.ve')) {
        usersByType['Docente'] = (usersByType['Docente'] ?? 0) + 1;
      } else {
        usersByType['Otros'] = (usersByType['Otros'] ?? 0) + 1;
      }

      final key = _useDailyBuckets ? _keyDaily(dt) : _keyWeekly(dt);
      usersByBucket[key] = (usersByBucket[key] ?? 0) + 1;
    }

    // MATERIALS
    final materialSnapshot =
        await FirebaseFirestore.instance.collection('materials').get();
    final materialDocs = materialSnapshot.docs;

    final categoriesFromMaterials = <String>{};
    for (final d in materialDocs) {
      final data = d.data();
      final cat = _normCat((data['category'] ?? '').toString());
      categoriesFromMaterials.add(cat);
    }

    final categoryOrder = _buildCategoryOrder(
      categoriesFromCollection: categoriesFromCollection,
      categoriesFromMaterials: categoriesFromMaterials,
    );

    final materialsTotalByCat = <String, int>{};
    for (final cat in categoryOrder) {
      materialsTotalByCat[cat] = 0;
    }

    final materialsByBucketCat = <String, Map<String, int>>{};

    for (final d in materialDocs) {
      final data = d.data();
      final dt = _readMaterialDate(data);
      if (dt == null || !_inRange(dt)) continue;

      final cat = _normCat((data['category'] ?? '').toString());
      if (!_catPass(cat)) continue;

      final key = _useDailyBuckets ? _keyDaily(dt) : _keyWeekly(dt);

      materialsByBucketCat.putIfAbsent(key, () {
        final seed = <String, int>{};
        for (final category in categoryOrder) {
          seed[category] = 0;
        }
        return seed;
      });

      materialsByBucketCat[key]![cat] =
          (materialsByBucketCat[key]![cat] ?? 0) + 1;
      materialsTotalByCat[cat] = (materialsTotalByCat[cat] ?? 0) + 1;
    }

    final materialCategoryById = <String, String>{};
    for (final d in materialDocs) {
      final data = d.data();
      final cat = _normCat((data['category'] ?? '').toString());
      materialCategoryById[d.id] = cat;
    }

    // CHATS / INTERCAMBIOS
    List<QueryDocumentSnapshot<Map<String, dynamic>>> chatDocs;
    try {
      chatDocs = await _safeRangeQuery('chats', 'createdAt');
    } catch (_) {
      chatDocs = await _safeRangeQuery('chats', 'lastUpdate');
    }

    final chatsByBucket = <String, int>{};
    for (final d in chatDocs) {
      final data = d.data();
      final dt = _readDateFromAny(data['createdAt']) ??
          _readDateFromAny(data['lastUpdate']);
      if (dt == null || !_inRange(dt)) continue;

      if (_materialCategory != 'Todas') {
        final materialId = (data['materialId'] ?? '').toString().trim();
        final chatCategory = materialCategoryById[materialId];
        if (chatCategory == null || !_catPass(chatCategory)) {
          continue;
        }
      }

      final key = _useDailyBuckets ? _keyDaily(dt) : _keyWeekly(dt);
      chatsByBucket[key] = (chatsByBucket[key] ?? 0) + 1;
    }

    int sumMap(Map<String, int> m) {
      var s = 0;
      for (final v in m.values) {
        s += v;
      }
      return s;
    }

    final usersSeries = <String, int>{};
    final chatsSeries = <String, int>{};
    final materialsSeriesTotal = <String, int>{};

    for (final k in bucketKeys) {
      usersSeries[k] = usersByBucket[k] ?? 0;
      chatsSeries[k] = chatsByBucket[k] ?? 0;

      final catMap = materialsByBucketCat[k];
      if (catMap == null) {
        materialsSeriesTotal[k] = 0;
      } else {
        var s = 0;
        for (final v in catMap.values) {
          s += v;
        }
        materialsSeriesTotal[k] = s;
      }
    }

    return _DashboardData(
      usersCount: sumMap(usersSeries),
      chatsCount: sumMap(chatsSeries),
      materialsCount: sumMap(materialsSeriesTotal),
      materialsByCategory: materialsTotalByCat,
      usersByType: usersByType,
      bucketKeys: bucketKeys,
      usersByBucket: usersSeries,
      chatsByBucket: chatsSeries,
      materialsByBucketCat: materialsByBucketCat,
      useDailyBuckets: _useDailyBuckets,
      categoryOrder: categoryOrder,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.transparent,
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: FutureBuilder<_DashboardData>(
              future: _future,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: unimetOrange),
                  );
                }

                final data = snap.data!;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final maxW = constraints.maxWidth;
                    const horizontalPadding = 40.0;
                    final innerW =
                        (maxW - horizontalPadding).clamp(320.0, maxW).toDouble();
                    const spacing = 16.0;

                    final trendCols =
                        innerW >= 1700 ? 3 : (innerW >= 1150 ? 2 : 1);
                    final trendTileW = trendCols == 1
                        ? innerW
                        : (innerW - spacing * (trendCols - 1)) / trendCols;

                    final lowerCols = innerW >= 1200 ? 2 : 1;
                    final lowerTileW = lowerCols == 1
                        ? innerW
                        : (innerW - spacing * (lowerCols - 1)) / lowerCols;

                    Widget trendTile(Widget child) =>
                        SizedBox(width: trendTileW, child: child);

                    Widget lowerTile(Widget child) =>
                        SizedBox(width: lowerTileW, child: child);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          _buildFiltersCard(context, data.categoryOrder),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 14,
                            runSpacing: 14,
                            children: [
                              _buildKpiCard(
                                "Usuarios (fecha)",
                                data.usersCount.toString(),
                                Icons.people,
                                Colors.blue,
                              ),
                              _buildKpiCard(
                                "Intercambios (filtro)",
                                data.chatsCount.toString(),
                                Icons.swap_horiz,
                                Colors.green,
                              ),
                              _buildKpiCard(
                                "Libros (filtro)",
                                data.materialsCount.toString(),
                                Icons.book,
                                unimetOrange,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: [
                              trendTile(
                                _sectionCard(
                                  title: "Tendencia de publicaciones (libros)",
                                  subtitle: data.useDailyBuckets
                                      ? "Por día (apilado por categoría)"
                                      : "Por semana (apilado por categoría)",
                                  child: _buildMaterialsTrendInner(data),
                                ),
                              ),
                              trendTile(
                                _sectionCard(
                                  title: "Tendencia de usuarios registrados",
                                  subtitle: data.useDailyBuckets
                                      ? "Por día"
                                      : "Por semana",
                                  child: _buildSimpleBarInner(
                                    keys: data.bucketKeys,
                                    values: data.usersByBucket,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              trendTile(
                                _sectionCard(
                                  title: "Tendencia de préstamos / intercambios",
                                  subtitle: data.useDailyBuckets
                                      ? "Por día"
                                      : "Por semana",
                                  child: _buildSimpleBarInner(
                                    keys: data.bucketKeys,
                                    values: data.chatsByBucket,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: [
                              lowerTile(
                                _sectionCard(
                                  title: "Libros por categoría (según filtros)",
                                  subtitle:
                                      "Distribución en el rango seleccionado",
                                  child: _buildPieInner(
                                    data.materialsByCategory,
                                    data.categoryOrder,
                                  ),
                                ),
                              ),
                              lowerTile(
                                _sectionCard(
                                  title: "Usuarios por tipo",
                                  subtitle:
                                      "Docentes vs estudiantes en el rango seleccionado",
                                  child: _buildUsersTypePieInner(
                                    data.usersByType,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          _Footer(onTerms: () => _showTermsDialog(context)),
                          const SizedBox(height: 12),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // LADO IZQUIERDO: Título flexible
          Expanded(
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Volver',
                ),
                const SizedBox(width: 8),
                const Icon(Icons.menu_book, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'BookLoop ADMIN',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // LADO DERECHO: Scroll horizontal para los iconos si la pantalla es muy pequeña
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: unimetBlue, borderRadius: BorderRadius.circular(12)),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pushNamed(context, '/publish'),
                    icon: const Icon(Icons.add, color: Colors.white, size: 20),
                    tooltip: 'Publicar material',
                  ),
                ),
                const SizedBox(width: 4),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      icon: const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 26),
                      onPressed: () {
                        setState(() => _hasNewNotifications = false);
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatListPage(isAdmin: true)));
                      },
                      tooltip: 'Mis chats y notificaciones',
                    ),
                    if (_hasNewNotifications)
                      Positioned(
                        right: 8, top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: unimetBlue, width: 1.5)),
                          constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  icon: const Icon(Icons.person_outline, color: Colors.white, size: 26),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfilePage())),
                  tooltip: 'Mi perfil',
                ),
                IconButton(
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  icon: const Icon(Icons.settings_suggest, color: Colors.white, size: 26),
                  onPressed: () => _mostrarMenuAdmin(context),
                  tooltip: 'Mostrar menú',
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert, color: Colors.white, size: 26),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  onSelected: (value) async { if (value == 'logout') await _handleLogout(context); },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(children: [Icon(Icons.logout, color: Color(0xFF1B3A57)), SizedBox(width: 10), Text('Cerrar sesión')]),
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

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: unimetBlue,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
         
          child, 
        ],
      ),
    );
  }

  Widget _buildMaterialsTrendInner(_DashboardData data) {
    final keys = data.bucketKeys;
    final catsOrder = data.categoryOrder;

    if (keys.isEmpty) {
      return Text(
        'Sin datos para el rango',
        style: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    var maxY = 0;
    for (final k in keys) {
      final m = data.materialsByBucketCat[k];
      if (m == null) continue;

      var sum = 0;
      for (final cat in catsOrder) {
        sum += (m[cat] ?? 0);
      }

      if (sum > maxY) maxY = sum;
    }
    if (maxY == 0) maxY = 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _miniLegend(catsOrder),
        const SizedBox(height: 10),
        SizedBox(
          height: 260,
          child: BarChart(
            BarChartData(
              gridData: FlGridData(show: true),
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY.toDouble() * 1.25,
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= keys.length) {
                        return const SizedBox.shrink();
                      }

                      final m = data.materialsByBucketCat[keys[i]];
                      if (m == null) return const SizedBox.shrink();

                      int total = 0;
                      for (final cat in catsOrder) {
                        total += (m[cat] ?? 0);
                      }

                      if (total <= 0) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          total.toString(),
                          style: const TextStyle(
                            color: unimetBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: unimetBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= keys.length) {
                        return const SizedBox.shrink();
                      }

                      final step = _bottomInterval(keys.length).toInt();
                      if (step > 1 && i % step != 0 && i != keys.length - 1) {
                        return const SizedBox.shrink();
                      }

                      return SideTitleWidget(
                        meta: meta,
                        space: 10,
                        child: Transform.rotate(
                          angle: -0.55,
                          child: Text(
                            _compactBucketLabel(keys[i], i, keys.length),
                            style: const TextStyle(
                              color: unimetBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => unimetBlue.withOpacity(0.92),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final key = keys[group.x.toInt()];
                    final m =
                        data.materialsByBucketCat[key] ?? const <String, int>{};

                    final lines = <String>[];
                    for (final cat in catsOrder) {
                      final v = m[cat] ?? 0;
                      if (v > 0) {
                        lines.add('$cat: $v');
                      }
                    }

                    final total = rod.toY.toInt();
                    return BarTooltipItem(
                      'Total: $total\n${lines.join('\n')}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    );
                  },
                ),
              ),
              barGroups: List.generate(keys.length, (i) {
                final k = keys[i];
                final m = data.materialsByBucketCat[k] ?? const <String, int>{};

                double running = 0;
                final stacks = <BarChartRodStackItem>[];

                for (final cat in catsOrder) {
                  final v = (m[cat] ?? 0).toDouble();
                  if (v <= 0) continue;

                  stacks.add(
                    BarChartRodStackItem(
                      running,
                      running + v,
                      _catColor(cat),
                    ),
                  );
                  running += v;
                }

                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: running,
                      width: 14,
                      borderRadius: BorderRadius.circular(6),
                      rodStackItems: stacks,
                      color: Colors.transparent,
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleBarInner({
    required List<String> keys,
    required Map<String, int> values,
    required Color color,
  }) {
    if (keys.isEmpty) {
      return Text(
        'Sin datos para el rango',
        style: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    var maxY = 0;
    for (final k in keys) {
      final v = values[k] ?? 0;
      if (v > maxY) maxY = v;
    }
    if (maxY == 0) maxY = 1;

    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: true),
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY.toDouble() * 1.25,
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= keys.length) {
                    return const SizedBox.shrink();
                  }

                  final v = values[keys[i]] ?? 0;
                  if (v <= 0) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      v.toString(),
                      style: const TextStyle(
                        color: unimetBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: unimetBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= keys.length) {
                    return const SizedBox.shrink();
                  }

                  final step = _bottomInterval(keys.length).toInt();
                  if (step > 1 && i % step != 0 && i != keys.length - 1) {
                    return const SizedBox.shrink();
                  }

                  return SideTitleWidget(
                    meta: meta,
                    space: 10,
                    child: Transform.rotate(
                      angle: -0.55,
                      child: Text(
                        _compactBucketLabel(keys[i], i, keys.length),
                        style: const TextStyle(
                          color: unimetBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => unimetBlue.withOpacity(0.92),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final key = keys[group.x.toInt()];
                final v = values[key] ?? 0;
                return BarTooltipItem(
                  '${_compactBucketLabel(key, group.x.toInt(), keys.length)}\n$v',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
          barGroups: List.generate(keys.length, (i) {
            final k = keys[i];
            final v = (values[k] ?? 0).toDouble();

            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: v,
                  width: 14,
                  borderRadius: BorderRadius.circular(6),
                  color: color,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildPieInner(Map<String, int> counts, List<String> categoryOrder) {
    _lastPieCounts = counts;

    int total = 0;
    for (final cat in categoryOrder) {
      total += counts[cat] ?? 0;
    }

    if (total == 0) {
      return Center(
        child: Text(
          'No hay libros en el rango seleccionado',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 42,
              sections: _buildPieSections(counts, total, categoryOrder),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildLegend(categoryOrder),
      ],
    );
  }

  Widget _buildUsersTypePieInner(Map<String, int> counts) {
    final estudiantes = counts['Estudiante'] ?? 0;
    final docentes = counts['Docente'] ?? 0;
    final otros = counts['Otros'] ?? 0;
    final total = estudiantes + docentes + otros;

    if (total == 0) {
      return Center(
        child: Text(
          'No hay usuarios en el rango seleccionado',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    double pct(int n) => (n * 100.0) / total;

    final sections = <PieChartSectionData>[];

    if (estudiantes > 0) {
      sections.add(
        PieChartSectionData(
          color: Colors.blue,
          value: estudiantes.toDouble(),
          title: '${pct(estudiantes).toInt()}%\n$estudiantes',
          radius: 56,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (docentes > 0) {
      sections.add(
        PieChartSectionData(
          color: Colors.orange,
          value: docentes.toDouble(),
          title: '${pct(docentes).toInt()}%\n$docentes',
          radius: 56,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (otros > 0) {
      sections.add(
        PieChartSectionData(
          color: Colors.grey,
          value: otros.toDouble(),
          title: '${pct(otros).toInt()}%\n$otros',
          radius: 56,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 42,
              sections: sections,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 18,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            _typeLegendItem(Colors.blue, 'Estudiante ($estudiantes)'),
            _typeLegendItem(Colors.orange, 'Docente ($docentes)'),
            _typeLegendItem(Colors.grey, 'Otros ($otros)'),
          ],
        ),
      ],
    );
  }

  Widget _typeLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: unimetBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersCard(BuildContext context, List<String> categoryOrder) {
    final r = _range;
    final rangeText = (r == null)
        ? '—'
        : '${r.start.day.toString().padLeft(2, '0')}/${r.start.month.toString().padLeft(2, '0')}/${r.start.year} '
            '→ ${r.end.day.toString().padLeft(2, '0')}/${r.end.month.toString().padLeft(2, '0')}/${r.end.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unimetBlue.withOpacity(0.28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtros',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _chipPreset('7d', '7 días'),
              _chipPreset('30d', '30 días'),
              _chipPreset('90d', '90 días'),
              _chipPreset('ytd', 'Este año'),
              ActionChip(
                label: const Text('Personalizado'),
                backgroundColor: _preset == 'custom' ? unimetOrange : Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.65)),
                labelStyle: TextStyle(
                  color: _preset == 'custom' ? Colors.white : unimetBlue,
                  fontWeight: FontWeight.w900,
                ),
                onPressed: _pickCustomRange,
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.date_range, color: Colors.white70, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    rangeText,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // AQUÍ ESTÁ EL FIX: Usar Wrap en lugar de Row para que el botón "Reiniciar" no desborde la pantalla
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.filter_alt_outlined, color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Categoría:', // Texto acortado un poco
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _materialCategory,
                    dropdownColor: const Color(0xFF274B6C),
                    underline: Container(height: 0),
                    iconEnabledColor: Colors.white,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                    items: [
                      const DropdownMenuItem(value: 'Todas', child: Text('Todas')),
                      ...categoryOrder.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _materialCategory = v;
                        _future = _loadDashboard();
                      });
                    },
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _materialCategory = 'Todas';
                    _applyPreset('30d');
                  });
                },
                icon: const Icon(Icons.refresh, color: Colors.white70, size: 18),
                label: const Text(
                  'Reiniciar',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipPreset(String key, String label) {
    final selected = _preset == key;

    return ChoiceChip(
      selected: selected,
      label: Text(label),
      showCheckmark: true,
      checkmarkColor: selected ? Colors.white : unimetBlue,
      selectedColor: unimetOrange,
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.white.withOpacity(0.65)),
      labelStyle: TextStyle(
        color: selected ? Colors.white : unimetBlue,
        fontWeight: FontWeight.w900,
      ),
      onSelected: (_) => _applyPreset(key),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 190,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: unimetBlue,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _catColor(String cat) {
    switch (_normCat(cat)) {
      case 'Humanidades':
        return Colors.redAccent;
      case 'Ingeniería':
        return Colors.blue;
      case 'Faces':
        return Colors.purple;
      case 'Derecho':
        return Colors.green;
      case 'Otros':
        return Colors.grey;
      default:
        final palette = <Color>[
          Colors.teal,
          Colors.indigo,
          Colors.deepOrange,
          Colors.cyan,
          Colors.pink,
          Colors.brown,
          Colors.lime,
        ];
        final hash = _normCat(cat).codeUnits.fold<int>(0, (a, b) => a + b);
        return palette[hash % palette.length];
    }
  }

  Widget _cardShell({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _miniLegend(List<String> cats) {
    return Wrap(
      spacing: 14,
      runSpacing: 10,
      children: cats.map((c) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _catColor(c),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              c,
              style: const TextStyle(
                color: unimetBlue,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  List<PieChartSectionData> _buildPieSections(
    Map<String, int> counts,
    int total,
    List<String> categoryOrder,
  ) {
    double pct(int n) => (n * 100.0) / total;

    PieChartSectionData section(int n, Color color) {
      return PieChartSectionData(
        color: color,
        value: n.toDouble(),
        title: '${pct(n).toInt()}%\n$n',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }

    final sections = <PieChartSectionData>[];
    for (final cat in categoryOrder) {
      final value = counts[cat] ?? 0;
      if (value > 0) {
        sections.add(section(value, _catColor(cat)));
      }
    }

    return sections;
  }

  Widget _buildLegend(List<String> categoryOrder) {
    return Wrap(
      spacing: 18,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: categoryOrder.map((cat) {
        final value = _lastPieCounts[cat] ?? 0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _catColor(cat),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$cat ($value)',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: unimetBlue,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _DashboardData {
  final int usersCount;
  final int chatsCount;
  final int materialsCount;
  final Map<String, int> materialsByCategory;
  final Map<String, int> usersByType;

  final List<String> bucketKeys;
  final Map<String, int> usersByBucket;
  final Map<String, int> chatsByBucket;
  final Map<String, Map<String, int>> materialsByBucketCat;
  final bool useDailyBuckets;
  final List<String> categoryOrder;

  const _DashboardData({
    required this.usersCount,
    required this.chatsCount,
    required this.materialsCount,
    required this.materialsByCategory,
    required this.usersByType,
    required this.bucketKeys,
    required this.usersByBucket,
    required this.chatsByBucket,
    required this.materialsByBucketCat,
    required this.useDailyBuckets,
    required this.categoryOrder,
  });
}

class _Footer extends StatelessWidget {
  final VoidCallback onTerms;
  const _Footer({required this.onTerms});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          const Text(
            '© BookLoop • UNIMET',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const Spacer(),
          TextButton(
            onPressed: onTerms,
            child: const Text(
              'Términos y condiciones',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}