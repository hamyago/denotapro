// lib/data/models/affiliation_model.dart
//
// Modèle de données pour les affiliations athlète ↔ institution.
// Correspond au schéma Supabase réel (table `athlete_institutions`).
//
// Une affiliation lie un athlète à un club, une académie ou une fédération
// sur une période donnée, avec un rôle spécifique.
//
// Schéma Supabase :
//   id, athlete_id, institution_id, joined_at, left_at,
//   is_current, role_in_club, created_at, updated_at

//import '../../core/constants/sports.dart';

// ══════════════════════════════════════════════════════════════
// ENUM : Rôle dans l'institution
// ══════════════════════════════════════════════════════════════

enum AffiliationRole {
  player(
    slug: 'player',
    labelFr: 'Joueur',
    emoji: '🏃',
    description: 'Athlète jouant dans cette institution',
  ),
  trainee(
    slug: 'trainee',
    labelFr: 'Stagiaire',
    emoji: '📚',
    description: 'Athlète en formation dans cette institution',
  ),
  coach(
    slug: 'coach',
    labelFr: 'Entraîneur',
    emoji: '🎓',
    description: 'Entraîneur de cette institution',
  ),
  staff(
    slug: 'staff',
    labelFr: 'Staff',
    emoji: '👔',
    description: 'Membre du staff technique ou administratif',
  );

  const AffiliationRole({
    required this.slug,
    required this.labelFr,
    required this.emoji,
    required this.description,
  });

  final String slug;
  final String labelFr;
  final String emoji;
  final String description;

  static AffiliationRole? fromSlug(String slug) {
    for (final r in AffiliationRole.values) {
      if (r.slug == slug) return r;
    }
    return null;
  }
}

// ══════════════════════════════════════════════════════════════
// MODÈLE PRINCIPAL
// ══════════════════════════════════════════════════════════════

/// Modèle représentant une affiliation athlète ↔ institution.
class AffiliationModel {
  // ── Identifiants ────────────────────────────────────────
  final String id;
  final String athleteId;
  final String institutionId;

  // ── Détails de l'affiliation ────────────────────────────
  final AffiliationRole role;
  final DateTime? joinedAt;   // Date d'arrivée
  final DateTime? leftAt;     // Date de départ (null si actuel)
  final bool isCurrent;       // Vrai si l'affiliation est active

  // ── Timestamps ──────────────────────────────────────────
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AffiliationModel({
    required this.id,
    required this.athleteId,
    required this.institutionId,
    this.role = AffiliationRole.player,
    this.joinedAt,
    this.leftAt,
    this.isCurrent = true,
    required this.createdAt,
    this.updatedAt,
  });

  // ══════════════════════════════════════════════════════════
  // SERIALIZATION
  // ══════════════════════════════════════════════════════════

  /// Crée un `AffiliationModel` depuis un JSON Supabase.
  factory AffiliationModel.fromJson(Map<String, dynamic> json) {
    return AffiliationModel(
      id:            json['id'] as String,
      athleteId:     json['athlete_id'] as String? ?? '',
      institutionId: json['institution_id'] as String? ?? '',
      role:          AffiliationRole.fromSlug(
                       json['role_in_club'] as String? ?? 'player'
                     ) ?? AffiliationRole.player,
      joinedAt:      json['joined_at'] != null
                       ? DateTime.tryParse(json['joined_at'] as String)
                       : null,
      leftAt:        json['left_at'] != null
                       ? DateTime.tryParse(json['left_at'] as String)
                       : null,
      isCurrent:     json['is_current'] as bool? ?? true,
      createdAt:     DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt:     json['updated_at'] != null
                       ? DateTime.tryParse(json['updated_at'] as String)
                       : null,
    );
  }

  /// Convertit le modèle en JSON pour Supabase.
  Map<String, dynamic> toJson() {
    return {
      'athlete_id':     athleteId,
      'institution_id': institutionId,
      'role_in_club':   role.slug,
      'joined_at':      joinedAt?.toIso8601String().split('T').first,
      'left_at':        leftAt?.toIso8601String().split('T').first,
      'is_current':     isCurrent,
    };
  }

  // ══════════════════════════════════════════════════════════
  // COPY WITH
  // ══════════════════════════════════════════════════════════

  AffiliationModel copyWith({
    String? id,
    String? athleteId,
    String? institutionId,
    AffiliationRole? role,
    DateTime? joinedAt,
    DateTime? leftAt,
    bool? isCurrent,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearJoinedAt = false,
    bool clearLeftAt = false,
  }) {
    return AffiliationModel(
      id:            id ?? this.id,
      athleteId:     athleteId ?? this.athleteId,
      institutionId: institutionId ?? this.institutionId,
      role:          role ?? this.role,
      joinedAt:      clearJoinedAt ? null : (joinedAt ?? this.joinedAt),
      leftAt:        clearLeftAt ? null : (leftAt ?? this.leftAt),
      isCurrent:     isCurrent ?? this.isCurrent,
      createdAt:     createdAt ?? this.createdAt,
      updatedAt:     updatedAt ?? this.updatedAt,
    );
  }

  // ══════════════════════════════════════════════════════════
  // GETTERS : Statut
  // ══════════════════════════════════════════════════════════

  /// Vrai si l'affiliation est en cours (pas terminée).
  bool get isActive => isCurrent && leftAt == null;

  /// Vrai si l'affiliation est terminée.
  bool get isEnded => !isCurrent || leftAt != null;

  /// Vrai si c'est la première affiliation (pas de date d'arrivée).
  bool get hasNoJoinDate => joinedAt == null;

  // ══════════════════════════════════════════════════════════
  // GETTERS : Durée
  // ══════════════════════════════════════════════════════════

  /// Durée de l'affiliation en mois.
  ///
  /// - Si terminée : entre joinedAt et leftAt
  /// - Si active : entre joinedAt et aujourd'hui
  /// - Retourne 0 si aucune date
  int get durationMonths {
    if (joinedAt == null) return 0;

    final end = leftAt ?? DateTime.now();
    final months = (end.year - joinedAt!.year) * 12 +
                   (end.month - joinedAt!.month);
    return months < 0 ? 0 : months;
  }

  /// Durée en années (arrondi à 1 décimale).
  double get durationYears {
    return double.parse((durationMonths / 12).toStringAsFixed(1));
  }

  /// Nombre de jours depuis l'arrivée.
  int get daysSinceJoin {
    if (joinedAt == null) return 0;
    return DateTime.now().difference(joinedAt!).inDays;
  }

  // ══════════════════════════════════════════════════════════
  // GETTERS : Affichage
  // ══════════════════════════════════════════════════════════

  /// Label français du rôle.
  String get roleLabel => role.labelFr;

  /// Emoji du rôle.
  String get roleEmoji => role.emoji;

  /// Label complet du rôle avec emoji (ex: '🏃 Joueur').
  String get roleWithEmoji => '${role.emoji} ${role.labelFr}';

  /// Label de la durée sous forme lisible.
  /// Ex: '2 ans', '6 mois', '3 ans et 5 mois', 'Nouveau'
  String get durationLabel {
    if (joinedAt == null) return 'Date non spécifiée';

    final months = durationMonths;
    if (months < 1) {
      final days = daysSinceJoin;
      if (days < 7) return 'Nouveau';
      if (days < 30) return '$days jour${days > 1 ? "s" : ""}';
      return '1 mois';
    }
    if (months < 12) return '$months mois';

    final years = months ~/ 12;
    final remainingMonths = months % 12;

    if (remainingMonths == 0) {
      return '$years an${years > 1 ? "s" : ""}';
    }
    return '$years an${years > 1 ? "s" : ""} et $remainingMonths mois';
  }

  /// Période complète sous forme lisible.
  /// Ex: 'Depuis janvier 2024' ou 'De 2020 à 2023'
  String get periodLabel {
    if (joinedAt == null) return 'Période non spécifiée';

    final start = _formatMonthYear(joinedAt!);

    if (isActive || leftAt == null) {
      return 'Depuis $start';
    }
    final end = _formatMonthYear(leftAt!);
    return 'De $start à $end';
  }

  /// Statut de l'affiliation sous forme de label.
  String get statusLabel {
    if (isActive) return 'En cours';
    return 'Terminée';
  }

  /// Emoji du statut.
  String get statusEmoji {
    if (isActive) return '🟢';
    return '⚪';
  }

  // ══════════════════════════════════════════════════════════
  // MÉTHODES
  // ══════════════════════════════════════════════════════════

  /// Vrai si l'affiliation concerne une institution donnée.
  bool isAtInstitution(String instId) => institutionId == instId;

  /// Vrai si le rôle est 'player'.
  bool get isPlayer => role == AffiliationRole.player;

  /// Vrai si le rôle est 'coach'.
  bool get isCoach => role == AffiliationRole.coach;

  /// Vrai si le rôle est 'trainee'.
  bool get isTrainee => role == AffiliationRole.trainee;

  /// Vrai si le rôle est 'staff'.
  bool get isStaff => role == AffiliationRole.staff;

  /// Vrai si l'affiliation a duré plus longtemps que [months] mois.
  bool isLongerThan(int months) => durationMonths > months;

  /// Termine l'affiliation (retourne une nouvelle instance).
  AffiliationModel end({DateTime? leaveDate}) {
    return copyWith(
      leftAt: leaveDate ?? DateTime.now(),
      isCurrent: false,
    );
  }

  // ══════════════════════════════════════════════════════════
  // HELPERS PRIVÉS
  // ══════════════════════════════════════════════════════════

  String _formatMonthYear(DateTime d) {
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  // ══════════════════════════════════════════════════════════
  // OVERRIDES
  // ══════════════════════════════════════════════════════════

  @override
  String toString() {
    return 'AffiliationModel(id: $id, athlete: $athleteId, '
           'institution: $institutionId, role: ${role.slug}, '
           'isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AffiliationModel &&
        other.id == id &&
        other.athleteId == athleteId &&
        other.institutionId == institutionId &&
        other.role == role &&
        other.isCurrent == isCurrent;
  }

  @override
  int get hashCode {
    return Object.hash(id, athleteId, institutionId, role, isCurrent);
  }
}