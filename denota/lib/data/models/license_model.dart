// lib/data/models/license_model.dart
//
// Modèle de données pour les licences fédérales des athlètes.
// Correspond au schéma Supabase réel (table `licenses`).
//
// Une licence est délivrée par une fédération sportive (FIF, FIBB, FIA, FITKD, etc.)
// et atteste qu'un athlète est officiellement enregistré pour pratiquer son sport.
//
// Schéma Supabase :
//   id, athlete_id, federation_name, license_number,
//   sport_id, category, valid_from, valid_until,
//   is_active, created_at, updated_at

import '../../core/constants/sports.dart';

/// Modèle représentant une licence fédérale d'un athlète.
class LicenseModel {
  // ── Identifiants ────────────────────────────────────────
  final String id;
  final String athleteId;

  // ── Informations de licence ─────────────────────────────
  final String federationName;   // 'FIF', 'FIBB', 'FIA', 'FITKD', etc.
  final String licenseNumber;    // Numéro unique de licence
  final int? sportId;            // Sport concerné
  final String? category;        // 'U15', 'U18', 'U21', 'Senior'

  // ── Validité ────────────────────────────────────────────
  final DateTime? validFrom;
  final DateTime? validUntil;
  final bool isActive;

  // ── Timestamps ──────────────────────────────────────────
  final DateTime createdAt;
  final DateTime? updatedAt;

  const LicenseModel({
    required this.id,
    required this.athleteId,
    required this.federationName,
    required this.licenseNumber,
    this.sportId,
    this.category,
    this.validFrom,
    this.validUntil,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  // ══════════════════════════════════════════════════════════
  // SERIALIZATION
  // ══════════════════════════════════════════════════════════

  /// Crée un `LicenseModel` depuis un JSON Supabase.
  factory LicenseModel.fromJson(Map<String, dynamic> json) {
    return LicenseModel(
      id:             json['id'] as String,
      athleteId:      json['athlete_id'] as String,
      federationName: json['federation_name'] as String? ?? '',
      licenseNumber:  json['license_number'] as String? ?? '',
      sportId:        json['sport_id'] as int?,
      category:       json['category'] as String?,
      validFrom:      json['valid_from'] != null
                        ? DateTime.tryParse(json['valid_from'] as String)
                        : null,
      validUntil:     json['valid_until'] != null
                        ? DateTime.tryParse(json['valid_until'] as String)
                        : null,
      isActive:       json['is_active'] as bool? ?? true,
      createdAt:      DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt:      json['updated_at'] != null
                        ? DateTime.tryParse(json['updated_at'] as String)
                        : null,
    );
  }

  /// Convertit le modèle en JSON pour Supabase.
  Map<String, dynamic> toJson() {
    return {
      'athlete_id':      athleteId,
      'federation_name': federationName,
      'license_number':  licenseNumber,
      'sport_id':        sportId,
      'category':        category,
      'valid_from':      validFrom?.toIso8601String().split('T').first,
      'valid_until':     validUntil?.toIso8601String().split('T').first,
      'is_active':       isActive,
    };
  }

  // ══════════════════════════════════════════════════════════
  // COPY WITH
  // ══════════════════════════════════════════════════════════

  LicenseModel copyWith({
    String? id,
    String? athleteId,
    String? federationName,
    String? licenseNumber,
    int? sportId,
    String? category,
    DateTime? validFrom,
    DateTime? validUntil,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearSportId = false,
    bool clearCategory = false,
    bool clearValidFrom = false,
    bool clearValidUntil = false,
  }) {
    return LicenseModel(
      id:             id ?? this.id,
      athleteId:      athleteId ?? this.athleteId,
      federationName: federationName ?? this.federationName,
      licenseNumber:  licenseNumber ?? this.licenseNumber,
      sportId:        clearSportId ? null : (sportId ?? this.sportId),
      category:       clearCategory ? null : (category ?? this.category),
      validFrom:      clearValidFrom ? null : (validFrom ?? this.validFrom),
      validUntil:     clearValidUntil ? null : (validUntil ?? this.validUntil),
      isActive:       isActive ?? this.isActive,
      createdAt:      createdAt ?? this.createdAt,
      updatedAt:      updatedAt ?? this.updatedAt,
    );
  }

  // ══════════════════════════════════════════════════════════
  // GETTERS : Validité
  // ══════════════════════════════════════════════════════════

  /// Vrai si la licence n'a pas encore commencé (validFrom dans le futur).
  bool get isNotYetValid {
    if (validFrom == null) return false;
    return validFrom!.isAfter(DateTime.now());
  }

  /// Vrai si la licence a expiré.
  bool get isExpired {
    if (validUntil == null) return false;
    return validUntil!.isBefore(DateTime.now());
  }

  /// Vrai si la licence est actuellement valide.
  /// = isActive ET pas expirée ET pas encore commencée (ou validFrom null)
  bool get isValid {
    if (!isActive) return false;
    if (isExpired) return false;
    if (isNotYetValid) return false;
    return true;
  }

  /// Vrai si la licence expire bientôt (< 60 jours).
  bool get isExpiringSoon {
    if (validUntil == null) return false;
    final daysLeft = validUntil!.difference(DateTime.now()).inDays;
    return daysLeft > 0 && daysLeft < 60;
  }

  /// Nombre de jours restants avant expiration.
  /// Retourne -1 si la licence est déjà expirée.
  /// Retourne null si la date d'expiration n'est pas définie.
  int? get daysRemaining {
    if (validUntil == null) return null;
    final days = validUntil!.difference(DateTime.now()).inDays;
    return days < 0 ? -1 : days;
  }

  /// Durée totale de validité en jours (entre validFrom et validUntil).
  int? get totalValidityDays {
    if (validFrom == null || validUntil == null) return null;
    return validUntil!.difference(validFrom!).inDays;
  }

  // ══════════════════════════════════════════════════════════
  // GETTERS : Affichage
  // ══════════════════════════════════════════════════════════

  /// Sport associé (si `sportId` défini).
  SportType? get sport {
    if (sportId == null) return null;
    return SportType.fromId(sportId!);
  }

  /// Nom français du sport.
  String? get sportName => sport?.nameFr;

  /// Emoji du sport.
  String? get sportEmoji => sport?.emoji;

  /// Label de la fédération avec emoji sport (ex: '⚽ FIF').
  String get federationWithSport {
    if (sportEmoji != null) {
      return '$sportEmoji $federationName';
    }
    return federationName;
  }

  /// Statut de la licence sous forme de label.
  String get statusLabel {
    if (!isActive) return 'Inactive';
    if (isExpired) return 'Expirée';
    if (isNotYetValid) return 'Pas encore valide';
    if (isExpiringSoon) return 'Expire bientôt';
    return 'Valide';
  }

  /// Emoji du statut.
  String get statusEmoji {
    if (!isActive) return '⚫';
    if (isExpired) return '🔴';
    if (isNotYetValid) return '🟡';
    if (isExpiringSoon) return '🟠';
    return '🟢';
  }

  /// Retourne une description courte de la période de validité.
  /// Ex: 'Valide du 01/01/2026 au 31/12/2026'
  String get validityPeriodLabel {
    final parts = <String>[];
    if (validFrom != null) {
      parts.add('du ${_formatDate(validFrom!)}');
    }
    if (validUntil != null) {
      parts.add('au ${_formatDate(validUntil!)}');
    }
    if (parts.isEmpty) return 'Période non spécifiée';
    return 'Valide ${parts.join(' ')}';
  }

  /// Affiche le nombre de jours restants sous forme lisible.
  /// Ex: '45 jours restants' ou 'Expirée depuis 10 jours'
  String get remainingLabel {
    final days = daysRemaining;
    if (days == null) return 'Pas de date d\'expiration';
    if (days < 0) {
      return 'Expirée depuis ${-days} jour${-days > 1 ? "s" : ""}';
    }
    if (days == 0) return 'Expire aujourd\'hui';
    return '$days jour${days > 1 ? "s" : ""} restant${days > 1 ? "s" : ""}';
  }

  // ══════════════════════════════════════════════════════════
  // MÉTHODES
  // ══════════════════════════════════════════════════════════

   /// Vérifie si la licence correspond à un sport donné (par ID).
  bool isForSport(int id) => sportId == id;

  /// Vérifie si la licence correspond à un sport donné par type.
  bool isForSportType(SportType sport) => sportId == sport.id;

  /// Vérifie si la licence est dans une catégorie donnée.
  bool isInCategory(String cat) => category == cat;

  /// Retourne le statut sous forme d'entier (pour tri) :
  /// 0 = expirée, 1 = expire bientôt, 2 = valide, 3 = pas encore valide, 4 = inactive
  int get statusPriority {
    if (!isActive) return 4;
    if (isExpired) return 0;
    if (isExpiringSoon) return 1;
    if (isNotYetValid) return 3;
    return 2;
  }

  // ══════════════════════════════════════════════════════════
  // HELPERS PRIVÉS
  // ══════════════════════════════════════════════════════════

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
           '${d.month.toString().padLeft(2, '0')}/'
           '${d.year}';
  }

  // ══════════════════════════════════════════════════════════
  // OVERRIDES
  // ══════════════════════════════════════════════════════════

  @override
  String toString() {
    return 'LicenseModel(id: $id, federation: $federationName, '
           'number: $licenseNumber, valid: $isValid)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LicenseModel &&
        other.id == id &&
        other.athleteId == athleteId &&
        other.federationName == federationName &&
        other.licenseNumber == licenseNumber;
  }

  @override
  int get hashCode {
    return Object.hash(id, athleteId, federationName, licenseNumber);
  }
}

// ══════════════════════════════════════════════════════════════
// FÉDÉRATIONS IVOIRIENNES CONNUES
// ══════════════════════════════════════════════════════════════

/// Liste des fédérations sportives ivoiriennes connues.
/// Utilisée pour les listes déroulantes dans les formulaires.
const List<Federation> kKnownFederations = [
  // ── Football ────────────────────────────────────────────
  Federation(
    code: 'FIF',
    nameFr: 'Fédération Ivoirienne de Football',
    sportSlug: 'football',
    emoji: '⚽',
  ),
  // ── Basketball ──────────────────────────────────────────
  Federation(
    code: 'FIBB',
    nameFr: 'Fédération Ivoirienne de Basketball',
    sportSlug: 'basketball',
    emoji: '🏀',
  ),
  // ── Athlétisme ──────────────────────────────────────────
  Federation(
    code: 'FIA',
    nameFr: 'Fédération Ivoirienne d\'Athlétisme',
    sportSlug: 'athletics',
    emoji: '🏃',
  ),
  // ── Taekwondo ───────────────────────────────────────────
  Federation(
    code: 'FITKD',
    nameFr: 'Fédération Ivoirienne de Taekwondo',
    sportSlug: 'taekwondo',
    emoji: '🥋',
  ),
];

/// Représente une fédération sportive.
class Federation {
  final String code;        // 'FIF', 'FIBB', etc.
  final String nameFr;      // Nom complet
  final String sportSlug;   // Slug du sport
  final String emoji;       // Emoji du sport

  const Federation({
    required this.code,
    required this.nameFr,
    required this.sportSlug,
    required this.emoji,
  });

  /// Retourne le SportType associé.
  SportType? get sport => SportType.fromSlug(sportSlug);

  /// Label court avec emoji (ex: '⚽ FIF').
  String get shortLabel => '$emoji $code';

  /// Label complet (ex: 'FIF — Fédération Ivoirienne de Football').
  String get fullLabel => '$code — $nameFr';
}