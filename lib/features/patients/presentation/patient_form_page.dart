import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_dashboard/features/auth/presentation/auth_controller.dart';
import 'package:hospital_dashboard/features/clinic/data/clinic_store.dart';
import 'package:hospital_dashboard/features/clinic/domain/clinic_models.dart';
import 'package:hospital_dashboard/features/clinic/domain/form_input.dart';
import 'package:hospital_dashboard/features/clinic/domain/form_rules.dart';
import 'package:hospital_dashboard/features/patients/domain/patient.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_exception.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_status.dart';
import 'package:hospital_dashboard/theme/app_colors.dart';
import 'package:hospital_dashboard/theme/app_theme.dart';
import 'package:intl/intl.dart';

class PatientFormPage extends ConsumerStatefulWidget {
  const PatientFormPage({this.patientId, super.key});

  final int? patientId;

  @override
  ConsumerState<PatientFormPage> createState() => _PatientFormPageState();
}

class _PatientFormPageState extends ConsumerState<PatientFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _history = TextEditingController();
  final _allergies = TextEditingController();
  final _medications = TextEditingController();
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();
  DateTime? _dob;
  String _gender = 'Female';
  String _blood = 'O+';
  PatientStatus _status = PatientStatus.admitted;
  String? _doctorId;
  var _loading = true;
  var _saving = false;
  var _hidePassword = true;
  var _hasLogin = false;
  String? _error;

  bool get _editing => widget.patientId != null;

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
      _address,
      _history,
      _allergies,
      _medications,
      _emergencyName,
      _emergencyPhone,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final id = widget.patientId;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final store = await ref.read(clinicStoreProvider.future);
      final patient = await store.getPatient(
        ref.read(authControllerProvider).actor,
        id,
      );
      final rel = await store.activeRelationship(id);
      final login = await store.userByEmail(patient.email);
      if (!mounted) return;
      _hasLogin =
          login != null &&
          login.role == UserRole.patient &&
          login.patientId == id;
      _name.text = patient.name;
      _email.text = patient.email;
      _phone.text = patient.phone;
      _address.text = patient.address;
      _history.text = patient.medicalHistory;
      _allergies.text = patient.allergies;
      _medications.text = patient.medications;
      _emergencyName.text = patient.emergencyContactName;
      _emergencyPhone.text = patient.emergencyContactPhone;
      _dob = patient.dateOfBirth;
      _gender = patient.gender;
      _blood = patient.bloodGroup.isEmpty ? 'O+' : patient.bloodGroup;
      _status = patient.status;
      _doctorId = rel?.doctorId;
      setState(() => _loading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error is PatientApiException || error is ClinicException
            ? error.toString()
            : 'Could not open this record.';
      });
    }
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    final message = patientFormError(
      name: _name.text,
      email: _email.text,
      phone: _phone.text,
      dateOfBirth: _dob,
      gender: _gender,
      bloodGroup: _blood,
      address: _address.text,
      emergencyName: _emergencyName.text,
      emergencyPhone: _emergencyPhone.text,
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
      final draft = Patient(
        id: widget.patientId ?? 0,
        name: _name.text,
        gender: _gender,
        dateOfBirth: _dob!,
        admissionDate: DateTime.now(),
        status: _status,
        phone: _phone.text,
        email: _email.text,
        address: _address.text,
        bloodGroup: _blood,
        emergencyContactName: _emergencyName.text,
        emergencyContactPhone: _emergencyPhone.text,
        medicalHistory: _history.text,
        allergies: _allergies.text,
        medications: _medications.text,
      );
      final saved = _editing
          ? await store.updatePatient(actor, draft, password: _password.text)
          : await store.createPatient(actor, draft, password: _password.text);
      if (!_editing && _doctorId != null && _doctorId!.isNotEmpty) {
        await store.assignDoctor(
          actor,
          patientId: saved.id,
          doctorId: _doctorId!,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editing
                ? 'Patient updated.'
                : 'Patient registered. They can sign in with this email.',
          ),
        ),
      );
      context.go('/patients/${saved.id}');
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final doctors = ref.watch(_doctorChoicesProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
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
                    _editing ? 'Edit patient' : 'Register patient',
                    style: AppType.title,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _passwordRequired
                        ? 'Set a password. They sign in with this email and chat with their doctor.'
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
                      labelText: _passwordRequired
                          ? 'Password'
                          : 'New password',
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
                  FormField<DateTime>(
                    validator: (_) => dateOfBirthRule(_dob),
                    builder: (state) {
                      return InkWell(
                        onTap: () async {
                          await _pickDob();
                          state.didChange(_dob);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date of birth',
                            errorText: state.errorText,
                          ),
                          child: Text(
                            _dob == null
                                ? 'Choose a date'
                                : DateFormat('d MMM yyyy').format(_dob!),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: const [
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (value) =>
                        setState(() => _gender = value ?? _gender),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _blood,
                    decoration: const InputDecoration(labelText: 'Blood group'),
                    items: [
                      for (final group in const [
                        'A+',
                        'A-',
                        'B+',
                        'B-',
                        'O+',
                        'O-',
                        'AB+',
                        'AB-',
                      ])
                        DropdownMenuItem(value: group, child: Text(group)),
                    ],
                    onChanged: (value) =>
                        setState(() => _blood = value ?? _blood),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _address,
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.streetAddress,
                    minLines: 2,
                    maxLines: 3,
                    inputFormatters: sentenceFormatters,
                    decoration: const InputDecoration(labelText: 'Address'),
                    validator: (value) => requiredText(value, 'the address'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _history,
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.multiline,
                    minLines: 2,
                    maxLines: 4,
                    inputFormatters: sentenceFormatters,
                    decoration: const InputDecoration(
                      labelText: 'Medical history',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _allergies,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    inputFormatters: sentenceFormatters,
                    decoration: const InputDecoration(labelText: 'Allergies'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _medications,
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.multiline,
                    minLines: 2,
                    maxLines: 3,
                    inputFormatters: sentenceFormatters,
                    decoration: const InputDecoration(
                      labelText: 'Current medications',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emergencyName,
                    textCapitalization: TextCapitalization.words,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    inputFormatters: personNameFormatters,
                    decoration: const InputDecoration(
                      labelText: 'Emergency contact name',
                    ),
                    validator: (value) =>
                        personNameRule(value, label: 'an emergency contact'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emergencyPhone,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: phoneFormatters,
                    maxLength: 10,
                    decoration: const InputDecoration(
                      labelText: 'Emergency contact number',
                      counterText: '',
                      helperText: '10 digits',
                    ),
                    validator: phoneRule,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<PatientStatus>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: [
                      for (final status in PatientStatus.values)
                        DropdownMenuItem(
                          value: status,
                          child: Text(status.displayLabel),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _status = value ?? _status),
                  ),
                  if (!_editing) ...[
                    const SizedBox(height: 12),
                    doctors.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (error, _) => Text(error.toString()),
                      data: (items) => DropdownButtonFormField<String?>(
                        initialValue: _doctorId,
                        decoration: const InputDecoration(
                          labelText: 'Assign doctor',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Assign later'),
                          ),
                          for (final doctor in items)
                            DropdownMenuItem(
                              value: doctor.id,
                              child: Text(
                                '${doctor.name} · ${doctor.specialization}',
                              ),
                            ),
                        ],
                        onChanged: (value) => setState(() => _doctorId = value),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(
                      _saving
                          ? 'Saving...'
                          : _editing
                          ? 'Save changes'
                          : 'Register patient',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final _doctorChoicesProvider = FutureProvider<List<Doctor>>((ref) async {
  final store = await ref.watch(clinicStoreProvider.future);
  final actor = ref.watch(authControllerProvider).actor;
  return store.listDoctors(actor);
});
