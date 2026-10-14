import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_dashboard/features/auth/presentation/auth_controller.dart';
import 'package:hospital_dashboard/features/clinic/data/clinic_store.dart';
import 'package:hospital_dashboard/features/clinic/domain/clinic_models.dart';
import 'package:hospital_dashboard/features/clinic/domain/form_input.dart';
import 'package:hospital_dashboard/features/clinic/domain/form_rules.dart';
import 'package:hospital_dashboard/theme/app_colors.dart';
import 'package:hospital_dashboard/theme/app_theme.dart';

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _slots = ['Morning', 'Afternoon', 'Evening'];

class DoctorFormPage extends ConsumerStatefulWidget {
  const DoctorFormPage({this.doctorId, super.key});

  final String? doctorId;

  @override
  ConsumerState<DoctorFormPage> createState() => _DoctorFormPageState();
}

class _DoctorFormPageState extends ConsumerState<DoctorFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _phone = TextEditingController();
  final _qualification = TextEditingController();
  final _years = TextEditingController();
  final _hospital = TextEditingController(text: 'City Hospital');
  final _fee = TextEditingController();
  final _bio = TextEditingController();
  final _specialization = TextEditingController();
  final _daysSelected = <String>{};
  final _slotsSelected = <String>{};
  String _photo = '';
  var _loading = true;
  var _saving = false;
  var _hidePassword = true;
  var _hasLogin = false;
  String? _error;

  bool get _editing => widget.doctorId != null;

  bool get _passwordRequired => !_editing || !_hasLogin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _email,
      _password,
      _confirm,
      _phone,
      _qualification,
      _years,
      _hospital,
      _fee,
      _bio,
      _specialization,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final id = widget.doctorId;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final store = await ref.read(clinicStoreProvider.future);
      final doctor = await store.getDoctor(
        ref.read(authControllerProvider).actor,
        id,
      );
      final login = await store.userByEmail(doctor.email);
      if (!mounted) return;
      _hasLogin =
          login != null &&
          login.role == UserRole.doctor &&
          login.doctorId == id;
      _name.text = doctor.name;
      _email.text = doctor.email;
      _phone.text = doctor.phone;
      _qualification.text = doctor.qualification;
      _years.text = '${doctor.yearsExperience}';
      _hospital.text = doctor.hospital;
      _fee.text = '${doctor.consultationFee}';
      _bio.text = doctor.bio;
      _specialization.text = doctor.specialization;
      _daysSelected.addAll(doctor.availableDays);
      _slotsSelected.addAll(doctor.timeSlots);
      _photo = doctor.photoDataUrl;
      setState(() => _loading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final bytes = result?.files.single.bytes;
    if (bytes == null) return;
    if (bytes.length > 180000) {
      setState(() => _error = 'Use a photo smaller than 180 KB.');
      return;
    }
    setState(() => _photo = 'data:image/jpeg;base64,${base64Encode(bytes)}');
  }

  Future<void> _save() async {
    final message = doctorFormError(
      name: _name.text,
      email: _email.text,
      phone: _phone.text,
      specialization: _specialization.text,
      qualification: _qualification.text,
      years: _years.text,
      hospital: _hospital.text,
      fee: _fee.text,
      days: _daysSelected.toList(),
      slots: _slotsSelected.toList(),
      password: _password.text,
      confirmPassword: _confirm.text,
      passwordRequired: _passwordRequired,
    );
    if (!(_formKey.currentState?.validate() ?? false) || message != null) {
      setState(() => _error = message);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final store = await ref.read(clinicStoreProvider.future);
      final actor = ref.read(authControllerProvider).actor;
      final draft = Doctor(
        id: widget.doctorId ?? '',
        name: _name.text,
        email: _email.text,
        phone: _phone.text,
        specialization: _specialization.text,
        qualification: _qualification.text,
        yearsExperience: int.parse(_years.text.trim()),
        hospital: _hospital.text,
        consultationFee: int.parse(_fee.text.trim()),
        availableDays: _daysSelected.toList(),
        timeSlots: _slotsSelected.toList(),
        bio: _bio.text,
        photoDataUrl: _photo,
      );
      final saved = _editing
          ? await store.updateDoctor(actor, draft, password: _password.text)
          : await store.createDoctor(actor, draft, password: _password.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editing
                ? 'Doctor updated.'
                : 'Doctor registered. They can sign in with this email.',
          ),
        ),
      );
      context.go('/doctors/${saved.id}');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        32 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editing ? 'Edit doctor' : 'Register doctor',
                  style: AppType.title,
                ),
                const SizedBox(height: 6),
                Text(
                  _passwordRequired
                      ? 'Set a password. They sign in with this email and chat with assigned patients.'
                      : 'Leave the password blank to keep the current one.',
                  style: AppType.body,
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.critical),
                    ),
                  ),
                Row(
                  children: [
                    _Photo(dataUrl: _photo),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _pickPhoto,
                      child: const Text('Profile photo'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  inputFormatters: personNameFormatters,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: personNameRule,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  inputFormatters: emailFormatters,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: emailRule,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: _hidePassword,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: _passwordRequired ? 'Password' : 'New password',
                    helperText: 'At least 8 characters',
                    suffixIcon: IconButton(
                      tooltip: _hidePassword
                          ? 'Show password'
                          : 'Hide password',
                      onPressed: () =>
                          setState(() => _hidePassword = !_hidePassword),
                      icon: Icon(
                        _hidePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) =>
                      passwordRule(value, required: _passwordRequired),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirm,
                  obscureText: _hidePassword,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                  ),
                  validator: (value) => confirmPasswordRule(
                    value,
                    _password.text,
                    required: _passwordRequired || _password.text.isNotEmpty,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: phoneFormatters,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    counterText: '',
                    helperText: '10 digits',
                  ),
                  validator: phoneRule,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _specialization,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  inputFormatters: titleFormatters,
                  decoration: const InputDecoration(
                    labelText: 'Specialization',
                  ),
                  validator: (value) => requiredText(value, 'a specialization'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _qualification,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  inputFormatters: titleFormatters,
                  decoration: const InputDecoration(labelText: 'Qualification'),
                  validator: (value) => requiredText(value, 'a qualification'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _years,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: yearsFormatters,
                  maxLength: 2,
                  decoration: const InputDecoration(
                    labelText: 'Years of experience',
                    counterText: '',
                    helperText: 'Up to 80',
                  ),
                  validator: experienceRule,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _hospital,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  inputFormatters: titleFormatters,
                  decoration: const InputDecoration(
                    labelText: 'Hospital or clinic',
                  ),
                  validator: (value) =>
                      requiredText(value, 'the hospital or clinic'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fee,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: feeFormatters,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Consultation fee (INR)',
                    counterText: '',
                    helperText: 'Digits only',
                  ),
                  validator: feeRule,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Available days',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final day in _days)
                      FilterChip(
                        label: Text(day),
                        selected: _daysSelected.contains(day),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            _daysSelected.add(day);
                          } else {
                            _daysSelected.remove(day);
                          }
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Time slots',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final slot in _slots)
                      FilterChip(
                        label: Text(slot),
                        selected: _slotsSelected.contains(slot),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            _slotsSelected.add(slot);
                          } else {
                            _slotsSelected.remove(slot);
                          }
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bio,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  minLines: 3,
                  maxLines: 5,
                  inputFormatters: sentenceFormatters,
                  decoration: const InputDecoration(
                    labelText: 'Short professional bio',
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving...' : 'Save doctor'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.dataUrl});

  final String dataUrl;

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;
    if (dataUrl.contains(',')) {
      try {
        image = MemoryImage(base64Decode(dataUrl.split(',').last));
      } catch (_) {
        image = null;
      }
    }
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.mint,
      backgroundImage: image,
      child: image == null
          ? const Icon(Icons.person_rounded, color: AppColors.teal)
          : null,
    );
  }
}
