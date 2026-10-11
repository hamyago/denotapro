// lib/core/constants/sports.dart
//
// Constantes sportives de DeNoTa.
// Contient les sports pilotes, les positions, les niveaux, etc.
// Source unique de vérité pour toute l'application.

// ══════════════════════════════════════════════════════════════
// SPORTS PILOTES (PHASE 1)
// ══════════════════════════════════════════════════════════════

/// Les 4 sports pilotes de la phase 1.
/// L'ordre détermine l'affichage dans les listes.
enum SportType {
  football(
    id: 1,
    slug: 'football',
    nameFr: 'Football',
    nameEn: 'Football',
    emoji: '⚽',
    description: 'Le sport roi en Côte d\'Ivoire',
  ),
  basketball(
    id: 2,
    slug: 'basketball',
    nameFr: 'Basketball',
    nameEn: 'Basketball',
    emoji: '🏀',
    description: 'Sport en pleine expansion avec NBA Africa',
  ),
  athletics(
    id: 3,
    slug: 'athletics',
    nameFr: 'Athlétisme',
    nameEn: 'Athletics',
    emoji: '🏃',
    description: 'Discipline olympique par excellence',
  ),
  taekwondo(
    id: 10,
    slug: 'taekwondo',
    nameFr: 'Taekwondo',
    nameEn: 'Taekwondo',
    emoji: '🥋',
    description: 'Art martial coréen, discipline olympique',
  );

  const SportType({
    required this.id,
    required this.slug,
    required this.nameFr,
    required this.nameEn,
    required this.emoji,
    required this.description,
  });

  final int id;
  final String slug;
  final String nameFr;
  final String nameEn;
  final String emoji;
  final String description;

  /// Retrouve un sport par son ID Supabase.
  static SportType? fromId(int id) {
    for (final s in SportType.values) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Retrouve un sport par son slug.
  static SportType? fromSlug(String slug) {
    for (final s in SportType.values) {
      if (s.slug == slug) return s;
    }
    return null;
  }
}

// ══════════════════════════════════════════════════════════════
// POSITIONS / SPÉCIALITÉS PAR SPORT
// ══════════════════════════════════════════════════════════════

/// Positions/spécialités pour chaque sport.
/// Utilisé dans le formulaire d'inscription et les filtres de recherche.
const Map<SportType, List<SportPosition>> kPositionsBySport = {
  SportType.football: [
    SportPosition(id: 1,  nameFr: 'Gardien de but',   slug: 'goalkeeper',   abbreviation: 'GB'),
    SportPosition(id: 2,  nameFr: 'Défenseur central', slug: 'center_back',  abbreviation: 'DC'),
    SportPosition(id: 3,  nameFr: 'Latéral droit',    slug: 'right_back',   abbreviation: 'LD'),
    SportPosition(id: 4,  nameFr: 'Latéral gauche',   slug: 'left_back',    abbreviation: 'LG'),
    SportPosition(id: 5,  nameFr: 'Milieu défensif',  slug: 'defensive_mid', abbreviation: 'MDF'),
    SportPosition(id: 6,  nameFr: 'Milieu central',   slug: 'central_mid',  abbreviation: 'MC'),
    SportPosition(id: 7,  nameFr: 'Milieu offensif',  slug: 'attacking_mid', abbreviation: 'MO'),
    SportPosition(id: 8,  nameFr: 'Ailier droit',     slug: 'right_wing',   abbreviation: 'AD'),
    SportPosition(id: 9,  nameFr: 'Ailier gauche',    slug: 'left_wing',    abbreviation: 'AG'),
    SportPosition(id: 10, nameFr: 'Attaquant',        slug: 'striker',      abbreviation: 'ATT'),
  ],
  SportType.basketball: [
    SportPosition(id: 20, nameFr: 'Meneur',           slug: 'point_guard',     abbreviation: 'PG'),
    SportPosition(id: 21, nameFr: 'Arrière',          slug: 'shooting_guard',  abbreviation: 'SG'),
    SportPosition(id: 22, nameFr: 'Ailier',           slug: 'small_forward',   abbreviation: 'SF'),
    SportPosition(id: 23, nameFr: 'Ailier fort',      slug: 'power_forward',   abbreviation: 'PF'),
    SportPosition(id: 24, nameFr: 'Pivot',            slug: 'center',          abbreviation: 'C'),
  ],
  SportType.athletics: [
    SportPosition(id: 30, nameFr: 'Sprint (100m, 200m)', slug: 'sprint',        abbreviation: 'SPR'),
    SportPosition(id: 31, nameFr: 'Demi-fond (800m, 1500m)', slug: 'middle_distance', abbreviation: 'DF'),
    SportPosition(id: 32, nameFr: 'Fond (5000m, 10000m)', slug: 'long_distance', abbreviation: 'FON'),
    SportPosition(id: 33, nameFr: 'Saut en longueur',  slug: 'long_jump',     abbreviation: 'SL'),
    SportPosition(id: 34, nameFr: 'Saut en hauteur',   slug: 'high_jump',     abbreviation: 'SH'),
    SportPosition(id: 35, nameFr: 'Lancer du poids',   slug: 'shot_put',      abbreviation: 'LP'),
    SportPosition(id: 36, nameFr: 'Lancer du javelot', slug: 'javelin',       abbreviation: 'LJ'),
    SportPosition(id: 37, nameFr: 'Relais',            slug: 'relay',         abbreviation: 'REL'),
  ],
  SportType.taekwondo: [
    SportPosition(id: 40, nameFr: 'Poids mouche (-54kg)',  slug: 'flyweight',    abbreviation: 'PM'),
    SportPosition(id: 41, nameFr: 'Poids coq (-58kg)',     slug: 'bantamweight', abbreviation: 'PC'),
    SportPosition(id: 42, nameFr: 'Poids plume (-63kg)',   slug: 'featherweight', abbreviation: 'PP'),
    SportPosition(id: 43, nameFr: 'Poids léger (-68kg)',   slug: 'lightweight',  abbreviation: 'PL'),
    SportPosition(id: 44, nameFr: 'Poids welter (-74kg)',  slug: 'welterweight', abbreviation: 'PW'),
    SportPosition(id: 45, nameFr: 'Poids moyen (-80kg)',   slug: 'middleweight', abbreviation: 'PMO'),
    SportPosition(id: 46, nameFr: 'Poids lourd (+80kg)',   slug: 'heavyweight',  abbreviation: 'PLO'),
  ],
};

/// Représente une position/spécialité dans un sport.
class SportPosition {
  const SportPosition({
    required this.id,
    required this.nameFr,
    required this.slug,
    this.abbreviation,
  });

  final int id;
  final String nameFr;
  final String slug;
  final String? abbreviation;
}

// ══════════════════════════════════════════════════════════════
// NIVEAUX
// ══════════════════════════════════════════════════════════════

enum AthleteLevel {
  amateur(
    slug: 'amateur',
    labelFr: 'Amateur',
    emoji: '🌱',
    description: 'Pratique en loisir ou en club local',
  ),
  semiPro(
    slug: 'semi_pro',
    labelFr: 'Semi-Professionnel',
    emoji: '⭐',
    description: 'Pratique en compétition régionale ou nationale',
  ),
  professional(
    slug: 'professional',
    labelFr: 'Professionnel',
    emoji: '🏆',
    description: 'Pratique en compétition nationale ou internationale',
  );

  const AthleteLevel({
    required this.slug,
    required this.labelFr,
    required this.emoji,
    required this.description,
  });

  final String slug;
  final String labelFr;
  final String emoji;
  final String description;

  static AthleteLevel? fromSlug(String slug) {
    for (final l in AthleteLevel.values) {
      if (l.slug == slug) return l;
    }
    return null;
  }
}

// ══════════════════════════════════════════════════════════════
// DISPONIBILITÉS
// ══════════════════════════════════════════════════════════════

enum Availability {
  immediate(
    slug: 'immediate',
    labelFr: 'Disponible immédiatement',
    shortLabel: 'Immédiat',
    emoji: '🟢',
  ),
  threeMonths(
    slug: '3_months',
    labelFr: 'Disponible dans 3 mois',
    shortLabel: '3 mois',
    emoji: '🟡',
  ),
  sixMonths(
    slug: '6_months',
    labelFr: 'Disponible dans 6 mois',
    shortLabel: '6 mois',
    emoji: '🟠',
  ),
  notAvailable(
    slug: 'not_available',
    labelFr: 'Non disponible',
    shortLabel: 'Non dispo',
    emoji: '🔴',
  );

  const Availability({
    required this.slug,
    required this.labelFr,
    required this.shortLabel,
    required this.emoji,
  });

  final String slug;
  final String labelFr;
  final String shortLabel;
  final String emoji;

  static Availability? fromSlug(String slug) {
    for (final a in Availability.values) {
      if (a.slug == slug) return a;
    }
    return null;
  }
}

// ══════════════════════════════════════════════════════════════
// CATÉGORIES D'ÂGE
// ══════════════════════════════════════════════════════════════

enum AgeCategory {
  u15(slug: 'U15', labelFr: 'Moins de 15 ans', minAge: 10, maxAge: 15),
  u18(slug: 'U18', labelFr: 'Moins de 18 ans', minAge: 15, maxAge: 18),
  u21(slug: 'U21', labelFr: 'Moins de 21 ans', minAge: 18, maxAge: 21),
  senior(slug: 'Senior', labelFr: 'Senior', minAge: 21, maxAge: 99);

  const AgeCategory({
    required this.slug,
    required this.labelFr,
    required this.minAge,
    required this.maxAge,
  });

  final String slug;
  final String labelFr;
  final int minAge;
  final int maxAge;

  static AgeCategory? fromAge(int age) {
    for (final c in AgeCategory.values) {
      if (age >= c.minAge && age < c.maxAge) return c;
    }
    return null;
  }
}

// ══════════════════════════════════════════════════════════════
// TYPES D'INSTITUTIONS
// ══════════════════════════════════════════════════════════════

enum InstitutionType {
  club(
    slug: 'club',
    labelFr: 'Club',
    emoji: '🏟️',
    description: 'Club sportif professionnel ou amateur',
  ),
  academy(
    slug: 'academy',
    labelFr: 'Académie / École',
    emoji: '🏫',
    description: 'Centre de formation ou académie sportive',
  ),
  federation(
    slug: 'federation',
    labelFr: 'Fédération',
    emoji: '🏛️',
    description: 'Fédération sportive nationale ou régionale',
  ),
  agent(
    slug: 'agent',
    labelFr: 'Agent / Manager',
    emoji: '🤝',
    description: 'Agent de joueurs ou manager sportif',
  ),
  sponsor(
    slug: 'sponsor',
    labelFr: 'Sponsor / Marque',
    emoji: '💰',
    description: 'Marque ou entreprise sponsor',
  );

  const InstitutionType({
    required this.slug,
    required this.labelFr,
    required this.emoji,
    required this.description,
  });

  final String slug;
  final String labelFr;
  final String emoji;
  final String description;

  static InstitutionType? fromSlug(String slug) {
    for (final t in InstitutionType.values) {
      if (t.slug == slug) return t;
    }
    return null;
  }
}

// ══════════════════════════════════════════════════════════════
// TYPES DE CONTRATS
// ══════════════════════════════════════════════════════════════

enum ContractType {
  fullTime(slug: 'full_time', labelFr: 'Temps plein'),
  partTime(slug: 'part_time', labelFr: 'Temps partiel'),
  trial(slug: 'trial', labelFr: 'Essai'),
  youth(slug: 'youth', labelFr: 'Contrat jeune'),
  professional(slug: 'professional', labelFr: 'Contrat professionnel');

  const ContractType({required this.slug, required this.labelFr});

  final String slug;
  final String labelFr;
}

// ══════════════════════════════════════════════════════════════
// NIVEAUX KYC
// ══════════════════════════════════════════════════════════════

enum KycLevel {
  none(slug: 'none', labelFr: 'Non vérifié'),
  email(slug: 'email', labelFr: 'Email vérifié'),
  phone(slug: 'phone', labelFr: 'Téléphone vérifié'),
  identity(slug: 'identity', labelFr: 'Identité vérifiée'),
  full(slug: 'full', labelFr: 'Certifié DeNoTa');

  const KycLevel({required this.slug, required this.labelFr});

  final String slug;
  final String labelFr;

  static KycLevel? fromSlug(String slug) {
    for (final k in KycLevel.values) {
      if (k.slug == slug) return k;
    }
    return null;
  }
}

// ══════════════════════════════════════════════════════════════
// RECOMMANDATIONS DE SCOUTING
// ══════════════════════════════════════════════════════════════

enum ScoutRecommendation {
  sign(
    slug: 'sign',
    labelFr: 'À recruter',
    emoji: '✅',
    color: 0xFF10B981,
  ),
  watch(
    slug: 'watch',
    labelFr: 'À surveiller',
    emoji: '👀',
    color: 0xFFF59E0B,
  ),
  pass(
    slug: 'pass',
    labelFr: 'Ne pas donner suite',
    emoji: '❌',
    color: 0xFFEF4444,
  );

  const ScoutRecommendation({
    required this.slug,
    required this.labelFr,
    required this.emoji,
    required this.color,
  });

  final String slug;
  final String labelFr;
  final String emoji;
  final int color;

  static ScoutRecommendation? fromSlug(String slug) {
    for (final r in ScoutRecommendation.values) {
      if (r.slug == slug) return r;
    }
    return null;
  }
}

// ══════════════════════════════════════════════════════════════
// HELPERS
// ══════════════════════════════════════════════════════════════

/// Retourne la liste des noms français des sports pilotes.
List<String> get kSportNames =>
    SportType.values.map((s) => s.nameFr).toList();

/// Retourne la liste des sports sous forme de Map (pour Supabase).
List<Map<String, dynamic>> get kSportsAsMaps => SportType.values
    .map((s) => {
          'id': s.id,
          'slug': s.slug,
          'name_fr': s.nameFr,
          'name_en': s.nameEn,
          'emoji': s.emoji,
          'description': s.description,
        })
    .toList();