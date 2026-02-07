import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> showLanguagePickerSheet({
  required BuildContext context,
  required List<Map<String, String>> languages,
  required String selectedCode,
  required void Function(String code, String name) onSelected,
}) {
  final TextEditingController controller = TextEditingController();
  final ValueNotifier<String> query = ValueNotifier('');

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 12,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              TextField(
                controller: controller,
                onChanged: (value) => query.value = value.trim(),
                decoration: InputDecoration(
                  hintText: 'Search language',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: query,
                  builder: (context, value, _) {
                    final filtered = value.isEmpty
                        ? languages
                        : languages
                            .where((lang) =>
                                lang['name']!
                                    .toLowerCase()
                                    .contains(value.toLowerCase()) ||
                                lang['code']!
                                    .toLowerCase()
                                    .contains(value.toLowerCase()))
                            .toList();
                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final lang = filtered[index];
                        final isSelected = lang['code'] == selectedCode;
                        return ListTile(
                          title: Text(
                            lang['name']!,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? const Color(0xFF003049)
                                  : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            lang['code']!,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check,
                                  color: Color(0xFF003049))
                              : null,
                          onTap: () {
                            onSelected(lang['code']!, lang['name']!);
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
