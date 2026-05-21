import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../auth/domain/readable_auth_error.dart';
import 'application/signup_providers.dart';
import 'domain/signup_profile.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _zipCodeController;
  late final TextEditingController _address1Controller;
  late final TextEditingController _address2Controller;
  late final TextEditingController _birthDateController;

  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(signupFlowProvider).profile;
    _zipCodeController = TextEditingController(text: profile.zipCode);
    _address1Controller = TextEditingController(text: profile.address1);
    _address2Controller = TextEditingController(text: profile.address2);
    _birthDateController = TextEditingController(text: profile.birthDate);
  }

  @override
  void dispose() {
    _zipCodeController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signupState = ref.watch(signupFlowProvider);
    final profile = signupState.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('회원정보 입력')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: [
            Text(
              '회원가입 3단계',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '회원정보를 입력해 주세요',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            _ReadonlyInfo(label: '이름', value: profile.name),
            _ReadonlyInfo(label: '연결 계정', value: profile.providerLabel),
            _ReadonlyInfo(label: '휴대폰번호', value: profile.phone),
            const SizedBox(height: 16),
            TextField(
              controller: _zipCodeController,
              decoration: const InputDecoration(
                labelText: '우편번호',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              enabled: !_saving,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _saving
                  ? null
                  : () => context.push(AppRoutes.addressWebView),
              icon: const Icon(Icons.map_outlined),
              label: const Text('주소검색 WebView 확인'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _address1Controller,
              decoration: const InputDecoration(
                labelText: '기본 주소',
                border: OutlineInputBorder(),
              ),
              enabled: !_saving,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _address2Controller,
              decoration: const InputDecoration(
                labelText: '상세 주소',
                border: OutlineInputBorder(),
              ),
              enabled: !_saving,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _birthDateController,
              decoration: const InputDecoration(
                labelText: '생년월일',
                hintText: 'YYYY-MM-DD',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.datetime,
              enabled: !_saving,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _ProfileNotice(message: _errorMessage!),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _submitProfile,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? '저장 중' : '회원정보 저장'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _saving
                  ? null
                  : () => context.go(AppRoutes.signupVerify),
              icon: const Icon(Icons.arrow_back),
              label: const Text('본인인증으로'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitProfile() async {
    final signupToken = ref.read(signupFlowProvider).signupToken;
    if (signupToken == null || signupToken.trim().isEmpty) {
      setState(() {
        _errorMessage = '회원가입 토큰이 없어 회원정보를 저장할 수 없습니다. 소셜 로그인을 다시 시도해 주세요.';
      });
      return;
    }

    final currentProfile = ref.read(signupFlowProvider).profile;
    final nextProfile = currentProfile.copyWith(
      zipCode: _zipCodeController.text.trim(),
      address1: _address1Controller.text.trim(),
      address2: _address2Controller.text.trim(),
      birthDate: _birthDateController.text.trim(),
    );
    final validationMessage = _validateProfile(nextProfile);
    if (validationMessage != null) {
      setState(() {
        _errorMessage = validationMessage;
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(signupRepositoryProvider)
          .submitProfile(signupToken: signupToken, profile: nextProfile);
      ref.read(signupFlowProvider.notifier).updateProfile(nextProfile);

      if (mounted) {
        context.go(AppRoutes.signupComplete);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = _readErrorMessage(error, '회원정보 저장에 실패했습니다.');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String? _validateProfile(SignupProfileDraft profile) {
    if (profile.zipCode.trim().isEmpty) {
      return '우편번호를 입력해 주세요.';
    }
    if (profile.address1.trim().isEmpty) {
      return '기본 주소를 입력해 주세요.';
    }
    if (profile.address2.trim().isEmpty) {
      return '상세 주소를 입력해 주세요.';
    }
    if (!_isValidBirthDate(profile.birthDate)) {
      return '생년월일은 YYYY-MM-DD 형식으로 입력해 주세요.';
    }

    return null;
  }

  bool _isValidBirthDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value.trim());
    if (match == null) {
      return false;
    }

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);

    return date.year == year && date.month == month && date.day == day;
  }

  String _readErrorMessage(Object error, String fallbackMessage) =>
      readAuthErrorMessage(error, fallbackMessage);
}

class _ReadonlyInfo extends StatelessWidget {
  const _ReadonlyInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(child: Text(value.trim().isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}

class _ProfileNotice extends StatelessWidget {
  const _ProfileNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        border: Border.all(color: const Color(0xFFFED7AA)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: Text(message)),
    );
  }
}
