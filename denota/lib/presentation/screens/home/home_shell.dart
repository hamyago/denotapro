// lib/presentation/screens/home/home_shell.dart
//
// Shell principal de l'application.
// Route l'utilisateur vers l'écran d'accueil correspondant à son rôle.
//
// Navigation par rôle :
//   - athlete     → TalentHomeScreen
//   - recruiter   → ScoutHomeScreen
//   - institution → InstitutionDashboardScreen
//   - federation  → FederationDashboardScreen
//   - admin       → AdminDashboardScreen
//   - sponsor     → ScoutHomeScreen (fallback)
//   - expert      → ScoutHomeScreen (fallback)

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../main.dart';
import 'tiktok_feed_screen.dart';
import 'notifications_screen.dart';
import '../search/discover_screen.dart';
import '../messaging/conversations_screen.dart';
import '../profile/profile_screen.dart';
//import '../recruiter/recruiter_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../auth/account_status_screen.dart';

// Nouveaux écrans DeNoTa
import '../talent/talent_home_screen.dart';
import '../scout/scout_home_screen.dart';
import '../institution/institution_dashboard_screen.dart';
import '../federation/federation_dashboard_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  String _role = 'athlete';
  String _status = 'active';
  bool _roleLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  // ── Chargement du rôle et du statut ─────────────────────
  Future<void> _loadRole() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid != null) {
      try {
        final data = await supabase
            .from('profiles')
            .select('role, status')
            .eq('id', uid)
            .maybeSingle();
        if (data != null && mounted) {
          setState(() {
            _role = data['role'] as String? ?? 'athlete';
            _status = data['status'] as String? ?? 'active';
            _roleLoaded = true;
          });
          return;
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _roleLoaded = true);
  }

  // ── Écran d'accueil selon le rôle ────────────────────────
  Widget _getHomeScreen() {
    switch (_role) {
      case 'recruiter':
        return const ScoutHomeScreen();
      case 'institution':
        return const InstitutionDashboardScreen();
      case 'federation':
        return const FederationDashboardScreen();
      case 'admin':
        return const AdminDashboardScreen();
      case 'sponsor':
      case 'expert':
        // Fallback : sponsor et expert utilisent le dashboard scout
        return const ScoutHomeScreen();
      case 'athlete':
      default:
        return const TalentHomeScreen();
    }
  }

  // ── Écran "Découvrir" selon le rôle ─────────────────────
  Widget _getDiscoverScreen() {
    // Pour les athlètes : TikTokFeed (contenu social)
    // Pour les autres : DiscoverScreen (recherche de talents)
    if (_role == 'athlete') {
      return TikTokFeedScreen(isActive: _currentIndex == 1);
    }
    return const DiscoverScreen();
  }

  // ── Label et icône du 1er onglet selon le rôle ──────────
  String get _homeLabel {
    switch (_role) {
      case 'recruiter':
        return 'Dashboard';
      case 'institution':
        return 'Club';
      case 'federation':
        return 'Fédé';
      case 'admin':
        return 'Admin';
      case 'sponsor':
      case 'expert':
        return 'Dashboard';
      case 'athlete':
      default:
        return 'Accueil';
    }
  }

  IconData get _homeIcon {
    switch (_role) {
      case 'recruiter':
        return Icons.dashboard_outlined;
      case 'institution':
        return Icons.business_outlined;
      case 'federation':
        return Icons.account_balance_outlined;
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      case 'sponsor':
      case 'expert':
        return Icons.dashboard_outlined;
      case 'athlete':
      default:
        return Icons.home_outlined;
    }
  }

  IconData get _homeSelectedIcon {
    switch (_role) {
      case 'recruiter':
        return Icons.dashboard;
      case 'institution':
        return Icons.business;
      case 'federation':
        return Icons.account_balance;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'sponsor':
      case 'expert':
        return Icons.dashboard;
      case 'athlete':
      default:
        return Icons.home;
    }
  }

  // ── Label et icône du 2e onglet selon le rôle ──────────
  String get _discoverLabel {
    return _role == 'athlete' ? 'Découvrir' : 'Talents';
  }

  IconData get _discoverIcon {
    return _role == 'athlete'
        ? Icons.explore_outlined
        : Icons.search_outlined;
  }

  IconData get _discoverSelectedIcon {
    return _role == 'athlete' ? Icons.explore : Icons.search;
  }

  // ── Liste des écrans (5 onglets) ─────────────────────────
  List<Widget> get _screens {
    return [
      _getHomeScreen(),
      _getDiscoverScreen(),
      const ConversationsScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];
  }

  // ── Destinations de la barre de navigation ──────────────
  List<NavigationDestination> get _destinations {
    return [
      NavigationDestination(
        icon: Icon(_homeIcon),
        selectedIcon: Icon(_homeSelectedIcon, color: AppColors.primary),
        label: _homeLabel,
      ),
      NavigationDestination(
        icon: Icon(_discoverIcon),
        selectedIcon: Icon(_discoverSelectedIcon, color: AppColors.primary),
        label: _discoverLabel,
      ),
      const NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline),
        selectedIcon: Icon(Icons.chat_bubble, color: AppColors.primary),
        label: 'Messages',
      ),
      const NavigationDestination(
        icon: Icon(Icons.notifications_outlined),
        selectedIcon: Icon(Icons.notifications, color: AppColors.primary),
        label: 'Alertes',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outlined),
        selectedIcon: Icon(Icons.person, color: AppColors.primary),
        label: 'Profil',
      ),
    ];
  }

  // ── Build ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Chargement initial
    if (!_roleLoaded) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // Compte non validé / bloqué
    if (_status != 'active') {
      return AccountStatusScreen(
        status: _status,
        onRefresh: () async {
          setState(() => _roleLoaded = false);
          await _loadRole();
        },
      );
    }

    // Interface principale
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.grey200, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: AppColors.white,
          indicatorColor: AppColors.primaryBg,
          destinations: _destinations,
        ),
      ),
    );
  }
}