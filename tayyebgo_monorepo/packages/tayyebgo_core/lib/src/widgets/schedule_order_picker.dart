import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

/// A reusable checkout widget that lets customers choose between
/// "Deliver Now" or scheduling their order for a later date/time.
///
/// Returns `null` via [onChanged] when "Deliver Now" is selected,
/// or a [DateTime] representing the scheduled delivery time.
class ScheduleOrderPicker extends StatefulWidget {
  final ValueChanged<DateTime?>? onChanged;

  const ScheduleOrderPicker({super.key, this.onChanged});

  @override
  State<ScheduleOrderPicker> createState() => _ScheduleOrderPickerState();
}

class _ScheduleOrderPickerState extends State<ScheduleOrderPicker> {
  bool _scheduleLater = false;
  DateTime? _selectedDate;
  DateTime? _selectedTime;

  DateTime? get _scheduledDateTime {
    if (_selectedDate == null || _selectedTime == null) return null;
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
  }

  void _notifyChanged() {
    widget.onChanged?.call(_scheduleLater ? _scheduledDateTime : null);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year, now.month, now.day + 7),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: context.primaryColor,
              onPrimary: Colors.white,
              surface: context.surfaceColor,
              onSurface: context.textPrimaryColor,
            ),
            dialogBackgroundColor: context.surfaceColor,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _notifyChanged();
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime != null
          ? TimeOfDay(hour: _selectedTime!.hour, minute: _selectedTime!.minute)
          : const TimeOfDay(hour: 12, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: context.primaryColor,
              onPrimary: Colors.white,
              surface: context.surfaceColor,
              onSurface: context.textPrimaryColor,
            ),
            dialogBackgroundColor: context.surfaceColor,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final dt = DateTime(0, 0, 0, picked.hour, picked.minute);
      if (dt.hour < 9 || dt.hour >= 23) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please select a time between 9:00 AM and 11:00 PM',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: context.primaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.brMd,
              ),
            ),
          );
        }
        return;
      }
      setState(() => _selectedTime = dt);
      _notifyChanged();
    }
  }

  String _formatDate(DateTime d) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    String label;
    if (DateTime(d.year, d.month, d.day) == DateTime(now.year, now.month, now.day)) {
      label = 'Today';
    } else if (DateTime(d.year, d.month, d.day) == tomorrow) {
      label = 'Tomorrow';
    } else {
      label = '${months[d.month - 1]} ${d.day}';
    }
    return label;
  }

  String _formatTime(DateTime t) {
    final hour = t.hour;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 20,
                color: _scheduleLater
                    ? context.primaryColor
                    : context.textMutedColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Delivery Time',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
              _buildToggle(context),
            ],
          ),
          if (_scheduleLater) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _buildDateButton(context)),
                const SizedBox(width: 10),
                Expanded(child: _buildTimeButton(context)),
              ],
            ),
            if (_scheduledDateTime != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: AppRadius.brMd,
                ),
                child: Text(
                  '${_formatDate(_selectedDate!)} at ${_formatTime(_selectedTime!)}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: context.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildToggle(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _scheduleLater = !_scheduleLater);
        if (!_scheduleLater) {
          _selectedDate = null;
          _selectedTime = null;
        }
        _notifyChanged();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _scheduleLater
              ? context.primaryColor.withValues(alpha: 0.15)
              : context.backgroundColor,
          borderRadius: AppRadius.brMd,
          border: Border.all(
            color: _scheduleLater ? context.primaryColor : context.borderColor,
            width: _scheduleLater ? 1.5 : 1,
          ),
        ),
        child: Text(
          _scheduleLater ? 'Scheduled' : 'Now',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: _scheduleLater ? context.primaryColor : context.textMutedColor,
          ),
        ),
      ),
    );
  }

  Widget _buildDateButton(BuildContext context) {
    final hasDate = _selectedDate != null;
    return GestureDetector(
      onTap: _pickDate,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: hasDate
              ? context.primaryColor.withValues(alpha: 0.1)
              : context.backgroundColor,
          borderRadius: AppRadius.brMd,
          border: Border.all(
            color: hasDate ? context.primaryColor : context.borderColor,
            width: hasDate ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: hasDate ? context.primaryColor : context.textMutedColor,
            ),
            const SizedBox(width: 6),
            Text(
              hasDate ? _formatDate(_selectedDate!) : 'Pick Date',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: hasDate ? context.primaryColor : context.textMutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeButton(BuildContext context) {
    final hasTime = _selectedTime != null;
    return GestureDetector(
      onTap: _pickTime,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: hasTime
              ? context.primaryColor.withValues(alpha: 0.1)
              : context.backgroundColor,
          borderRadius: AppRadius.brMd,
          border: Border.all(
            color: hasTime ? context.primaryColor : context.borderColor,
            width: hasTime ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 16,
              color: hasTime ? context.primaryColor : context.textMutedColor,
            ),
            const SizedBox(width: 6),
            Text(
              hasTime ? _formatTime(_selectedTime!) : 'Pick Time',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: hasTime ? context.primaryColor : context.textMutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
