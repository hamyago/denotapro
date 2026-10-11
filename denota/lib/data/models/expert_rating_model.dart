// lib/data/models/expert_rating_model.dart
//
// Modèle unifié pour les évaluations d'experts ET les rapports de scouting.
// Correspond au schéma Supabase réel (table `expert_ratings`).
//
// Deux usages distincts via `reportType` :
//   - 'expert' : évaluation publique d'un athlète par un expert
//   - 'scout'  : rapport privé d'un recruteur (avec recommandation)
//
// Schéma Supabase :
//   id, expert_id, athlete_id, technique_score, physical_score,
//   mental_score, stats_score, potential_score, global_score,
//   comment, sport_id, context, is_public, created_at,
//   report_type, recommendation, tags, match_date,
//   institution_id, is_shared, updated_at

import '../../core/constants/sports.dart';

// ══════════════════════════════════════════════════════════════
// ENUM : Type de rapport
// ══════════════════════════════════════════════════════════════

enum ReportType {
  expert(
    slug: 'expert',
    labelFr: 'Évaluation d\'expert',
    emoji: '⭐',
    description: 'Évaluation publique visible sur le profil',
  ),
  scout(
    slug: 'scout',
    labelFr: 'Rapport de scouting',
    emoji: '🔍',
    description: 'Rapport privé de recruteur',
  );

  const ReportType({
    required this.slug,
    required this.labelFr,
    required this.emoji,
    required this.description,
  });

  final String slug;
  final String labelFr;
  final String emoji;
  final String description;

  static ReportType? fromSlug(String slug) {
    for (final t in ReportType.values) {
      if (t.slug == slug) return t;
    }
    return null;
  }
}

// ══════════════════════════════════════════════════════════════
// MODÈLE PRINCIPAL
// ══════════════════════════════════════════════════════════════

/// Modèle représentant une évaluation d'expert OU un rapport de scouting.
///
/// La distinction se fait via [reportType] :
/// - `ReportType.expert` → évaluation publique (notation experte)
/// - `ReportType.scout` → rapport privé (recommandation sign/watch/pass)
class ExpertRatingModel {
  // ── Identifiants ────────────────────────────────────────
  final String id;
  final String expertId;      // Le créateur (expert OU scout)
  final String athleteId;     // L'athlète évalué
  final String? institutionId; // Pour quel club (scouts uniquement)

  // ── Type de rapport ─────────────────────────────────────
  final ReportType reportType;

  // ── 5 scores (0-10 chacun) ──────────────────────────────
  final double techniqueScore;
  final double physicalScore;
  final double mentalScore;
  final double statsScore;
  final double potentialScore;
  final double globalScore;

  // ── Évaluation qualitative ──────────────────────────────
  final String? comment;
  final String? recommendation;  // 'sign', 'watch', 'pass' (scouts uniquement)
  final List<String> tags;

  // ── Contexte ────────────────────────────────────────────
  final int? sportId;
  final String? context;         // Contexte de l'évaluation
  final DateTime? matchDate;     // Date du match observé

  // ── Visibilité ──────────────────────────────────────────
  final bool isPublic;   // Pour les évaluations d'experts
  final bool isShared;   // Pour les rapports de scouts

  // ── Timestamps ──────────────────────────────────────────
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ExpertRatingModel({
    required this.id,
    required this.expertId,
    required this.athleteId,
    this.institutionId,
    this.reportType = ReportType.expert,
    required this.techniqueScore,
    required this.physicalScore,
    required this.mentalScore,
    required this.statsScore,
    required this.potentialScore,
    required this.globalScore,
    this.comment,
    this.recommendation,
    this.tags = const [],
    this.sportId,
    this.context,
    this.matchDate,
    this.isPublic = true,
    this.isShared = false,
    required this.createdAt,
    this.updatedAt,
  });

  // ══════════════════════════════════════════════════════════
  // SERIALIZATION
  // ══════════════════════════════════════════════════════════

  /// Crée un `ExpertRatingModel` depuis un JSON Supabase.
  factory ExpertRatingModel.fromJson(Map<String, dynamic> json) {
    final technique = (json['technique_score'] as num?)?.toDouble() ?? 0.0;
    final physical  = (json['physical_score'] as num?)?.toDouble() ?? 0.0;
    final mental    = (json['mental_score'] as num?)?.toDouble() ?? 0.0;
    final stats     = (json['stats_score'] as num?)?.toDouble() ?? 0.0;
    final potential = (json['potential_score'] as num?)?.toDouble() ?? 0.0;

    // Si le score global n'est pas fourni, on le calcule.
    final globalFromJson = (json['global_score'] as num?)?.toDouble();
    final computedGlobal = globalFromJson ??
        ExpertRatingModel.computeGlobalScore(
          technique: technique,
          physical: physical,
          mental: mental,
          stats: stats,
          potential: potential,
        );

    return ExpertRatingModel(
      id:              json['id'] as String,
      expertId:        json['expert_id'] as String,
      athleteId:       json['athlete_id'] as String,
      institutionId:   json['institution_id'] as String?,
      reportType:      ReportType.fromSlug(
                         json['report_type'] as String? ?? 'expert'
                       ) ?? ReportType.expert,
      techniqueScore:  technique,
      physicalScore:   physical,
      mentalScore:     mental,
      statsScore:      stats,
      potentialScore:  potential,
      globalScore:     computedGlobal,
      comment:         json['comment'] as String?,
      recommendation:  json['recommendation'] as String?,
      tags:            (json['tags'] as List<dynamic>?)
                         ?.map((e) => e as String)
                         .toList() ?? const [],
      sportId:         json['sport_id'] as int?,
      context:         json['context'] as String?,
      matchDate:       json['match_date'] != null
                         ? DateTime.tryParse(json['match_date'] as String)
                         : null,
      isPublic:        json['is_public'] as bool? ?? true,
      isShared:        json['is_shared'] as bool? ?? false,
      createdAt:       DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt:       json['updated_at'] != null
                         ? DateTime.tryParse(json['updated_at'] as String)
                         : null,
    );
  }

  /// Convertit le modèle en JSON pour Supabase.
  Map<String, dynamic> toJson() {
    return {
      'expert_id':        expertId,
      'athlete_id':       athleteId,
      'institution_id':   institutionId,
      'report_type':      reportType.slug,
      'technique_score':  techniqueScore,
      'physical_score':   physicalScore,
      'mental_score':     mentalScore,
      'stats_score':      statsScore,
      'potential_score':  potentialScore,
      'global_score':     globalScore,
      'comment':          comment,
      'recommendation':   recommendation,
      'tags':             tags,
      'sport_id':         sportId,
      'context':          context,
      'match_date':       matchDate?.toIso8601String().split('T').first,
      'is_public':        isPublic,
      'is_shared':        isShared,
    };
  }

  // ══════════════════════════════════════════════════════════
  // COMPUTE GLOBAL SCORE
  // ══════════════════════════════════════════════════════════

  /// Calcule le score global pondéré à partir des 5 critères.
  ///
  /// Pondérations (total = 1.0) :
  /// - Technique : 30%
  /// - Physique : 25%
  /// - Mental : 20%
  /// - Statistiques : 15%
  /// - Potentiel : 10%
  static double computeGlobalScore({
    required double technique,
    required double physical,
    required double mental,
    required double stats,
    required double potential,
  }) {
    final score = (technique * 0.30) +
                  (physical * 0.25) +
                  (mental * 0.20) +
                  (stats * 0.15) +
                  (potential * 0.10);
    return double.parse(score.toStringAsFixed(1));
  }

  // ══════════════════════════════════════════════════════════
  // COPY WITH
  // ══════════════════════════════════════════════════════════

  ExpertRatingModel copyWith({
    String? id,
    String? expertId,
    String? athleteId,
    String? institutionId,
    ReportType? reportType,
    double? techniqueScore,
    double? physicalScore,
    double? mentalScore,
    double? statsScore,
    double? potentialScore,
    double? globalScore,
    String? comment,
    String? recommendation,
    List<String>? tags,
    int? sportId,
    String? context,
    DateTime? matchDate,
    bool? isPublic,
    bool? isShared,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearInstitution = false,
    bool clearComment = false,
    bool clearRecommendation = false,
    bool clearContext = false,
    bool clearMatchDate = false,
    bool clearSportId = false,
  }) {
    return ExpertRatingModel(
      id:              id ?? this.id,
      expertId:        expertId ?? this.expertId,
      athleteId:       athleteId ?? this.athleteId,
      institutionId:   clearInstitution ? null : (institutionId ?? this.institutionId),
      reportType:      reportType ?? this.reportType,
      techniqueScore:  techniqueScore ?? this.techniqueScore,
      physicalScore:   physicalScore ?? this.physicalScore,
      mentalScore:     mentalScore ?? this.mentalScore,
      statsScore:      statsScore ?? this.statsScore,
      potentialScore:  potentialScore ?? this.potentialScore,
      globalScore:     globalScore ?? this.globalScore,
      comment:         clearComment ? null : (comment ?? this.comment),
      recommendation:  clearRecommendation ? null : (recommendation ?? this.recommendation),
      tags:            tags ?? this.tags,
      sportId:         clearSportId ? null : (sportId ?? this.sportId),
      context:         clearContext ? null : (context ?? this.context),
      matchDate:       clearMatchDate ? null : (matchDate ?? this.matchDate),
      isPublic:        isPublic ?? this.isPublic,
      isShared:        isShared ?? this.isShared,
      createdAt:       createdAt ?? this.createdAt,
      updatedAt:       updatedAt ?? this.updatedAt,
    );
  }

  // ══════════════════════════════════════════════════════════
  // GETTERS : Type de rapport
  // ══════════════════════════════════════════════════════════

  /// Vrai si c'est une évaluation d'expert.
  bool get isExpertRating => reportType == ReportType.expert;

  /// Vrai si c'est un rapport de scouting.
  bool get isScoutReport => reportType == ReportType.scout;

  /// Label français du type de rapport.
  String get reportTypeLabel => reportType.labelFr;

  /// Emoji du type de rapport.
  String get reportTypeEmoji => reportType.emoji;

  // ══════════════════════════════════════════════════════════
  // GETTERS : Scores
  // ══════════════════════════════════════════════════════════

  /// Note moyenne des 5 critères.
  double get averageScore {
    final sum = techniqueScore +
                physicalScore +
                mentalScore +
                statsScore +
                potentialScore;
    return double.parse((sum / 5).toStringAsFixed(1));
  }

  /// Meilleur critère (nom + score).
  MapEntry<String, double> get bestCriterion {
    final criteria = {
      'Technique': techniqueScore,
      'Physique': physicalScore,
      'Mental': mentalScore,
      'Statistiques': statsScore,
      'Potentiel': potentialScore,
    };
    return criteria.entries.reduce((a, b) => a.value >= b.value ? a : b);
  }

  /// Critère le plus faible (nom + score).
  MapEntry<String, double> get weakestCriterion {
    final criteria = {
      'Technique': techniqueScore,
      'Physique': physicalScore,
      'Mental': mentalScore,
      'Statistiques': statsScore,
      'Potentiel': potentialScore,
    };
    return criteria.entries.reduce((a, b) => a.value <= b.value ? a : b);
  }

  /// Vrai si tous les critères sont remplis (> 0).
  bool get isComplete =>
      techniqueScore > 0 &&
      physicalScore > 0 &&
      mentalScore > 0 &&
      statsScore > 0 &&
      potentialScore > 0;

  // ══════════════════════════════════════════════════════════
  // GETTERS : Recommandation (scouts uniquement)
  // ══════════════════════════════════════════════════════════

  /// Vrai si le recruteur recommande de recruter.
  bool get isPositive => recommendation == 'sign';

  /// Vrai si le recruteur veut surveiller.
  bool get isWatch => recommendation == 'watch';

  /// Vrai si le recruteur rejette.
  bool get isNegative => recommendation == 'pass';

  /// Label français de la recommandation.
  String get recommendationLabel {
    switch (recommendation) {
      case 'sign':
        return 'À recruter';
      case 'watch':
        return 'À surveiller';
      case 'pass':
        return 'Ne pas donner suite';
      default:
        return 'Non spécifié';
    }
  }

  /// Emoji de la recommandation.
  String get recommendationEmoji {
    switch (recommendation) {
      case 'sign':
        return '✅';
      case 'watch':
        return '👀';
      case 'pass':
        return '❌';
      default:
        return '⚪';
    }
  }

  // ══════════════════════════════════════════════════════════
  // GETTERS : Divers
  // ══════════════════════════════════════════════════════════

  /// Vrai si le rapport a un commentaire.
  bool get hasComment => comment != null && comment!.isNotEmpty;

  /// Vrai si le rapport a des tags.
  bool get hasTags => tags.isNotEmpty;

  /// Vrai si le rapport a une recommandation (scouts uniquement).
  bool get hasRecommendation =>
      recommendation != null && recommendation!.isNotEmpty;

  /// Retourne les tags sous forme de chaîne (ex: '#rapide #technique').
  String get tagsLabel => tags.map((t) => '#$t').join(' ');

  /// Sport associé (si `sportId` défini).
  SportType? get sport {
    if (sportId == null) return null;
    return SportType.fromId(sportId!);
  }

  /// Nom français du sport.
  String? get sportName => sport?.nameFr;

  /// Emoji du sport.
  String? get sportEmoji => sport?.emoji;

  // ══════════════════════════════════════════════════════════
  // MÉTHODES STATIQUES
  // ══════════════════════════════════════════════════════════

  /// Crée un rapport vide (utile pour les formulaires).
  static ExpertRatingModel empty({
    required String expertId,
    required String athleteId,
    ReportType type = ReportType.expert,
    String? institutionId,
  }) {
    return ExpertRatingModel(
      id:              '',
      expertId:        expertId,
      athleteId:       athleteId,
      institutionId:   institutionId,
      reportType:      type,
      techniqueScore:  0,
      physicalScore:   0,
      mentalScore:     0,
      statsScore:      0,
      potentialScore:  0,
      globalScore:     0,
      createdAt:       DateTime.now(),
    );
  }

  // ══════════════════════════════════════════════════════════
  // OVERRIDES
  // ══════════════════════════════════════════════════════════

  @override
  String toString() {
    return 'ExpertRatingModel(id: $id, type: ${reportType.slug}, '
           'athlete: $athleteId, global: $globalScore)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpertRatingModel &&
        other.id == id &&
        other.expertId == expertId &&
        other.athleteId == athleteId &&
        other.reportType == reportType &&
        other.globalScore == globalScore;
  }

  @override
  int get hashCode {
    return Object.hash(id, expertId, athleteId, reportType, globalScore);
  }
}

// ══════════════════════════════════════════════════════════════
// CRITÈRES DE NOTATION (pour formulaires)
// ══════════════════════════════════════════════════════════════

/// Décrit un critère de notation.
class RatingCriterion {
  final String key;
  final String labelFr;
  final String description;
  final double weight;

  const RatingCriterion({
    required this.key,
    required this.labelFr,
    required this.description,
    required this.weight,
  });

  int get weightPercent => (weight * 100).round();
}

/// Les 5 critères de notation disponibles.
const List<RatingCriterion> kRatingCriteria = [
  RatingCriterion(
    key: 'technique',
    labelFr: 'Technique',
    description: 'Contrôle, passe, dribble, finition',
    weight: 0.30,
  ),
  RatingCriterion(
    key: 'physical',
    labelFr: 'Physique',
    description: 'Vitesse, endurance, force, agilité',
    weight: 0.25,
  ),
  RatingCriterion(
    key: 'mental',
    labelFr: 'Mental / Attitude',
    description: 'Leadership, discipline, réaction à la pression',
    weight: 0.20,
  ),
  RatingCriterion(
    key: 'stats',
    labelFr: 'Statistiques',
    description: 'Performances mesurables (buts, passes, victoires)',
    weight: 0.15,
  ),
  RatingCriterion(
    key: 'potential',
    labelFr: 'Potentiel',
    description: 'Marge de progression, âge, attitude',
    weight: 0.10,
  ),
];

/// Pondérations utilisées pour le calcul du score global.
const Map<String, double> kRatingCriteriaWeights = {
  'technique': 0.30,
  'physical':  0.25,
  'mental':    0.20,
  'stats':     0.15,
  'potential': 0.10,
};