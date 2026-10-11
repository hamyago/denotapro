// lib/presentation/screens/federation/federation_dashboard_screen.dart
//
// Tableau de bord d'une fédération sportive nationale.
// Fournit une vue nationale (31 régions) de la discipline.
//
// Différence avec InstitutionDashboardScreen :
//   - Institution : gère UN club avec ses athlètes
//   - Fédération : supervise TOUS les clubs et athlètes de sa discipline

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_colors.dart';
import '../../../main.dart';
import '../../widgets/common/logout_action.dart';
import '../search/discover_screen.dart';
import '../search/talent_map_screen.dart';
import '../profile/profile_screen.dart';
import '../home/notifications_screen.dart';

// ══════════════════════════════════════════════════════════════
// ÉCRAN PRINCIPAL
// ══════════════════════════════════════════════════════════════

class FederationDashboardScreen extends StatefulWidget {
  const FederationDashboardScreen({super.key});

  @override
  State<FederationDashboardScreen> createState() =>
      _FederationDashboardScreenState();
}

class _FederationDashboardScreenState
    extends State<FederationDashboardScreen> {
  // ── État ────────────────────────────────────────────────
  bool _loading = true;
  String? _error;

  // Institution (fédération)
  Map<String, dynamic>? _institution;

  // Statistiques nationales
  int _totalAthletes = 0;
  int _totalClubs = 0;
  int _totalLicenses = 0;
  int _activeLicenses = 0;

  // Top talents nationaux
  List<Map<String, dynamic>> _topTalents = [];

  // Clubs affiliés
  List<Map<String, dynamic>> _affiliatedClubs = [];

  // Répartition par ville
  Map<String, int> _talentsByCity = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ── Chargement des données ──────────────────────────────
  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final uid = supabase.auth.currentUser?.id;
    if (uid == null) {
      setState(() {
        _error = 'Utilisateur non connecté';
        _loading = false;
      });
      return;
    }

    try {
      // Charger l'institution
      final institution = await supabase
          .from('institutions')
          .select()
          .eq('profile_id', uid)
          .maybeSingle();

      if (institution == null) {
        setState(() {
          _error = 'Aucune fédération associée à ce compte';
          _loading = false;
        });
        return;
      }

      // Récupérer les sports couverts par la fédération
      final sportIds = (institution['sport_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [];

      final primarySportId = sportIds.isNotEmpty ? sportIds.first : null;

      // Charger toutes les stats en parallèle
      final results = await Future.wait([
        _fetchTotalAthletes(primarySportId),
        _fetchTotalClubs(primarySportId),
        _fetchLicenseStats(primarySportId),
        _fetchTopTalents(primarySportId),
        _fetchAffiliatedClubs(primarySportId),
        _fetchTalentsByCity(primarySportId),
      ]);

      if (!mounted) return;

      setState(() {
        _institution = institution;
        _totalAthletes = results[0] as int;
        _totalClubs = results[1] as int;
        final licenseStats = results[2] as Map<String, int>;
        _totalLicenses = licenseStats['total'] ?? 0;
        _activeLicenses = licenseStats['active'] ?? 0;
        _topTalents = results[3] as List<Map<String, dynamic>>;
        _affiliatedClubs = results[4] as List<Map<String, dynamic>>;
        _talentsByCity = results[5] as Map<String, int>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().length > 150
            ? e.toString().substring(0, 150)
            : e.toString();
        _loading = false;
      });
    }
  }

  Future<int> _fetchTotalAthletes(int? sportId) async {
    try {
      final data = sportId != null
          ? await supabase
              .from('athlete_profiles')
              .select('id')
              .eq('primary_sport_id', sportId)
          : await supabase
              .from('athlete_profiles')
              .select('id');

      return (data as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _fetchTotalClubs(int? sportId) async {
    try {
      final data = sportId != null
          ? await supabase
              .from('institutions')
              .select('id')
              .inFilter('institution_type', ['club', 'academy'])
              .contains('sport_ids', [sportId])
          : await supabase
              .from('institutions')
              .select('id')
              .inFilter('institution_type', ['club', 'academy']);

      return (data as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<Map<String, int>> _fetchLicenseStats(int? sportId) async {
    try {
      final data = sportId != null
          ? await supabase
              .from('licenses')
              .select('id, is_active')
              .eq('sport_id', sportId)
          : await supabase.from('licenses').select('id, is_active');

      final list = data as List;
      final active = list.where((e) => e['is_active'] == true).length;
      return {'total': list.length, 'active': active};
    } catch (_) {
      return {'total': 0, 'active': 0};
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTopTalents(int? sportId) async {
    try {
      final data = sportId != null
          ? await supabase
              .from('athlete_profiles')
              .select('''
                profile_id,
                talent_score,
                level,
                profiles:profile_id(
                  id,
                  full_name,
                  avatar_url,
                  city
                ),
                sports:primary_sport_id(name_fr)
              ''')
              .eq('primary_sport_id', sportId)
              .gte('talent_score', 60)
              .order('talent_score', ascending: false)
              .limit(10)
          : await supabase
              .from('athlete_profiles')
              .select('''
                profile_id,
                talent_score,
                level,
                profiles:profile_id(
                  id,
                  full_name,
                  avatar_url,
                  city
                ),
                sports:primary_sport_id(name_fr)
              ''')
              .gte('talent_score', 60)
              .order('talent_score', ascending: false)
              .limit(10);

      return List<Map<String, dynamic>>.from(data as List);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAffiliatedClubs(
      int? sportId) async {
    try {
      final data = sportId != null
          ? await supabase
              .from('institutions')
              .select('''
                id,
                name,
                official_name,
                logo_url,
                city,
                total_athletes,
                champions_count,
                is_verified
              ''')
              .inFilter('institution_type', ['club', 'academy'])
              .contains('sport_ids', [sportId])
              .order('total_athletes', ascending: false)
              .limit(8)
          : await supabase
              .from('institutions')
              .select('''
                id,
                name,
                official_name,
                logo_url,
                city,
                total_athletes,
                champions_count,
                is_verified
              ''')
              .inFilter('institution_type', ['club', 'academy'])
              .order('total_athletes', ascending: false)
              .limit(8);

      return List<Map<String, dynamic>>.from(data as List);
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, int>> _fetchTalentsByCity(int? sportId) async {
    try {
      // Récupérer les profils avec ville
      final data = sportId != null
          ? await supabase
              .from('athlete_profiles')
              .select('profiles:profile_id(city)')
              .eq('primary_sport_id', sportId)
          : await supabase
              .from('athlete_profiles')
              .select('profiles:profile_id(city)');

      final list = data as List;
      final Map<String, int> counts = {};

      for (final row in list) {
        final profiles = row['profiles'];
        Map<String, dynamic>? profile;
        if (profiles is List && profiles.isNotEmpty) {
          profile = profiles.first as Map<String, dynamic>?;
        } else if (profiles is Map) {
          profile = Map<String, dynamic>.from(profiles);
        }

        final city = profile?['city'] as String?;
        if (city != null && city.isNotEmpty) {
          counts[city] = (counts[city] ?? 0) + 1;
        }
      }

      // Trier par nombre décroissant et garder top 5
      final sorted = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return Map.fromEntries(sorted.take(5));
    } catch (_) {
      return {};
    }
  }

  // ── Actions ──────────────────────────────────────────────
  Future<void> _goToDiscover() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DiscoverScreen()),
    );
  }

  Future<void> _goToMap() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TalentMapScreen()),
    );
  }

  Future<void> _goToNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  Future<void> _goToTalentProfile(String athleteId) async {
    if (athleteId.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfileScreen(userId: athleteId)),
    );
    _loadAll();
  }

  // ── Export (placeholder) ────────────────────────────────
  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📊 Export des données à venir'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.grey600),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loadAll,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadAll,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // ── AppBar ──────────────────────────────────
            SliverAppBar(
              floating: true,
              pinned: true,
              backgroundColor: AppColors.white,
              elevation: 0,
              title: _buildAppBarTitle(),
              actions: [
                IconButton(
                  icon: const Icon(Icons.map_outlined),
                  onPressed: _goToMap,
                  tooltip: 'Carte nationale',
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: _goToNotifications,
                  tooltip: 'Notifications',
                ),
                const LogoutMenuButton(),
              ],
            ),

            // ── Contenu ──────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // En-tête fédération
                  _buildFederationHeader(),
                  const SizedBox(height: 20),

                  // Stats nationales
                  _buildNationalStats(),
                  const SizedBox(height: 20),

                  // Actions rapides
                  _buildQuickActions(),
                  const SizedBox(height: 24),

                  // Répartition géographique
                  if (_talentsByCity.isNotEmpty) ...[
                    _buildGeographicDistribution(),
                    const SizedBox(height: 24),
                  ],

                  // Top talents nationaux
                  _buildTopTalents(),
                  const SizedBox(height: 24),

                  // Clubs affiliés
                  _buildAffiliatedClubs(),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // WIDGETS
  // ══════════════════════════════════════════════════════════

  Widget _buildAppBarTitle() {
    return RichText(
      text: const TextSpan(
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        children: [
          TextSpan(text: 'De', style: TextStyle(color: AppColors.ink)),
          TextSpan(text: 'No', style: TextStyle(color: AppColors.primary)),
          TextSpan(text: 'Ta', style: TextStyle(color: AppColors.accent)),
          TextSpan(
              text: ' Fédération',
              style: TextStyle(color: AppColors.grey400, fontSize: 13)),
        ],
      ),
    );
  }

  // ── En-tête fédération ──────────────────────────────────
  Widget _buildFederationHeader() {
    final name = _institution?['name'] as String? ??
        _institution?['official_name'] as String? ??
        'Ma fédération';
    final logoUrl = _institution?['logo_url'] as String?;
    final city = _institution?['city'] as String?;
    final isVerified = _institution?['is_verified'] as bool? ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: logoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      imageUrl: logoUrl,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.account_balance,
                    color: AppColors.primary,
                    size: 32,
                  ),
          ),
          const SizedBox(width: 16),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified,
                          color: Colors.white70, size: 16),
                    ],
                  ],
                ),
                if (city != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: Colors.white70, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        city,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '🏛️ Vue nationale · 31 régions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats nationales ────────────────────────────────────
  Widget _buildNationalStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📊 Vue nationale',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.people_outline,
                value: '$_totalAthletes',
                label: 'Athlètes',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.business_outlined,
                value: '$_totalClubs',
                label: 'Clubs',
                color: AppColors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.badge_outlined,
                value: '$_totalLicenses',
                label: 'Licences',
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle_outline,
                value: '$_activeLicenses',
                label: 'Licences actives',
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Actions rapides ─────────────────────────────────────
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions rapides',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.map_outlined,
                label: 'Carte\nnationale',
                color: AppColors.primary,
                onTap: _goToMap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.search,
                label: 'Chercher\nun talent',
                color: AppColors.blue,
                onTap: _goToDiscover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.file_download_outlined,
                label: 'Exporter\nles données',
                color: AppColors.accent,
                onTap: _exportData,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Répartition géographique ────────────────────────────
  Widget _buildGeographicDistribution() {
    final maxCount = _talentsByCity.values.isEmpty
        ? 1
        : _talentsByCity.values.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🗺️ Répartition géographique',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Column(
            children: _talentsByCity.entries.map((entry) {
              final percent = maxCount > 0 ? entry.value / maxCount : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${entry.value} athlète${entry.value > 1 ? "s" : ""}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 6,
                        backgroundColor: AppColors.grey200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Top talents ─────────────────────────────────────────
  Widget _buildTopTalents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '🏆 Top talents nationaux',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            TextButton(
              onPressed: _goToDiscover,
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_topTalents.isEmpty)
          _buildEmptyState('Aucun talent avec un score ≥ 60')
        else
          ..._topTalents.map((talent) {
            final profile = talent['profiles'] as Map<String, dynamic>?;
            final athleteId = profile?['id'] as String? ??
                talent['profile_id'] as String? ??
                '';
            return _TalentListTile(
              rank: _topTalents.indexOf(talent) + 1,
              talent: talent,
              onTap: () => _goToTalentProfile(athleteId),
            );
          }),
      ],
    );
  }

  // ── Clubs affiliés ──────────────────────────────────────
  Widget _buildAffiliatedClubs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '🏟️ Clubs affiliés',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            if (_affiliatedClubs.isNotEmpty)
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Liste complète des clubs à venir'),
                    ),
                  );
                },
                child: const Text('Voir tout'),
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (_affiliatedClubs.isEmpty)
          _buildEmptyState('Aucun club affilié pour le moment')
        else
          ..._affiliatedClubs.map((club) => _ClubListTile(club: club)),
      ],
    );
  }

  // ── Empty state ─────────────────────────────────────────
  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.grey400,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGETS AUXILIAIRES
// ══════════════════════════════════════════════════════════════

/// Carte de statistique.
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.grey400,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte d'action rapide.
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ligne de talent dans une liste (avec rang).
class _TalentListTile extends StatelessWidget {
  final Map<String, dynamic> talent;
  final VoidCallback onTap;
  final int rank;

  const _TalentListTile({
    required this.talent,
    required this.onTap,
    this.rank = 0,
  });

  @override
  Widget build(BuildContext context) {
    final profile = talent['profiles'] as Map<String, dynamic>?;
    final name = profile?['full_name'] as String? ?? 'Athlète';
    final avatar = profile?['avatar_url'] as String?;
    final city = profile?['city'] as String?;

    final score = (talent['talent_score'] as num?)?.toDouble() ?? 0;
    final sport = (talent['sports'] as Map?)?['name_fr'] as String?;
    final level = talent['level'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          children: [
            // Rang
            if (rank > 0)
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: _rankColor(rank).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _rankColor(rank),
                    ),
                  ),
                ),
              ),

            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primaryBg,
              backgroundImage:
                  avatar != null ? CachedNetworkImageProvider(avatar) : null,
              child: avatar == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (sport != null) sport,
                      if (city != null) '📍 $city',
                    ].join(' · '),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.grey500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (level != null)
                    Text(
                      _levelLabel(level),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.grey400,
                      ),
                    ),
                ],
              ),
            ),

            // Score
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    score.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentDark,
                      height: 1,
                    ),
                  ),
                  const Text(
                    '/100',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.grey400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _rankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700); // Or
    if (rank == 2) return const Color(0xFFC0C0C0); // Argent
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    return AppColors.grey400;
  }

  String _levelLabel(String level) {
    switch (level) {
      case 'amateur':
        return '🌱 Amateur';
      case 'semi_pro':
        return '⭐ Semi-Pro';
      case 'professional':
        return '🏆 Professionnel';
      default:
        return level;
    }
  }
}

/// Ligne de club.
class _ClubListTile extends StatelessWidget {
  final Map<String, dynamic> club;

  const _ClubListTile({required this.club});

  @override
  Widget build(BuildContext context) {
    final name = club['name'] as String? ??
        club['official_name'] as String? ??
        'Club';
    final logoUrl = club['logo_url'] as String?;
    final city = club['city'] as String?;
    final totalAthletes = club['total_athletes'] as int? ?? 0;
    final champions = club['champions_count'] as int? ?? 0;
    final isVerified = club['is_verified'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: logoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: logoUrl,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.business,
                    color: AppColors.primary,
                    size: 22,
                  ),
          ),
          const SizedBox(width: 12),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified,
                          size: 13, color: AppColors.primary),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (city != null) ...[
                      const Icon(Icons.location_on_outlined,
                          size: 11, color: AppColors.grey400),
                      const SizedBox(width: 2),
                      Text(
                        city,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.grey500,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Icon(Icons.people_outline,
                        size: 11, color: AppColors.grey400),
                    const SizedBox(width: 2),
                    Text(
                      '$totalAthletes athlète${totalAthletes > 1 ? "s" : ""}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Champions
          if (champions > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 3),
                  Text(
                    '$champions',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentDark,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}