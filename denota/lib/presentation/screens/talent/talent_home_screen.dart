// lib/presentation/screens/talent/talent_home_screen.dart
//
// Tableau de bord du talent (athlète).
// C'est le premier écran vu après connexion par un athlète.
//
// Objectifs :
//   - Mettre en avant le Talent Score™
//   - Montrer la visibilité (vues, rapports, abonnés)
//   - Encourager l'action (publier, compléter)
//   - Afficher les dernières publications

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
//import 'package:timeago/timeago.dart' as timeago;

import '../../../core/theme/app_colors.dart';
import '../../../main.dart';
import '../../widgets/profile/talent_score_badge.dart';
import '../post/create_post_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../home/notifications_screen.dart';

// ══════════════════════════════════════════════════════════════
// ÉCRAN PRINCIPAL
// ══════════════════════════════════════════════════════════════

class TalentHomeScreen extends StatefulWidget {
  const TalentHomeScreen({super.key});

  @override
  State<TalentHomeScreen> createState() => _TalentHomeScreenState();
}

class _TalentHomeScreenState extends State<TalentHomeScreen>
    with SingleTickerProviderStateMixin {
  // ── État ────────────────────────────────────────────────
  bool _loading = true;
  String? _error;

  // Profil
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _athleteProfile;

  // Statistiques
  int _recruiterViews = 0;
  int _scoutReports = 0;
  int _followersCount = 0;
  int _profileViews = 0;

  // Publications récentes
  List<Map<String, dynamic>> _recentPosts = [];

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

      // Charger le profil athlète
      final athleteProfile = await supabase
          .from('athlete_profiles')
          .select('''
            *,
            sports:primary_sport_id(name_fr, slug),
            positions:primary_position_id(name_fr)
          ''')
          .eq('profile_id', uid)
          .maybeSingle();

      // Charger les stats en parallèle
      final results = await Future.wait([
        _fetchRecruiterViews(uid),
        _fetchScoutReportsCount(uid),
        _fetchFollowersCount(uid),
        _fetchRecentPosts(uid),
      ]);

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _athleteProfile = athleteProfile;
        _recruiterViews = results[0] as int;
        _scoutReports = results[1] as int;
        _followersCount = results[2] as int;
        _recentPosts = results[3] as List<Map<String, dynamic>>;
        _profileViews = (profile?['profile_views'] as int?) ?? 0;
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

  Future<int> _fetchRecruiterViews(String uid) async {
    try {
      final data = await supabase
          .from('profiles')
          .select('recruiter_view_count')
          .eq('id', uid)
          .maybeSingle();
      return (data?['recruiter_view_count'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _fetchScoutReportsCount(String uid) async {
    try {
      final data = await supabase
          .from('expert_ratings')
          .select('id')
          .eq('athlete_id', uid)
          .eq('report_type', 'scout');
      return (data as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _fetchFollowersCount(String uid) async {
    try {
      final data = await supabase
          .from('follows')
          .select('id')
          .eq('following_id', uid);
      return (data as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRecentPosts(String uid) async {
    try {
      final data = await supabase
          .from('posts')
          .select('id, title, body, content_type, media_urls, thumbnail_url, likes_count, views_count, created_at')
          .eq('author_id', uid)
          .inFilter('status', ['published', 'pending_moderation'])
          .order('created_at', ascending: false)
          .limit(6);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (_) {
      return [];
    }
  }

  // ── Actions ──────────────────────────────────────────────
  Future<void> _goToCreatePost() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
    _loadAll();
  }

  Future<void> _goToEditProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    _loadAll();
  }

  Future<void> _goToProfile() async {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  Future<void> _goToNotifications() async {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
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
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: _goToNotifications,
                  tooltip: 'Notifications',
                ),
                const SizedBox(width: 8),
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

                  // Talent Score
                  _buildTalentScoreCard(),
                  const SizedBox(height: 20),

                  // Stats de visibilité
                  _buildVisibilityStats(),
                  const SizedBox(height: 20),

                  // Actions rapides
                  _buildQuickActions(),
                  const SizedBox(height: 24),

                  // Dernières publications
                  _buildRecentPosts(),
                  const SizedBox(height: 24),

                  // Conseils
                  _buildTipsSection(),
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

  // ── Titre AppBar ────────────────────────────────────────
  Widget _buildAppBarTitle() {
    return RichText(
      text: const TextSpan(
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        children: [
          TextSpan(text: 'De', style: TextStyle(color: AppColors.ink)),
          TextSpan(text: 'No', style: TextStyle(color: AppColors.primary)),
          TextSpan(text: 'Ta', style: TextStyle(color: AppColors.accent)),
        ],
      ),
    );
  }

  // ── Salutation ──────────────────────────────────────────
  Widget _buildGreeting() {
    final name = _profile?['full_name'] as String? ?? 'Athlète';
    final firstName = name.split(' ').first;
    final hour = DateTime.now().hour;

    String greeting;
    if (hour < 12) {
      greeting = 'Bonjour';
    } else if (hour < 18) {
      greeting = 'Bon après-midi';
    } else {
      greeting = 'Bonsoir';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $firstName 👋',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Voici ton activité sur DeNoTa.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.grey500,
          ),
        ),
      ],
    );
  }

  // ── Talent Score Card ───────────────────────────────────
  Widget _buildTalentScoreCard() {
    final score = (_athleteProfile?['talent_score'] as num?)?.toDouble() ?? 0;
    final level = _athleteProfile?['level'] as String?;
    final sportName = _athleteProfile?['sports']?['name_fr'] as String?;

    return Container(
      padding: const EdgeInsets.all(20),
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
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Badge du score
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: TalentScoreBadge(
              score: score,
              size: 110,
              showLabel: false,
            ),
          ),
          const SizedBox(width: 20),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TALENT SCORE™',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),

                // Sport + Level
                if (sportName != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.sports_soccer, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        sportName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],

                if (level != null) ...[
                  Text(
                    _levelLabel(level),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Bouton voir profil
                GestureDetector(
                  onTap: _goToProfile,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Voir mon profil',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                      ],
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

  // ── Stats de visibilité ─────────────────────────────────
  Widget _buildVisibilityStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ta visibilité',
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
              child: _VisibilityStatCard(
                icon: Icons.visibility_outlined,
                value: '$_profileViews',
                label: 'Vues profil',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _VisibilityStatCard(
                icon: Icons.work_outline,
                value: '$_recruiterViews',
                label: 'Vues recruteurs',
                color: AppColors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _VisibilityStatCard(
                icon: Icons.assignment_outlined,
                value: '$_scoutReports',
                label: 'Rapports scouts',
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _VisibilityStatCard(
                icon: Icons.people_outline,
                value: '$_followersCount',
                label: 'Abonnés',
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
                icon: Icons.video_camera_back_outlined,
                label: 'Publier\nune vidéo',
                color: AppColors.primary,
                onTap: _goToCreatePost,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.edit_outlined,
                label: 'Modifier\nle profil',
                color: AppColors.accent,
                onTap: _goToEditProfile,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Dernières publications ──────────────────────────────
  Widget _buildRecentPosts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tes dernières publications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            if (_recentPosts.isNotEmpty)
              TextButton(
                onPressed: _goToProfile,
                child: const Text('Voir tout'),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (_recentPosts.isEmpty)
          _buildEmptyPosts()
        else
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _recentPosts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _PostMiniCard(post: _recentPosts[i]),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyPosts() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 48,
            color: AppColors.grey300,
          ),
          const SizedBox(height: 12),
          const Text(
            'Aucune publication',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Publie ta première vidéo pour être détecté !',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.grey400,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _goToCreatePost,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Publier une vidéo'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Conseils ────────────────────────────────────────────
  Widget _buildTipsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💡 Conseils pour progresser',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        _buildTipCard(
          icon: Icons.video_camera_back,
          title: 'Publie régulièrement',
          description: 'Les recruteurs cherchent des talents actifs. Publie au moins 1 vidéo par semaine.',
          color: AppColors.primary,
        ),
        const SizedBox(height: 10),
        _buildTipCard(
          icon: Icons.badge_outlined,
          title: 'Complète ton profil',
          description: 'Un profil à 100% est 5× plus vu. Ajoute tes stats, ton palmarès et tes licences.',
          color: AppColors.accent,
        ),
        const SizedBox(height: 10),
        _buildTipCard(
          icon: Icons.people_outline,
          title: 'Développe ton réseau',
          description: 'Suis d\'autres athlètes et interagis. Plus ton réseau grandit, plus tu es visible.',
          color: AppColors.blue,
        ),
      ],
    );
  }

  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────
  String _levelLabel(String level) {
    switch (level) {
      case 'amateur':
        return '🌱 Amateur';
      case 'semi_pro':
        return '⭐ Semi-Professionnel';
      case 'professional':
        return '🏆 Professionnel';
      default:
        return 'Niveau non spécifié';
    }
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGETS AUXILIAIRES
// ══════════════════════════════════════════════════════════════

/// Carte de statistique de visibilité.
class _VisibilityStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _VisibilityStatCard({
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
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

/// Mini carte de publication.
class _PostMiniCard extends StatelessWidget {
  final Map<String, dynamic> post;

  const _PostMiniCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final contentType = post['content_type'] as String? ?? 'video';
    final thumbnailUrl = post['thumbnail_url'] as String?;
    final mediaUrls = (post['media_urls'] as List<dynamic>?) ?? [];
    final imageUrl = thumbnailUrl ??
        (mediaUrls.isNotEmpty ? mediaUrls.first as String : null);
    final status = post['status'] as String? ?? 'published';
    final isPending = status == 'pending_moderation';

    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image/Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            child: Stack(
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  color: AppColors.grey100,
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppColors.grey100,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.grey100,
                            child: const Icon(
                              Icons.broken_image,
                              color: AppColors.grey400,
                            ),
                          ),
                        )
                      : Icon(
                          contentType == 'video'
                              ? Icons.videocam
                              : Icons.article,
                          color: AppColors.grey400,
                          size: 32,
                        ),
                ),

                // Badge "en attente"
                if (isPending)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'En attente',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Infos
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post['title'] as String? ?? 'Sans titre',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.favorite_border,
                      size: 12,
                      color: AppColors.grey400,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${post['likes_count'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.grey400,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.visibility_outlined,
                      size: 12,
                      color: AppColors.grey400,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${post['views_count'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.grey400,
                      ),
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
}