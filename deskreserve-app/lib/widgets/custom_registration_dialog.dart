import 'package:flutter/material.dart';

class CustomRegistrationDialog extends StatefulWidget {
  final int seatNumber;

  const CustomRegistrationDialog({super.key, required this.seatNumber});

  @override
  State<CustomRegistrationDialog> createState() =>
      _CustomRegistrationDialogState();
}

class _CustomRegistrationDialogState extends State<CustomRegistrationDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  TimeOfDay? startTime;
  TimeOfDay? endTime;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        "Seat ${widget.seatNumber}",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// NAME
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Student Name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Name required" : null,
              ),

              const SizedBox(height: 12),

              /// PHONE
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().length < 10 ? "Invalid phone" : null,
              ),

              const SizedBox(height: 12),

              /// START TIME
              ListTile(
                title: const Text("Start Time"),
                subtitle: Text(
                  startTime == null
                      ? "Select start time"
                      : startTime!.format(context),
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () => pickTime(true),
              ),

              /// END TIME
              ListTile(
                title: const Text("End Time"),
                subtitle: Text(
                  endTime == null
                      ? "Select end time"
                      : endTime!.format(context),
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () => pickTime(false),
              ),

              const SizedBox(height: 8),

              /// NOTE
              TextFormField(
                controller: noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Purpose / Note (optional)",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            if (startTime == null || endTime == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Select start & end time")),
              );
              return;
            }

            /// Return raw form data only
            Navigator.pop(context, {
              "seat": widget.seatNumber,
              "name": nameController.text.trim(),
              "phone": phoneController.text.trim(),
              "note": noteController.text.trim(),
              "startTime": startTime,
              "endTime": endTime,
            });
          },
          child: const Text("Continue"),
        ),
      ],
    );
  }
}
