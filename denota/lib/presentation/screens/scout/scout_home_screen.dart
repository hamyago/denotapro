// lib/presentation/screens/scout/scout_home_screen.dart
//
// Tableau de bord du recruteur (agent, club, fédération, sponsor).
// C'est l'écran principal pour les utilisateurs B2B de DeNoTa.
//
// Objectifs :
//   - Afficher les stats clés (favoris, contacts, rapports, alertes)
//   - Actions rapides (rechercher, carte, filtres)
//   - Top talents de la semaine
//   - Nouveaux talents
//   - Alertes récentes

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/theme/app_colors.dart';
import '../../../main.dart';
import '../../widgets/common/logout_action.dart';
import '../search/discover_screen.dart';
import '../search/talent_map_screen.dart';
import '../profile/profile_screen.dart';
import '../messaging/conversations_screen.dart';
import '../home/notifications_screen.dart';

// ══════════════════════════════════════════════════════════════
// ÉCRAN PRINCIPAL
// ══════════════════════════════════════════════════════════════

class ScoutHomeScreen extends StatefulWidget {
  const ScoutHomeScreen({super.key});

  @override
  State<ScoutHomeScreen> createState() => _ScoutHomeScreenState();
}

class _ScoutHomeScreenState extends State<ScoutHomeScreen> {
  // ── État ────────────────────────────────────────────────
  bool _loading = true;
  String? _error;

  // Profil et institution
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _institution;

  // Statistiques
  int _favoritesCount = 0;
  int _contactsCount = 0;
  int _reportsCount = 0;
  int _unreadAlertsCount = 0;

  // Talents
  List<Map<String, dynamic>> _topTalents = [];
  List<Map<String, dynamic>> _newTalents = [];

  // Alertes récentes
  List<Map<String, dynamic>> _recentAlerts = [];

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
      // Charger le profil
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();

      // Charger l'institution (si existe)
      final institution = await supabase
          .from('institutions')
          .select()
          .eq('profile_id', uid)
          .maybeSingle();

      // Charger les stats en parallèle
      final results = await Future.wait([
        _fetchFavoritesCount(uid),
        _fetchContactsCount(uid),
        _fetchReportsCount(uid),
        _fetchUnreadAlertsCount(uid),
        _fetchTopTalents(),
        _fetchNewTalents(),
        _fetchRecentAlerts(uid),
      ]);

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _institution = institution;
        _favoritesCount = results[0] as int;
        _contactsCount = results[1] as int;
        _reportsCount = results[2] as int;
        _unreadAlertsCount = results[3] as int;
        _topTalents = results[4] as List<Map<String, dynamic>>;
        _newTalents = results[5] as List<Map<String, dynamic>>;
        _recentAlerts = results[6] as List<Map<String, dynamic>>;
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

  Future<int> _fetchFavoritesCount(String uid) async {
    try {
      final data = await supabase
          .from('favorites')
          .select('id')
          .eq('recruiter_id', uid);
      return (data as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _fetchContactsCount(String uid) async {
    try {
      final data = await supabase
          .from('conversations')
          .select('id')
          .or('participant_1.eq.$uid,participant_2.eq.$uid');
      return (data as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _fetchReportsCount(String uid) async {
    try {
      final data = await supabase
          .from('expert_ratings')
          .select('id')
          .eq('expert_id', uid)
          .eq('report_type', 'scout');
      return (data as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _fetchUnreadAlertsCount(String uid) async {
    try {
      final data = await supabase
          .from('notifications')
          .select('id')
          .eq('recipient_id', uid)
          .eq('is_read', false);
      return (data as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTopTalents() async {
    try {
      final data = await supabase
          .from('athlete_profiles')
          .select('''
            profile_id,
            talent_score,
            level,
            profiles:profile_id(
              full_name,
              avatar_url,
              city
            ),
            sports:primary_sport_id(name_fr)
          ''')
          .gte('talent_score', 50)
          .order('talent_score', ascending: false)
          .limit(5);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchNewTalents() async {
    try {
      final data = await supabase
          .from('profiles')
          .select('''
            id,
            full_name,
            avatar_url,
            city,
            created_at,
            athlete_profiles:athlete_profiles!athlete_profiles_profile_id_fkey(
              talent_score,
              level,
              sports:primary_sport_id(name_fr)
            )
          ''')
          .eq('role', 'athlete')
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(5);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRecentAlerts(String uid) async {
    try {
      final data = await supabase
          .from('notifications')
          .select('id, type, title, body, is_read, created_at')
          .eq('recipient_id', uid)
          .order('created_at', ascending: false)
          .limit(3);
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

  Future<void> _goToMap() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TalentMapScreen()),
    );
  }

  Future<void> _goToMessages() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ConversationsScreen()),
    );
  }

  Future<void> _goToNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  Future<void> _goToTalentProfile(String athleteId) async {
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
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
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
                  icon: Stack(
                    children: [
                      const Icon(Icons.notifications_outlined),
                      if (_unreadAlertsCount > 0)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
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
                  // Salutation
                  _buildGreeting(),
                  const SizedBox(height: 20),

                  // Stats principales
                  _buildMainStats(),
                  const SizedBox(height: 20),

                  // Actions rapides
                  _buildQuickActions(),
                  const SizedBox(height: 24),

                  // Top talents
                  _buildTopTalents(),
                  const SizedBox(height: 24),

                  // Nouveaux talents
                  _buildNewTalents(),
                  const SizedBox(height: 24),

                  // Alertes récentes
                  _buildRecentAlerts(),
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
          TextSpan(text: ' Pro', style: TextStyle(color: AppColors.grey400, fontSize: 14)),
        ],
      ),
    );
  }

  // ── Salutation ──────────────────────────────────────────
  Widget _buildGreeting() {
    final name = _profile?['full_name'] as String? ?? 'Recruteur';
    final firstName = name.split(' ').first;
    final institutionName = _institution?['name'] as String?
        ?? _institution?['official_name'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bonjour, $firstName 👋',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        if (institutionName != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.business_outlined,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  institutionName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ] else ...[
          const SizedBox(height: 4),
          const Text(
            'Voici les derniers talents détectés.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.grey500,
            ),
          ),
        ],
      ],
    );
  }

  // ── Stats principales ───────────────────────────────────
  Widget _buildMainStats() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: [
        _StatCard(
          icon: Icons.bookmark_outline,
          value: '$_favoritesCount',
          label: 'Favoris',
          color: AppColors.primary,
        ),
        _StatCard(
          icon: Icons.send_outlined,
          value: '$_contactsCount',
          label: 'Contacts',
          color: AppColors.blue,
        ),
        _StatCard(
          icon: Icons.assignment_outlined,
          value: '$_reportsCount',
          label: 'Rapports',
          color: AppColors.accent,
        ),
        _StatCard(
          icon: Icons.notifications_outlined,
          value: '$_unreadAlertsCount',
          label: 'Alertes non lues',
          color: _unreadAlertsCount > 0 ? AppColors.error : AppColors.grey400,
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
                icon: Icons.search,
                label: 'Rechercher\nun talent',
                color: AppColors.primary,
                onTap: _goToDiscover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.map_outlined,
                label: 'Carte\ndes talents',
                color: AppColors.blue,
                onTap: _goToMap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.chat_bubble_outline,
                label: 'Mes\nmessages',
                color: AppColors.accent,
                onTap: _goToMessages,
              ),
            ),
          ],
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
              '🏆 Top talents',
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
          _buildEmptyState('Aucun talent pour le moment')
        else
          ..._topTalents.map((talent) => _TalentListTile(
                talent: talent,
                onTap: () => _goToTalentProfile(talent['profile_id'] as String),
              )),
      ],
    );
  }

  // ── Nouveaux talents ────────────────────────────────────
  Widget _buildNewTalents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '✨ Nouveaux talents',
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

        if (_newTalents.isEmpty)
          _buildEmptyState('Aucun nouveau talent récent')
        else
          ..._newTalents.map((talent) => _TalentListTile(
                talent: talent,
                isNew: true,
                onTap: () => _goToTalentProfile(talent['id'] as String),
              )),
      ],
    );
  }

  // ── Alertes récentes ────────────────────────────────────
  Widget _buildRecentAlerts() {
    if (_recentAlerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '🔔 Alertes récentes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            TextButton(
              onPressed: _goToNotifications,
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._recentAlerts.map((alert) => _AlertTile(alert: alert)),
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

/// Carte de statistique principale.
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
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
                  maxLines: 2,
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

/// Ligne de talent dans une liste.
class _TalentListTile extends StatelessWidget {
  final Map<String, dynamic> talent;
  final VoidCallback onTap;
  final bool isNew;

  const _TalentListTile({
    required this.talent,
    required this.onTap,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    // Deux formats possibles selon la source
    final profile = talent['profiles'] as Map<String, dynamic>?;
    final name = profile?['full_name'] as String?
        ?? talent['full_name'] as String?
        ?? 'Athlète';
    final avatar = profile?['avatar_url'] as String?
        ?? talent['avatar_url'] as String?;
    final city = profile?['city'] as String?
        ?? talent['city'] as String?;

    // athlete_profiles peut être objet ou liste
    final apRaw = talent['athlete_profiles'];
    Map<String, dynamic>? ap;
    if (apRaw is List && apRaw.isNotEmpty) {
      ap = Map<String, dynamic>.from(apRaw.first as Map);
    } else if (apRaw is Map) {
      ap = Map<String, dynamic>.from(apRaw);
    }

    final score = (ap?['talent_score'] as num?)?.toDouble()
        ?? (talent['talent_score'] as num?)?.toDouble()
        ?? 0;
    final sport = (ap?['sports'] as Map?)?['name_fr'] as String?
        ?? (talent['sports'] as Map?)?['name_fr'] as String?;
    final level = ap?['level'] as String? ?? talent['level'] as String?;

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
                      if (isNew) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'NEW',
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

            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios,
                size: 12, color: AppColors.grey300),
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
        return '🏆 Professionnel';
      default:
        return level;
    }
  }
}

/// Ligne d'alerte.
class _AlertTile extends StatelessWidget {
  final Map<String, dynamic> alert;

  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final isRead = alert['is_read'] == true;
    final createdAt = DateTime.tryParse(alert['created_at'] as String? ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRead ? AppColors.white : AppColors.primaryBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['title'] as String? ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                if (alert['body'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    alert['body'] as String,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.grey500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(createdAt, locale: 'fr'),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.grey400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isRead)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}