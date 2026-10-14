import 'package:flutter/material.dart';
import 'package:hospital_dashboard/common/format.dart';
import 'package:hospital_dashboard/common/widgets/entrance.dart';
import 'package:hospital_dashboard/theme/app_colors.dart';
import 'package:hospital_dashboard/common/widgets/status_chip.dart';
import 'package:hospital_dashboard/features/patients/domain/patient.dart';
import 'package:hospital_dashboard/features/patients/presentation/widgets/patient_avatar.dart';

class PatientTable extends StatelessWidget {
  const PatientTable({required this.patients, required this.onOpen, super.key});

  final List<Patient> patients;
  final ValueChanged<Patient> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _HeaderRow(),
        const Divider(height: 1, color: AppColors.line),
        for (var i = 0; i < patients.length; i++)
          Entrance(
            delay: Duration(milliseconds: 35 * i),
            offset: 8,
            child: _PatientRow(
              patient: patients[i],
              striped: i.isOdd,
              onOpen: () => onOpen(patients[i]),
            ),
          ),
      ],
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _Head('Patient ID', flex: 11),
          _Head('Patient name', flex: 22),
          _Head('Gender', flex: 10),
          _Head('Date of birth', flex: 16),
          _Head('Admission date', flex: 16),
          _Head('Status', flex: 16),
          _Head('Actions', flex: 12),
        ],
      ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head(this.label, {required this.flex});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label.toUpperCase(),
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _PatientRow extends StatefulWidget {
  const _PatientRow({
    required this.patient,
    required this.striped,
    required this.onOpen,
  });

  final Patient patient;
  final bool striped;
  final VoidCallback onOpen;

  @override
  State<_PatientRow> createState() => _PatientRowState();
}

class _PatientRowState extends State<_PatientRow> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final background = _hover
        ? AppColors.mint
        : widget.striped
        ? const Color(0xFFFBFBFD)
        : Colors.white;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onOpen,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(13, 12, 16, 12),
            decoration: BoxDecoration(
              color: background,
              border: Border(
                left: BorderSide(
                  color: _hover ? AppColors.teal : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 11,
                  child: Text(
                    '${patient.id}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  flex: 22,
                  child: Row(
                    children: [
                      PatientAvatar(
                        name: patient.name,
                        radius: 16,
                        heroTag: 'patient-${patient.id}',
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          patient.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 10,
                  child: Text(patient.gender, overflow: TextOverflow.ellipsis),
                ),
                Expanded(
                  flex: 16,
                  child: Text(
                    formatHospitalDate(patient.dateOfBirth),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 16,
                  child: Text(
                    formatHospitalDate(patient.admissionDate),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 16,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: StatusChip(status: patient.status),
                    ),
                  ),
                ),
                Expanded(
                  flex: 12,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: widget.onOpen,
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text('Open'),
                        ),
                        AnimatedSlide(
                          offset: _hover ? Offset.zero : const Offset(-0.3, 0),
                          duration: const Duration(milliseconds: 160),
                          child: AnimatedOpacity(
                            opacity: _hover ? 1 : 0,
                            duration: const Duration(milliseconds: 160),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: AppColors.teal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
