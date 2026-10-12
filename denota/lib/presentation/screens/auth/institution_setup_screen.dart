// lib/presentation/screens/auth/institution_setup_screen.dart
//
// Écran de configuration d'une institution après inscription.
// Affiche un formulaire pour créer l'institution liée au profil.

import 'package:flutter/material.dart';

import '../../../core/constants/sports.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../main.dart';

class InstitutionSetupScreen extends StatefulWidget {
  final String role; // 'institution', 'federation' ou 'recruiter'

  const InstitutionSetupScreen({super.key, required this.role});

  @override
  State<InstitutionSetupScreen> createState() =>
      _InstitutionSetupScreenState();
}

class _InstitutionSetupScreenState extends State<InstitutionSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _officialNameCtrl = TextEditingController();
  final _nameCtrl         = TextEditingController();
  final _cityCtrl         = TextEditingController();
  final _descriptionCtrl  = TextEditingController();
  final _websiteCtrl      = TextEditingController();
  final _phoneCtrl        = TextEditingController();

  late InstitutionType _type;
  final Set<int> _selectedSports = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    switch (widget.role) {
      case 'institution':
        _type = InstitutionType.club;
        break;
      case 'federation':
        _type = InstitutionType.federation;
        break;
      case 'recruiter':
        _type = InstitutionType.agent;
        break;
      default:
        _type = InstitutionType.club;
    }
  }

  @override
  void dispose() {
    _officialNameCtrl.dispose();
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _descriptionCtrl.dispose();
    _websiteCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez au moins un sport'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final uid = supabase.auth.currentUser!.id;

      await supabase.from('institutions').insert({
        'profile_id': uid,
        'institution_type': _type.slug,
        'official_name': _officialNameCtrl.text.trim(),
        'name': _nameCtrl.text.trim().isEmpty
            ? _officialNameCtrl.text.trim()
            : _nameCtrl.text.trim(),
        'city': _cityCtrl.text.trim().isEmpty
            ? null
            : _cityCtrl.text.trim(),
        'country': 'CI',
        'sport_ids': _selectedSports.toList(),
        'description': _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
        'website_url': _websiteCtrl.text.trim().isEmpty
            ? null
            : _websiteCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty
            ? null
            : _phoneCtrl.text.trim(),
        'status': 'active',
        'is_verified': false,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Structure créée avec succès !'),
          backgroundColor: AppColors.success,
        ),
      );

      AppNavigator.goToFeed();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur : ${e.toString().length > 150 ? e.toString().substring(0, 150) : e.toString()}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.role == 'federation'
        ? 'Ma fédération'
        : widget.role == 'recruiter'
            ? 'Mon agence'
            : 'Ma structure';

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Finalisons votre profil',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ces informations seront visibles par les athlètes et les autres utilisateurs de DeNoTa.',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.grey500, height: 1.5),
                ),
                const SizedBox(height: 24),

                // Type de structure : affiché en lecture seule
// (défini par le rôle choisi à l'inscription)
Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
  decoration: BoxDecoration(
    color: AppColors.grey100,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.grey200),
  ),
  child: Row(
    children: [
      const Icon(Icons.category_outlined, color: AppColors.grey500, size: 20),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Type de structure',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.grey500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_type.emoji} ${_type.labelFr}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
      const Icon(Icons.lock_outline, color: AppColors.grey400, size: 18),
    ],
  ),
),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _officialNameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nom officiel *',
                    hintText: 'Ex: ASEC Mimosas',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nom court (optionnel)',
                    hintText: 'Ex: ASEC',
                    prefixIcon: Icon(Icons.short_text),
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _cityCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Ville',
                    hintText: 'Ex: Abidjan',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    prefixText: '+225 ',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _websiteCtrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Site web',
                    hintText: 'https://...',
                    prefixIcon: Icon(Icons.language),
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _descriptionCtrl,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Présentez votre structure...',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Sports pratiqués *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sélectionnez au moins un sport',
                  style: TextStyle(fontSize: 12, color: AppColors.grey500),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kPilotSports.map((sport) {
                    final selected = _selectedSports.contains(sport.id);
                    return FilterChip(
                      label: Text('${sport.emoji} ${sport.nameFr}'),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          if (selected) {
                            _selectedSports.remove(sport.id);
                          } else {
                            _selectedSports.add(sport.id);
                          }
                        });
                      },
                      selectedColor: AppColors.primaryBg,
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color:
                            selected ? AppColors.primary : AppColors.grey600,
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                      side: BorderSide(
                        color:
                            selected ? AppColors.primary : AppColors.grey200,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Créer ma structure'),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.info, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Votre structure sera vérifiée par DeNoTa sous 48h. '
                          'En attendant, vous pouvez déjà explorer les talents.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.blue,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}