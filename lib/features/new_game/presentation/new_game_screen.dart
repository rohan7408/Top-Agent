import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../application/game_controller.dart';
import '../../../application/persistence_providers.dart';

class NewGameScreen extends ConsumerStatefulWidget {
  const NewGameScreen({super.key});

  @override
  ConsumerState<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends ConsumerState<NewGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _agentNameController = TextEditingController();
  final _agencyNameController = TextEditingController();
  final _ageController = TextEditingController();
  bool _isStarting = false;

  @override
  void dispose() {
    _agentNameController.dispose();
    _agencyNameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _startCareer() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      final existing =
          await ref.read(gameSaveRepositoryProvider).latestSummary();
      if (existing != null && mounted) {
        final replace = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Replace saved career?'),
            content: Text(
              '${existing.agencyName} at ${existing.seasonLabel}, Week ${existing.currentWeek} will be replaced by this new career.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Keep career'),
              ),
              FilledButton(
                key: const Key('confirmNewCareerButton'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Start new'),
              ),
            ],
          ),
        );
        if (replace != true) return;
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The existing save could not be checked. Try again.'),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isStarting = true);

    final controller = ref.read(gameControllerProvider.notifier);
    controller.startNewGame(
      agentName: _agentNameController.text,
      agencyName: _agencyNameController.text,
      agentAge: int.parse(_ageController.text),
    );
    final saved = await controller.saveNow();
    if (!mounted) return;
    setState(() => _isStarting = false);
    context.go(AppRoutes.game);
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Career started, but the autosave could not be written.'),
        ),
      );
    }
  }

  String? _validateRequiredName(String? value, String label) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter $label.';
    if (trimmed.length < 2) return 'Use at least 2 characters.';
    if (trimmed.length > 40) return 'Use 40 characters or fewer.';
    return null;
  }

  String? _validateAge(String? value) {
    final age = int.tryParse(value ?? '');
    if (age == null) return 'Enter your age.';
    if (age < 18 || age > 80) return 'Age must be between 18 and 80.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to main menu',
          onPressed: () => context.go(AppRoutes.mainMenu),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'NEW CAREER',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.teal,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Sign your first deal.',
                        style: textTheme.headlineLarge),
                    const SizedBox(height: 12),
                    Text(
                      'Create the identity that clubs and players will know you by.',
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.muted,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      key: const Key('agentNameField'),
                      controller: _agentNameController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(
                        labelText: 'Agent name',
                        hintText: 'e.g. Alex Morgan',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (value) =>
                          _validateRequiredName(value, 'an agent name'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('agencyNameField'),
                      controller: _agencyNameController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Agency name',
                        hintText: 'e.g. North Star Sports',
                        prefixIcon: Icon(Icons.business_center_outlined),
                      ),
                      validator: (value) =>
                          _validateRequiredName(value, 'an agency name'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('agentAgeField'),
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Agent age',
                        hintText: '18–80',
                        prefixIcon: Icon(Icons.cake_outlined),
                      ),
                      validator: _validateAge,
                      onFieldSubmitted: (_) => _startCareer(),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      key: const Key('startCareerButton'),
                      onPressed: _isStarting ? null : _startCareer,
                      icon: _isStarting
                          ? const SizedBox.square(
                              dimension: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_forward_rounded),
                      label: Text(
                        _isStarting ? 'Creating career…' : 'Start career',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Your career begins in 2025/2026, Week 1.',
                      textAlign: TextAlign.center,
                      style:
                          textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
