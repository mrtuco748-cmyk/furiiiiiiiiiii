import 'package:flutter/material.dart';

import '../../../models/event_type.dart';
import 'schedule_form_fields.dart';

const _c = Color(0xFF00D4FF);

class ScheduleFormCard extends StatelessWidget {
  final double width;
  final double height;
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final TextEditingController locCtrl;
  final TextEditingController instCtrl;
  final TextEditingController startTimeCtrl;
  final TextEditingController endTimeCtrl;
  final DateTime date;
  final String selectedType;
  final List<EventType> types;
  final VoidCallback onPickDate;
  final void Function(TextEditingController ctrl) onPickTime;
  final VoidCallback onOpenTypePicker;
  final VoidCallback onManageTypes;

  const ScheduleFormCard({
    super.key,
    required this.width,
    required this.height,
    required this.titleCtrl,
    required this.descCtrl,
    required this.locCtrl,
    required this.instCtrl,
    required this.startTimeCtrl,
    required this.endTimeCtrl,
    required this.date,
    required this.selectedType,
    required this.types,
    required this.onPickDate,
    required this.onPickTime,
    required this.onOpenTypePicker,
    required this.onManageTypes,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: width * 0.04,
      top: height * 0.09,
      width: width * 0.92,
      height: height * 0.74,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: _c,
            border: Border.all(color: _c, width: 4),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.title, color: Color(0xFF00D4FF), size: 22),
                  const SizedBox(width: 10),
                  Expanded(child: ScheduleTextField(controller: titleCtrl, hint: '...')),
                ]),
                const SizedBox(height: 14),
                ScheduleTypeRow(
                  types: types,
                  selectedType: selectedType,
                  onOpenTypePicker: onOpenTypePicker,
                  onManageTypes: onManageTypes,
                ),
                const SizedBox(height: 14),
                Row(children: [
                  const Icon(Icons.calendar_today, color: Color(0xFF00D4FF), size: 22),
                  const SizedBox(width: 10),
                  Expanded(child: ScheduleDateField(date: date, onTap: onPickDate)),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  const Icon(Icons.access_time, color: Color(0xFF00D4FF), size: 22),
                  const SizedBox(width: 10),
                  Expanded(child: ScheduleTimeField(controller: startTimeCtrl, onTap: () => onPickTime(startTimeCtrl))),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: Color(0xFF0088AA), size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: ScheduleTimeField(controller: endTimeCtrl, onTap: () => onPickTime(endTimeCtrl))),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  const Icon(Icons.place, color: Color(0xFF00D4FF), size: 22),
                  const SizedBox(width: 10),
                  Expanded(child: ScheduleTextField(controller: locCtrl, hint: '...')),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  const Icon(Icons.badge, color: Color(0xFF00D4FF), size: 22),
                  const SizedBox(width: 10),
                  Expanded(child: ScheduleTextField(controller: instCtrl, hint: 'profesor (opcional)')),
                ]),
                const SizedBox(height: 14),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Padding(padding: EdgeInsets.only(top: 4), child: Icon(Icons.notes, color: Color(0xFF0088AA), size: 22)),
                  const SizedBox(width: 10),
                  Expanded(child: ScheduleTextField(controller: descCtrl, hint: '...', maxLines: 3)),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
