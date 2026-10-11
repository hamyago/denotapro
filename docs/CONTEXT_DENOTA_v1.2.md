# 📄 DOCUMENT DE CONTEXTE — PROJET DeNoTa
**Version** : 1.2
**Date** : Juillet 2026
**Statut** : Validé — À exécuter
**Mise à jour** : Intégration SIGS/JTS + Partenariat Ministère

---

## 1. VISION DU PRODUIT

### 1.1. Mission
**DeNoTa** (Détection de Nouveaux Talents) est la **vitrine digitale des talents sportifs ivoiriens**, connectée aux décideurs du sport (clubs, académies, agents, fédérations).

### 1.2. Problème résolu
- Des milliers de jeunes talents en Côte d'Ivoire n'ont **aucune visibilité** auprès des recruteurs.
- Les clubs et agents **manquent d'outils** pour détecter des profils hors de leurs réseaux habituels.
- Les fédérations n'ont **pas de cartographie** des talents sur le territoire.
- Les jeunes talents n'osent pas **se montrer en public**.

### 1.3. Solution
Une plateforme mobile et web qui permet :
1. Aux **talents** de créer un profil sportif vérifié avec vidéos, stats et palmarès.
2. Aux **clubs, agents et fédérations** de découvrir, filtrer et contacter les talents.
3. Aux **experts** de noter les talents via un Talent Score™.
4. Aux **sponsors** de trouver des ambassadeurs.

### 1.4. Ce que DeNoTa n'est PAS
- ❌ Un réseau social généraliste
- ❌ Un site d'actualités sportives
- ❌ Une plateforme de streaming vidéo
- ❌ Un site de paris sportifs

---

## 2. UTILISATEURS CIBLES ET RÔLES

| Rôle | Objectif principal | Fonctionnalités clés |
|------|-------------------|---------------------|
| **Talent (Athlète)** | Être découvert | Profil, vidéos, Talent Score™, stats |
| **Club / Académie** | Recruter | Recherche, filtres, favoris, rapports PDF |
| **Agent** | Détecter | Alertes, favoris, notes privées |
| **Fédération** | Cartographier | Vue globale, stats, export données |
| **Sponsor / Marque** | Ambassadeurs | Recherche par popularité |
| **Expert / Coach** | Noter | Notation multicritères |
| **Admin DeNoTa** | Modérer | Modération, vérification |

---

## 3. SPORTS PILOTES (PHASE 1)

| Sport | Emoji | Justification |
|-------|-------|---------------|
| **Football** | ⚽ | Sport n°1 en Côte d'Ivoire |
| **Basketball** | 🏀 | Croissance rapide, NBA Africa |
| **Athlétisme** | 🏃 | Discipline olympique |
| **Taekwondo** | 🥋 | Arts martiaux populaires |

**Phase 2** : Natation, Handball, Judo, Boxe, Tennis
**Phase 3** : Tous les sports olympiques

---

## 4. POSITIONNEMENT STRATÉGIQUE

### 4.1. Marché
- **Zone pilote** : Côte d'Ivoire
- **Expansion** : Afrique de l'Ouest
- **À terme** : Afrique francophone

### 4.2. Concurrence
Aucun concurrent direct établi en Afrique francophone.

### 4.3. Partenariats clés
- Fédérations sportives ivoiriennes
- Ministère des Sports
- Clubs professionnels
- Académies locales
- Sponsors

---

## 4 bis. ÉCOSYSTÈME MINISTÈRE DES SPORTS

### 4 bis.1. Le Ministère est déjà digitalisé

Le Ministère des Sports a lancé 2 plateformes :

#### SIGS (ms-sigs.org) — Système d'Information et de Gestion du Sport
- **Rôle** : Back-office administratif
- **Fonctions** : Gestion des clubs, fédérations, licences, tableaux de bord
- **Chiffres** : 77+ fédérations, 580+ clubs, 70+ disciplines
- **Statut** : Lancement imminent

#### JTS (jts.ms-sigs.org) — Programme National de Détection des Jeunes Talents Sportifs
- **Rôle** : Détection des talents
- **Public** : Jeunes de 10 à 18 ans
- **Fonctions** : Inscription, tri, regroupements régionaux, API
- **Couverture** : 31 régions, 70+ disciplines
- **Statut** : Actif

### 4 bis.2. Positionnement de DeNoTa

**DeNoTa est complémentaire au JTS, pas concurrent.**

| Critère | JTS | DeNoTa |
|---------|-----|--------|
| Public | 10-18 ans | 15-25 ans |
| Approche | Détection de masse | Détection continue |
| Sports | 70+ | 4 pilotes |
| Fonctions | Inscription, tri | Vidéo, Talent Score™, scout reports |
| Business | Public (gratuit) | Freemium + commissions |
| Couverture | Nationale | Abidjan puis national |
| Technologie | Microservices | Flutter, Supabase |
| Vitesse | Lente | Rapide |

**DeNoTa = le "front-office" digital du JTS.**

### 4 bis.3. Alignement stratégique

1. **Mêmes disciplines pilotes** : Football, Basketball, Athlétisme, Taekwondo
2. **Même terminologie** : "Jeunes Talents Sportifs", "Égalité des chances"
3. **Même objectif** : Révéler les futurs champions ivoiriens
4. **Complémentarité** : DeNoTa apporte l'analyse vidéo et la mise en relation

### 4 bis.4. Opportunités identifiées

| Opportunité | Source | Action |
|-------------|--------|--------|
| Financement | FONTSI (rencontré par le SIGS) | Solliciter via Ministère |
| Infrastructure | ANSUT (rencontré par le SIGS) | Demander hébergement |
| Intégration API | JTS | Proposer une API |
| Données licences | SIGS | Demander accès |
| Couverture nationale | JTS | S'aligner sur 31 régions |

### 4 bis.5. Argumentaire pour le Ministère

> "Le JTS détecte les talents. DeNoTa les révèle au monde.
> 
> Le JTS organise des regroupements ponctuels. DeNoTa offre une vitrine continue.
> 
> Le JTS cible 10-18 ans. DeNoTa accompagne 15-25 ans.
> 
> Ensemble, nous couvrons tout le cycle du talent ivoirien."

### 4 bis.6. Demande révisée

1. **Protocole d'accord** de partenariat technique
2. **Accès API** au SIGS pour les licences
3. **Intégration** avec le JTS
4. **Recommandation** auprès de FONTSI et ANSUT
5. **Communication conjointe** au lancement

### 4 bis.7. Chiffres à reprendre

- 77+ fédérations
- 580+ clubs
- 70+ disciplines
- 31 régions
- 10-18 ans (JTS) → 15-25 ans (DeNoTa)

### 4 bis.8. Actions à mener

| Étape | Action | Échéance |
|-------|--------|----------|
| 1 | Dossier de présentation officiel | Semaine 1 |
| 2 | Audience formelle Cabinet | Semaine 2 |
| 3 | Démo fonctionnelle MVP | Semaine 4 |
| 4 | Négocier protocole d'accord | Semaine 6 |
| 5 | Signature + communication | Semaine 8 |

---

## 5. MODÈLE ÉCONOMIQUE

| Source | Type | Prix |
|--------|------|------|
| Commission recrutement | Principal | 5-10% du 1er salaire |
| Publicité In-App | Principal | Bannières |
| Premium Sportif | Récurrent | 2 000 – 5 000 FCFA/mois |
| Abonnement Institution | Récurrent | 15 000 – 40 000 FCFA/mois |
| Recruteur Pro | Récurrent | 25 000 FCFA/mois |
| Profil Boosté | Ponctuel | Variable |

### Revenus additionnels (avec Ministère)
| Source | Estimation |
|--------|------------|
| Subvention publique (FONTSI) | 5-20 M FCFA |
| Partenariats fédéraux | 2-5 M FCFA/an |
| Formation | 500 K FCFA/session |
| Data analytics | 1-3 M FCFA/an |

---

## 6. ARCHITECTURE TECHNIQUE

### 6.1. Stack
| Couche | Technologie |
|--------|-------------|
| Mobile | Flutter 3.x · Dart · BLoC |
| Backend | Supabase (PostgreSQL, Auth, Storage) |
| Web vitrine | HTML5 · CSS3 · JavaScript |
| IA | Python · MediaPipe · TensorFlow |
| Notifications | Firebase FCM |
| Paiement | Wave · CinetPay · Orange Money |
| Stockage vidéo | Supabase Storage · Cloudflare CDN |
| PDF | Package `pdf` Dart |

### 6.2. Décision : Rester sur Supabase
- ✅ Focus produit
- ✅ Plan gratuit généreux
- ✅ Migration possible en Phase 3
- ✅ Sécurité RLS native
- ✅ Realtime intégré

---

## 7. NOUVELLE ARCHITECTURE DE CODE

### 7.1. Structure des dossiers

```
lib/
├── main.dart
├── core/
│   ├── router/
│   ├── theme/
│   ├── constants/
│   │   ├── sports.dart
│   │   ├── levels.dart
│   │   └── institution_types.dart
│   ├── validators/
│   └── errors/
│
├── data/
│   ├── models/
│   │   ├── profile_model.dart
│   │   ├── athlete_profile_model.dart
│   │   ├── institution_model.dart
│   │   ├── scout_report_model.dart
│   │   └── license_model.dart
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── profile_repository.dart
│   │   ├── talent_repository.dart
│   │   └── institution_repository.dart
│   └── services/
│       ├── video_service.dart
│       ├── payment_service.dart
│       └── scouting_pdf_service.dart
│
├── presentation/
│   ├── screens/
│   │   ├── auth/
│   │   ├── onboarding/
│   │   ├── talent/
│   │   ├── scout/
│   │   ├── institution/
│   │   ├── admin/
│   │   ├── messaging/
│   │   └── shared/
│   └── widgets/
```

### 7.2. Navigation par rôle

**Talent :**
```
[Mon Profil] [Feed] [Notifications] [Messages] [Paramètres]
```

**Club / Agent / Fédération :**
```
[Talents] [Carte] [Favoris] [Messages] [Dashboard]
```

**Admin :**
```
[Dashboard] [Modération] [Utilisateurs] [Stats]
```

---

## 8. NOUVEAUX MODÈLES DE DONNÉES

### 8.1. InstitutionModel
Champs : `id`, `profileId`, `type` (club/academy/federation/agent/sponsor), `name`, `logoUrl`, `sportIds`, `isVerified`, `athleteCount`.

### 8.2. ScoutReportModel
Champs : `id`, `scoutId`, `athleteId`, `institutionId`, `globalScore`, `techniqueScore`, `physicalScore`, `mentalScore`, `potentialScore`, `comment`, `recommendation`, `isShared`.

### 8.3. LicenseModel
Champs : `id`, `athleteId`, `federationName`, `licenseNumber`, `sportId`, `category`, `validFrom`, `validUntil`, `isActive`.

### 8.4. AthleteProfileModel (enrichi)
Ajouts : `licenseNumber`, `federationName`, `highlightUrls`, `matchesPlayed`, `currentStatus`, `lastActiveAt`, `scoutViewsCount`.

---

## 9. BASE DE DONNÉES SUPABASE

### 9.1. Nouvelles tables
- `institutions`
- `affiliations`
- `scout_reports`
- `licenses`

### 9.2. Vues SQL
- `talents_view`
- `institutions_view`

### 9.3. Sécurité RLS
- Talents : accès à leurs propres données
- Institutions vérifiées : accès aux talents publics
- Rapports de scouting : privés sauf si `is_shared`
- Admins : accès total

---

## 10. FONCTIONNALITÉS PAR PHASE

### Phase 0 — Discovery (3 semaines) ✅
- Maquettes Figma
- Architecture technique
- Documentation de contexte

### Phase 1 — MVP Lean (3 mois)
- App Flutter (auth + profils + upload)
- Inscription talent
- Inscription institution
- Filtres avancés
- Carte des talents
- Favoris
- Rapports PDF
- Messagerie
- Modération admin

### Phase 2 — Traction (2 mois)
- 500 profils talents
- 50 clubs abidjanais
- Alertes personnalisées
- Vérification institutions
- Analytics

### Phase 3 — Monétisation (2 mois)
- Premium Sportif
- Abonnement Institution
- Recruteur Pro
- Publicité
- Challenges & tournois

### Phase 4 — Scale
- Levée de fonds
- Expansion nationale
- Expansion Afrique de l'Ouest
- Autres sports
- Live streaming
- API fédérations

---

## 11. CHRONOGRAMME COMMUN

| Étape | Tâche | Durée |
|-------|-------|-------|
| É1 | Créer `constants/sports.dart` | 0.5j |
| É2 | Créer `InstitutionModel` | 1j |
| É3 | Créer `ScoutReportModel` | 1j |
| É4 | Migrations SQL Supabase | 2j |
| É5 | Adapter `home_shell.dart` | 1j |
| É6 | Créer `TalentHomeScreen` | 3j |
| É7 | Créer `ScoutHomeScreen` | 3j |
| É8 | Refondre `register_screen.dart` | 3j |
| É9 | Créer `InstitutionRepository` | 2j |
| É10 | Créer `ScoutReportScreen` | 2j |
| É11 | Refondre `TalentListScreen` | 3j |
| É12 | Système vérification | 3j |
| É13 | Tests d'intégration | 3j |
| É14 | Déploiement Phase 1 | 2j |

**Durée totale** : ~30 jours ouvrés (6 semaines)

---

## 12. RÈGLES DE COLLABORATION

1. Avancer étape par étape
2. Valider chaque étape avant la suivante
3. Documenter les blocages
4. Réévaluer si imprévu

---

## 13. KPI

### Phase pilote
- 500 talents inscrits
- 50 clubs inscrits
- 2 fédérations partenaires
- 5 villes couvertes

### Phase 2
- 5 000 talents
- 200 clubs
- 10 sports
- 20 recrutements

### Phase 3
- 1 000 talents actifs
- 100 clubs
- 500 000 FCFA/mois

---

## 14. RISQUES

| Risque | Mitigation |
|--------|------------|
| Faible adoption clubs | Partenariats Ministère |
| Qualité vidéos | Tutoriels, validation |
| Coût stockage | Compression |
| Concurrence | Avance terrain |
| Fuite données | RLS strict |
| Dépendance Supabase | Architecture découplée |

---

## 15. DÉCISIONS ACTÉES

| Date | Décision |
|------|----------|
| Juil. 2026 | Rester sur Supabase |
| Juil. 2026 | 4 sports pilotes |
| Juil. 2026 | Navigation par rôle |
| Juil. 2026 | Ajout InstitutionModel |
| Juil. 2026 | Ajout ScoutReportModel |
| Juil. 2026 | Vérification institutions |
| Juil. 2026 | Partenariat Ministère |
| Juil. 2026 | Alignement SIGS/JTS |

---

## 16. PROCHAINES ÉTAPES

### Techniques
1. `lib/core/constants/sports.dart`
2. `InstitutionModel`
3. `ScoutReportModel`
4. ...

### Institutionnelles
| Action | Échéance |
|--------|----------|
| Dossier présentation | Semaine 1 |
| Pitch 5 min | Semaine 1 |
| Compte @DeNoTa_CI | Semaine 1 |
| Interlocuteur clé | Semaine 2 |
| Démo | Semaine 3 |
| Audience | Semaine 2 |
| Protocole accord | Semaine 4 |
| Solliciter FONTSI | Semaine 4 |
| Solliciter ANSUT | Semaine 5 |

---

## 17. AVANTAGES CONCURRENTIELS

1. Barrière à l'entrée
2. Accès privilégié
3. Confiance parents
4. Financement facilité
5. Couverture médias
6. Légitimité officielle
7. Alignement SIGS/JTS

---

## 18. VISION À 5 ANS

| Année | Objectif |
|-------|----------|
| 2026 | MVP, 4 sports, 500 talents |
| 2027 | 5 000 talents, 200 clubs |
| 2028 | Expansion Afrique de l'Ouest |
| 2029 | Leader africain francophone |
| 2030 | Expansion anglophone |

---

**Document validé — Version 1.2**
**Fondateur** : Hamyago
**Contact** : contact@denota.ci