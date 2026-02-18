import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/booking_service.dart';
import 'seat_selection_screen.dart';

class PlanSelectionScreen extends StatefulWidget {
  const PlanSelectionScreen({super.key});

  @override
  State<PlanSelectionScreen> createState() => _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends State<PlanSelectionScreen> {
  DateTime startDate = DateTime.now();
  int selectedMonths = 1;

  String slotType = 'PRESET';
  String selectedPresetSlot = 'MORNING';

  TimeOfDay? customStart;
  TimeOfDay? customEnd;

  int? baseAmount;
  int? discountAmount;
  int? finalAmount;
  bool pricingLoading = false;

  final Map<String, String> presetSlots = {
    'MORNING': '08:00 - 14:00',
    'AFTERNOON': '14:00 - 20:00',
    'EVENING': '20:00 - 24:00',
  };

  @override
  void initState() {
    super.initState();
    _loadLivePrice();
  }

  /* ================= HELPERS ================= */

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _choiceCard({
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.blue : Colors.grey.shade300,
            width: 2,
          ),
          color: selected ? Colors.blue.shade50 : Colors.white,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? Colors.blue : Colors.black,
          ),
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay? t) {
    if (t == null) return '--:--';
    final hour = t.hour.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  String _formatDate(DateTime d) {
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        customStart = picked;
      } else {
        customEnd = picked;
      }
    });

    _loadLivePrice();
  }

  /* ================= LIVE PRICING ================= */

  Future<void> _loadLivePrice() async {
    try {
      setState(() => pricingLoading = true);

      List<Map<String, String>> slotPayload;

      if (slotType == 'PRESET') {
        final times = presetSlots[selectedPresetSlot]!.split(' - ');
        slotPayload = [
          {"start": times[0], "end": times[1]},
        ];
      } else {
        if (customStart == null || customEnd == null) {
          setState(() => pricingLoading = false);
          return;
        }

        slotPayload = [
          {"start": _formatTime(customStart), "end": _formatTime(customEnd)},
        ];
      }

      final quote = await BookingService.getQuotePreview(
        months: selectedMonths,
        slots: slotPayload,
        discount: selectedMonths == 1 ? 0 : 5,
      );

      setState(() {
        baseAmount = quote["baseAmount"];
        discountAmount = quote["discountAmount"];
        finalAmount = quote["finalAmount"];
      });
    } catch (_) {
      // silent
    } finally {
      setState(() => pricingLoading = false);
    }
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Plan'),
        backgroundColor: const Color(0xFF4A6CF7),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Start Date'),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: startDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => startDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${startDate.day}-${startDate.month}-${startDate.year}",
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),

            _sectionTitle('Select Duration'),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              physics: const NeverScrollableScrollPhysics(),
              children: [1, 3, 6, 12].map((m) {
                return _choiceCard(
                  text: '$m Month${m > 1 ? 's' : ''}',
                  selected: selectedMonths == m,
                  onTap: () {
                    setState(() => selectedMonths = m);
                    _loadLivePrice();
                  },
                );
              }).toList(),
            ),

            _sectionTitle('Daily Time Slot'),
            Row(
              children: [
                Radio(
                  value: 'PRESET',
                  groupValue: slotType,
                  onChanged: (_) {
                    setState(() => slotType = 'PRESET');
                    _loadLivePrice();
                  },
                ),
                const Text('Preset Slots'),
                Radio(
                  value: 'CUSTOM',
                  groupValue: slotType,
                  onChanged: (_) {
                    setState(() => slotType = 'CUSTOM');
                  },
                ),
                const Text('Custom Time'),
              ],
            ),

            if (slotType == 'PRESET')
              Column(
                children: presetSlots.entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _choiceCard(
                      text: '${e.key} (${e.value})',
                      selected: selectedPresetSlot == e.key,
                      onTap: () {
                        setState(() => selectedPresetSlot = e.key);
                        _loadLivePrice();
                      },
                    ),
                  );
                }).toList(),
              ),

            if (slotType == 'CUSTOM')
              Row(
                children: [
                  Expanded(
                    child: _choiceCard(
                      text: 'Start: ${_formatTime(customStart)}',
                      selected: false,
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _choiceCard(
                      text: 'End: ${_formatTime(customEnd)}',
                      selected: false,
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ],
              ),

            _sectionTitle('Plan Summary'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: pricingLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Base Amount : ₹${baseAmount ?? 0}"),
                        Text("Discount : ₹${discountAmount ?? 0}"),
                        const Divider(),
                        Text(
                          "Total Payable : ₹${finalAmount ?? 0}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6CF7),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: finalAmount == null
                    ? null
                    : () async {
                        List<Map<String, String>> slotPayload;

                        if (slotType == 'PRESET') {
                          final times = presetSlots[selectedPresetSlot]!.split(
                            ' - ',
                          );
                          slotPayload = [
                            {"start": times[0], "end": times[1]},
                          ];
                        } else {
                          slotPayload = [
                            {
                              "start": _formatTime(customStart),
                              "end": _formatTime(customEnd),
                            },
                          ];
                        }

                        final quoteId = await BookingService.lockQuote(
                          months: selectedMonths,
                          slots: slotPayload,
                          discount: selectedMonths == 1 ? 0 : 5,
                        );

                        final endDate = DateTime(
                          startDate.year,
                          startDate.month + selectedMonths,
                          startDate.day,
                        );

                        final formattedStart = _formatDate(startDate);
                        final formattedEnd = _formatDate(endDate);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SeatSelectionScreen(
                              mode: SeatScreenMode.createSubscription,
                              startDate: formattedStart,
                              endDate: formattedEnd,
                              quoteId: quoteId,
                              finalAmount: finalAmount!,
                            ),
                          ),
                        );
                      },
                child: const Text(
                  'Continue to Seat Selection',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
