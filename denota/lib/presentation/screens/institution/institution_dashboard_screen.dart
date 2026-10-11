// lib/presentation/screens/institution/institution_dashboard_screen.dart
//
// Tableau de bord d'une institution (club, académie, fédération).
// Permet de gérer son effectif d'athlètes, ses licences et sa visibilité.
//
// Différence avec ScoutHomeScreen :
//   - ScoutHomeScreen : cherche des talents EXTERNES
//   - InstitutionDashboardScreen : gère ses PROPRES athlètes

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_colors.dart';
import '../../../main.dart';
import '../../widgets/common/logout_action.dart';
import '../search/discover_screen.dart';
import '../profile/profile_screen.dart';
import '../home/notifications_screen.dart';

// ══════════════════════════════════════════════════════════════
// ÉCRAN PRINCIPAL
// ══════════════════════════════════════════════════════════════

class InstitutionDashboardScreen extends StatefulWidget {
  const InstitutionDashboardScreen({super.key});

  @override
  State<InstitutionDashboardScreen> createState() =>
      _InstitutionDashboardScreenState();
}

class _InstitutionDashboardScreenState
    extends State<InstitutionDashboardScreen> {
  // ── État ────────────────────────────────────────────────
  bool _loading = true;
  String? _error;

  // Institution
  Map<String, dynamic>? _institution;

  // Statistiques
  int _activeAthletes = 0;
  int _pendingAthletes = 0;
  int _championsCount = 0;
  int? _maxAthletes;

  // Listes
  List<Map<String, dynamic>> _roster = [];
  List<Map<String, dynamic>> _pendingRequests = [];

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
          _error = 'Aucune institution associée à ce compte';
          _loading = false;
        });
        return;
      }

      final institutionId = institution['id'] as String;
      final maxAthletes = institution['max_athletes'] as int?;

      // Charger l'effectif et les demandes en parallèle
      final results = await Future.wait([
        _fetchRoster(institutionId),
        _fetchPendingRequests(institutionId),
      ]);

      final roster = results[0];
      final pending = results[1];

      if (!mounted) return;

      setState(() {
        _institution = institution;
        _roster = roster;
        _pendingRequests = pending;
        _activeAthletes = roster.length;
        _pendingAthletes = pending.length;
        _championsCount = (institution['champions_count'] as int?) ?? 0;
        _maxAthletes = maxAthletes;
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

  Future<List<Map<String, dynamic>>> _fetchRoster(String institutionId) async {
    try {
      final data = await supabase
          .from('athlete_institutions')
          .select('''
            id,
            is_current,
            joined_at,
            role_in_club,
            athlete:athlete_id(
              id,
              full_name,
              avatar_url,
              city,
              athlete_profiles:athlete_profiles!athlete_profiles_profile_id_fkey(
                talent_score,
                level,
                sports:primary_sport_id(name_fr)
              )
            )
          ''')
          .eq('institution_id', institutionId)
          .eq('is_current', true)
          .order('joined_at', ascending: false)
          .limit(20);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPendingRequests(
      String institutionId) async {
    try {
      final data = await supabase
          .from('athlete_institutions')
          .select('''
            id,
            is_current,
            joined_at,
            role_in_club,
            athlete:athlete_id(
              id,
              full_name,
              avatar_url,
              city,
              athlete_profiles:athlete_profiles!athlete_profiles_profile_id_fkey(
                talent_score,
                level,
                sports:primary_sport_id(name_fr)
              )
            )
          ''')
          .eq('institution_id', institutionId)
          .eq('is_current', false)
          .order('created_at', ascending: false)
          .limit(10);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (_) {
      return [];
    }
  }

  // ── Actions ──────────────────────────────────────────────
  Future<void> _goToDiscover() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DiscoverScreen()),
    );
  }

  Future<void> _goToNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  Future<void> _goToAthleteProfile(String athleteId) async {
    if (athleteId.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfileScreen(userId: athleteId)),
    );
    _loadAll();
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
                  icon: const Icon(Icons.search),
                  onPressed: _goToDiscover,
                  tooltip: 'Rechercher',
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
                  // En-tête institution
                  _buildInstitutionHeader(),
                  const SizedBox(height: 20),

                  // Stats
                  _buildStats(),
                  const SizedBox(height: 20),

                  // Actions rapides
                  _buildQuickActions(),
                  const SizedBox(height: 24),

                  // Effectif
                  _buildRoster(),
                  const SizedBox(height: 24),

                  // Athlètes en attente
                  if (_pendingAthletes > 0) _buildPendingRequests(),
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
              text: ' Club',
              style: TextStyle(color: AppColors.grey400, fontSize: 14)),
        ],
      ),
    );
  }

  // ── En-tête institution ────────────────────────────────
  Widget _buildInstitutionHeader() {
    final name = _institution?['name'] as String? ??
        _institution?['official_name'] as String? ??
        'Mon institution';
    final logoUrl = _institution?['logo_url'] as String?;
    final city = _institution?['city'] as String?;
    final isVerified = _institution?['is_verified'] as bool? ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
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
                    Icons.business,
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
                const SizedBox(height: 8),
                Text(
                  '$_activeAthletes athlète${_activeAthletes > 1 ? "s" : ""} actif${_activeAthletes > 1 ? "s" : ""}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats ───────────────────────────────────────────────
  Widget _buildStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mon institution',
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
                value: '$_activeAthletes',
                label: 'Effectif',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.emoji_events_outlined,
                value: '$_championsCount',
                label: 'Champions',
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.hourglass_top_outlined,
                value: '$_pendingAthletes',
                label: 'En attente',
                color: _pendingAthletes > 0
                    ? AppColors.warning
                    : AppColors.grey400,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.vertical_align_top,
                value: _maxAthletes != null
                    ? '${_maxAthletes! - _activeAthletes}'
                    : '∞',
                label: 'Places dispo',
                color: AppColors.blue,
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
                icon: Icons.person_add_outlined,
                label: 'Ajouter\nun athlète',
                color: AppColors.primary,
                onTap: _goToDiscover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.list_alt_outlined,
                label: 'Voir\nl\'effectif',
                color: AppColors.blue,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Écran effectif à venir'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.badge_outlined,
                label: 'Gérer\nlicences',
                color: AppColors.accent,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Écran licences à venir'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Effectif ────────────────────────────────────────────
  Widget _buildRoster() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '👥 Mon effectif',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            if (_roster.isNotEmpty)
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Écran effectif complet à venir'),
                    ),
                  );
                },
                child: const Text('Voir tout'),
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (_roster.isEmpty)
          _buildEmptyState(
            'Aucun athlète dans ton effectif',
            'Commence par chercher des talents à ajouter.',
          )
        else
          ..._roster.take(5).map((entry) => _AthleteListTile(
                entry: entry,
                onTap: () => _goToAthleteProfile(
                  (entry['athlete'] as Map?)?['id'] as String? ?? '',
                ),
              )),
      ],
    );
  }

  // ── Athlètes en attente ─────────────────────────────────
  Widget _buildPendingRequests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  '⏳ En attente',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$_pendingAthletes',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        ..._pendingRequests.map((entry) => _AthleteListTile(
              entry: entry,
              isPending: true,
              onTap: () => _goToAthleteProfile(
                (entry['athlete'] as Map?)?['id'] as String? ?? '',
              ),
            )),
      ],
    );
  }

  // ── Empty state ─────────────────────────────────────────
  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.people_outline,
            size: 48,
            color: AppColors.grey300,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.grey600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.grey400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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

/// Ligne d'athlète dans une liste.
class _AthleteListTile extends StatelessWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onTap;
  final bool isPending;

  const _AthleteListTile({
    required this.entry,
    required this.onTap,
    this.isPending = false,
  });

  @override
  Widget build(BuildContext context) {
    final athlete = entry['athlete'] as Map<String, dynamic>?;
    final name = athlete?['full_name'] as String? ?? 'Athlète';
    final avatar = athlete?['avatar_url'] as String?;
    final city = athlete?['city'] as String?;

    // athlete_profiles peut être objet ou liste
    final apRaw = athlete?['athlete_profiles'];
    Map<String, dynamic>? ap;
    if (apRaw is List && apRaw.isNotEmpty) {
      ap = Map<String, dynamic>.from(apRaw.first as Map);
    } else if (apRaw is Map) {
      ap = Map<String, dynamic>.from(apRaw);
    }

    final score = (ap?['talent_score'] as num?)?.toDouble() ?? 0;
    final sport = (ap?['sports'] as Map?)?['name_fr'] as String?;
    final level = ap?['level'] as String?;
    final roleInClub = entry['role_in_club'] as String? ?? 'player';
    final joinedAt = entry['joined_at'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPending
                ? AppColors.warning.withValues(alpha: 0.4)
                : AppColors.grey200,
          ),
        ),
        child: Row(
          children: [
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
                      if (isPending) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.warning,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'EN ATTENTE',
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
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
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _RoleChip(role: roleInClub),
                      if (level != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          _levelLabel(level),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.grey400,
                          ),
                        ),
                      ],
                      if (joinedAt != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '· ${_joinedLabel(joinedAt)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.grey400,
                          ),
                        ),
                      ],
                    ],
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
                      fontSize: 15,
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

  String _levelLabel(String level) {
    switch (level) {
      case 'amateur':
        return '🌱 Amateur';
      case 'semi_pro':
        return '⭐ Semi-Pro';
      case 'professional':
        return '🏆 Pro';
      default:
        return level;
    }
  }

  String _joinedLabel(String joinedAt) {
    final date = DateTime.tryParse(joinedAt);
    if (date == null) return '';
    final months = (DateTime.now().year - date.year) * 12 +
        (DateTime.now().month - date.month);
    if (months < 1) return 'Nouveau';
    if (months < 12) return '$months mois';
    final years = months ~/ 12;
    return '$years an${years > 1 ? "s" : ""}';
  }
}

/// Chip de rôle dans le club.
class _RoleChip extends StatelessWidget {
  final String role;

  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final (label, emoji, color) = _roleInfo(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$emoji $label',
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (String, String, Color) _roleInfo(String role) {
    switch (role) {
      case 'player':
        return ('Joueur', '🏃', AppColors.primary);
      case 'trainee':
        return ('Stagiaire', '📚', AppColors.blue);
      case 'coach':
        return ('Entraîneur', '🎓', AppColors.accentDark);
      case 'staff':
        return ('Staff', '👔', AppColors.grey500);
      default:
        return (role, '•', AppColors.grey500);
    }
  }
}