// lib/data/models/institution_model.dart
//
// Modèle de données pour les institutions DeNoTa.
// Correspond au schéma Supabase réel (table `institutions`).
//
// Schéma Supabase :
//   id, profile_id, institution_type, official_name, name,
//   registration_number, founded_year, sport_ids, max_athletes,
//   address, city, country, website_url, email, phone,
//   logo_url, description, is_verified, status,
//   total_athletes, champions_count, created_at, updated_at

import '../../core/constants/sports.dart';

/// Modèle représentant une institution (club, académie, fédération, agent, sponsor).
class InstitutionModel {
  // ── Identifiants ────────────────────────────────────────
  final String id;
  final String? profileId;

  // ── Type & Noms ─────────────────────────────────────────
  final InstitutionType type;
  final String officialName;   // Nom officiel complet (obligatoire)
  final String? name;          // Nom court pour l'UI (optionnel)
  final String? registrationNumber;

  // ── Détails ─────────────────────────────────────────────
  final String? logoUrl;
  final String? description;
  final int? foundedYear;

  // ── Contact & Localisation ──────────────────────────────
  final String? websiteUrl;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String country;

  // ── Sports ──────────────────────────────────────────────
  final List<int> sportIds;

  // ── Statistiques ────────────────────────────────────────
  final int? maxAthletes;         // Capacité maximale
  final int totalAthletes;        // Nombre actuel d'athlètes
  final int championsCount;       // Champions formés

  // ── Vérification & Statut ───────────────────────────────
  final bool isVerified;
  final String status;  // 'pending', 'active', 'suspended'

  // ── Timestamps ──────────────────────────────────────────
  final DateTime createdAt;
  final DateTime? updatedAt;

  const InstitutionModel({
    required this.id,
    this.profileId,
    required this.type,
    required this.officialName,
    this.name,
    this.registrationNumber,
    this.logoUrl,
    this.description,
    this.foundedYear,
    this.websiteUrl,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.country = 'CI',
    this.sportIds = const [],
    this.maxAthletes,
    this.totalAthletes = 0,
    this.championsCount = 0,
    this.isVerified = false,
    this.status = 'pending',
    required this.createdAt,
    this.updatedAt,
  });

  // ══════════════════════════════════════════════════════════
  // SERIALIZATION
  // ══════════════════════════════════════════════════════════

  /// Crée un `InstitutionModel` depuis un JSON Supabase.
  factory InstitutionModel.fromJson(Map<String, dynamic> json) {
    return InstitutionModel(
      id:                 json['id'] as String,
      profileId:          json['profile_id'] as String?,
      type:               InstitutionType.fromSlug(
                            json['institution_type'] as String? ?? 'club'
                          ) ?? InstitutionType.club,
      officialName:       json['official_name'] as String? ?? '',
      name:               json['name'] as String?,
      registrationNumber: json['registration_number'] as String?,
      logoUrl:            json['logo_url'] as String?,
      description:        json['description'] as String?,
      foundedYear:        json['founded_year'] as int?,
      websiteUrl:         json['website_url'] as String?,
      email:              json['email'] as String?,
      phone:              json['phone'] as String?,
      address:            json['address'] as String?,
      city:               json['city'] as String?,
      country:            json['country'] as String? ?? 'CI',
      sportIds:           (json['sport_ids'] as List<dynamic>?)
                            ?.map((e) => e as int)
                            .toList() ?? const [],
      maxAthletes:        json['max_athletes'] as int?,
      totalAthletes:      json['total_athletes'] as int? ?? 0,
      championsCount:     json['champions_count'] as int? ?? 0,
      isVerified:         json['is_verified'] as bool? ?? false,
      status:             json['status'] as String? ?? 'pending',
      createdAt:          DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt:          json['updated_at'] != null
                            ? DateTime.tryParse(json['updated_at'] as String)
                            : null,
    );
  }

  /// Convertit le modèle en JSON pour Supabase.
  Map<String, dynamic> toJson() {
    return {
      'profile_id':          profileId,
      'institution_type':    type.slug,
      'official_name':       officialName,
      'name':                name,
      'registration_number': registrationNumber,
      'logo_url':            logoUrl,
      'description':         description,
      'founded_year':        foundedYear,
      'website_url':         websiteUrl,
      'email':               email,
      'phone':               phone,
      'address':             address,
      'city':                city,
      'country':             country,
      'sport_ids':           sportIds,
      'max_athletes':        maxAthletes,
      'is_verified':         isVerified,
      'status':              status,
    };
  }

  // ══════════════════════════════════════════════════════════
  // COPY WITH
  // ══════════════════════════════════════════════════════════

  InstitutionModel copyWith({
    String? id,
    String? profileId,
    InstitutionType? type,
    String? officialName,
    String? name,
    String? registrationNumber,
    String? logoUrl,
    String? description,
    int? foundedYear,
    String? websiteUrl,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? country,
    List<int>? sportIds,
    int? maxAthletes,
    int? totalAthletes,
    int? championsCount,
    bool? isVerified,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearName = false,
    bool clearLogo = false,
    bool clearDescription = false,
    bool clearWebsite = false,
    bool clearEmail = false,
    bool clearPhone = false,
    bool clearAddress = false,
    bool clearCity = false,
    bool clearFoundedYear = false,
  }) {
    return InstitutionModel(
      id:                 id ?? this.id,
      profileId:          profileId ?? this.profileId,
      type:               type ?? this.type,
      officialName:       officialName ?? this.officialName,
      name:               clearName ? null : (name ?? this.name),
      registrationNumber: registrationNumber ?? this.registrationNumber,
      logoUrl:            clearLogo ? null : (logoUrl ?? this.logoUrl),
      description:        clearDescription ? null : (description ?? this.description),
      foundedYear:        clearFoundedYear ? null : (foundedYear ?? this.foundedYear),
      websiteUrl:         clearWebsite ? null : (websiteUrl ?? this.websiteUrl),
      email:              clearEmail ? null : (email ?? this.email),
      phone:              clearPhone ? null : (phone ?? this.phone),
      address:            clearAddress ? null : (address ?? this.address),
      city:               clearCity ? null : (city ?? this.city),
      country:            country ?? this.country,
      sportIds:           sportIds ?? this.sportIds,
      maxAthletes:        maxAthletes ?? this.maxAthletes,
      totalAthletes:      totalAthletes ?? this.totalAthletes,
      championsCount:     championsCount ?? this.championsCount,
      isVerified:         isVerified ?? this.isVerified,
      status:             status ?? this.status,
      createdAt:          createdAt ?? this.createdAt,
      updatedAt:          updatedAt ?? this.updatedAt,
    );
  }

  // ══════════════════════════════════════════════════════════
  // GETTERS UTILES
  // ══════════════════════════════════════════════════════════

  /// Nom d'affichage : utilise `name` si présent, sinon `officialName`.
  String get displayName => name ?? officialName;

  /// Label français du type d'institution.
  String get typeLabel => type.labelFr;

  /// Emoji du type d'institution.
  String get typeEmoji => type.emoji;

  /// Vrai si l'institution est active.
  bool get isActive => status == 'active';

  /// Vrai si l'institution est en attente de vérification.
  bool get isPending => status == 'pending';

  /// Vrai si l'institution est suspendue.
  bool get isSuspended => status == 'suspended';

  /// Vrai si l'institution est à capacité maximale.
  bool get isFull {
    if (maxAthletes == null) return false;
    return totalAthletes >= maxAthletes!;
  }

  /// Places restantes disponibles.
  int get availableSpots {
    if (maxAthletes == null) return -1; // Illimité
    return (maxAthletes! - totalAthletes).clamp(0, maxAthletes!);
  }

  /// Liste des objets `SportType`.
  List<SportType> get sports {
    return sportIds
        .map((id) => SportType.fromId(id))
        .whereType<SportType>()
        .toList();
  }

  /// Liste des noms français des sports (ex: ['Football', 'Basketball']).
  List<String> get sportNames => sports.map((s) => s.nameFr).toList();

  /// Liste des emojis des sports (ex: ['⚽', '🏀']).
  List<String> get sportEmojis => sports.map((s) => s.emoji).toList();

  /// Chaîne avec les emojis joints (ex: '⚽ 🏀').
  String get sportEmojisLabel => sportEmojis.join(' ');

  /// Label français du statut.
  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Active';
      case 'pending':
        return 'En attente';
      case 'suspended':
        return 'Suspendue';
      default:
        return status;
    }
  }

  /// Description courte pour l'UI.
  String get shortDescription {
    final parts = <String>[];
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (foundedYear != null) parts.add('Fondé en $foundedYear');
    if (totalAthletes > 0) {
      parts.add('$totalAthletes athlète${totalAthletes > 1 ? "s" : ""}');
    }
    return parts.join(' • ');
  }

  // ══════════════════════════════════════════════════════════
  // MÉTHODES
  // ══════════════════════════════════════════════════════════

  /// Vérifie si l'institution couvre un sport donné par son ID.
  bool coversSport(int sportId) => sportIds.contains(sportId);

  /// Vérifie si l'institution couvre un sport donné par son type.
  bool coversSportType(SportType sport) => sportIds.contains(sport.id);

  @override
  String toString() {
    return 'InstitutionModel(id: $id, displayName: $displayName, '
           'type: ${type.slug}, isVerified: $isVerified)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InstitutionModel &&
        other.id == id &&
        other.profileId == profileId &&
        other.type == type &&
        other.officialName == officialName &&
        other.isVerified == isVerified &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(id, profileId, type, officialName, isVerified, status);
  }
}