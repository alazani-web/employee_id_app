
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../widgets/app_date_picker.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../providers/alert_provider.dart';
import '../services/notification_service.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  int selectedFilter = 0;
  final TextEditingController searchController = TextEditingController();

  final List<Map<String, dynamic>> _documents = [];
  final Map<String, List<String>> _documentLogs = {};

  final List<Map<String, String>> _documentTypes = [
    {'name': 'السجل التجاري', 'icon': '🏢'},
    {'name': 'الرخصة', 'icon': '📄'},
    {'name': 'التأمين', 'icon': '🛡️'},
    {'name': 'أخرى', 'icon': '📁'},
  ];

  final Color primaryBlue = const Color(0xff2563EB);

  OverlayEntry? _messageEntry;

  final List<String> filters = [
    "الكل",
    "نشط",
    "تنتهي قريباً",
    "منتهي",
  ];

  static const String _documentsStorageKey = 'employee_id_app_documents_v2';
  static const String _documentTypesStorageKey = 'employee_id_app_document_types_v2';
  static const String _documentLogsStorageKey = 'employee_id_app_document_logs_v2';

  @override
  void initState() {
    super.initState();
    searchController.addListener(() => setState(() {}));
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    try {
      final rawDocuments = prefs.getString(_documentsStorageKey);
      final rawTypes = prefs.getString(_documentTypesStorageKey);
      final rawLogs = prefs.getString(_documentLogsStorageKey);

      if (rawDocuments != null && rawDocuments.isNotEmpty) {
        final decoded = jsonDecode(rawDocuments);
        if (decoded is List) {
          _documents
            ..clear()
            ..addAll(
              decoded
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item)),
            );
        }
      }

      if (rawTypes != null && rawTypes.isNotEmpty) {
        final decoded = jsonDecode(rawTypes);
        if (decoded is List) {
          _documentTypes
            ..clear()
            ..addAll(
              decoded
                  .whereType<Map>()
                  .map((item) => Map<String, String>.from(
                        item.map(
                          (key, value) => MapEntry(
                            key.toString(),
                            value?.toString() ?? '',
                          ),
                        ),
                      )),
            );
        }
      }

      if (rawLogs != null && rawLogs.isNotEmpty) {
        final decoded = jsonDecode(rawLogs);
        if (decoded is Map) {
          _documentLogs
            ..clear()
            ..addAll(
              decoded.map(
                (key, value) => MapEntry(
                  key.toString(),
                  value is List
                      ? value.map((e) => e.toString()).toList()
                      : <String>[],
                ),
              ),
            );
        }
      }

      setState(() {});
    } catch (_) {
      // إذا كانت البيانات القديمة غير صالحة، لا نوقف الشاشة.
    }
  }

  Future<void> _saveDocumentsAndRefreshAlerts() async {
    await _saveDocuments();
    await NotificationService.instance.syncStoredData();
    if (!mounted) return;
    await context.read<AlertProvider>().refreshDocuments();
  }

  Future<void> _saveDocuments() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _documentsStorageKey,
      jsonEncode(_documents),
    );

    await prefs.setString(
      _documentTypesStorageKey,
      jsonEncode(_documentTypes),
    );

    await prefs.setString(
      _documentLogsStorageKey,
      jsonEncode(_documentLogs),
    );
  }

  @override
  void dispose() {
    _messageEntry?.remove();
    _messageEntry = null;
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF7F8FC),
        body: Column(
          children: [
            const SizedBox(height: 15),

            // البحث
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: searchController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "البحث بالاسم أو رقم الوثيقة...",
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // الفلاتر
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(filters.length, (index) {
                  final active = selectedFilter == index;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: index == filters.length - 1 ? 0 : 8,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => selectedFilter = index);
                        },
                        child: Container(
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active ? primaryBlue : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: active
                                  ? primaryBlue
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Text(
                            filters[index],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: active ? Colors.white : Colors.black87,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 15),

            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _buildDocumentsList(),
              ),
            ),
            const SizedBox(height: 15),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => showDocumentActions(context),
          backgroundColor: primaryBlue,
          shape: const CircleBorder(),
          elevation: 4,
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 32,
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  // ============================================================
  // قائمة "اختر العملية" - في منتصف الشاشة مثل الموظفين
  // ============================================================

  void showDocumentActions(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 48, vertical: 28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 315),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xffF3F4F6),
                        radius: 15,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.close,
                            size: 17,
                            color: Color(0xff4B5563),
                          ),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xffEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.edit_note,
                          color: Color(0xff2563EB),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "اختر العملية",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _documentActionButton(
                    label: "إضافة وثيقة",
                    icon: Icons.description_outlined,
                    color: primaryBlue,
                    bgColor: const Color(0xffF0F5FF),
                    onTap: () {
                      Navigator.pop(dialogContext);
                      _showDocumentForm(context);
                    },
                  ),
                  const SizedBox(height: 9),
                  _documentActionButton(
                    label: "أنواع الوثائق",
                    icon: Icons.layers_outlined,
                    color: primaryBlue,
                    bgColor: const Color(0xffF0F5FF),
                    onTap: () {
                      Navigator.pop(dialogContext);
                      showDocumentTypesDialog(context);
                    },
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffE5E7EB),
                        foregroundColor: const Color(0xff374151),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "إلغاء",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _documentActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xffE5E7EB)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 9),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // إضافة / تعديل وثيقة
  // ============================================================

  Future<void> _showDocumentForm(
    BuildContext context, {
    Map<String, dynamic>? document,
  }) async {
    final isEdit = document != null;

    final nameController =
        TextEditingController(text: document?['name']?.toString() ?? '');
    final numberController =
        TextEditingController(text: document?['number']?.toString() ?? '');
    final notesController =
        TextEditingController(text: document?['notes']?.toString() ?? '');

    String selectedType =
        document?['type']?.toString() ?? _documentTypes.first['name']!;
    String selectedIcon =
        document?['icon']?.toString() ?? _documentTypes.first['icon']!;
    String? selectedDate = document?['expiry']?.toString();

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 560,
                maxHeight: 650,
              ),
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: const Icon(
                                Icons.close,
                                size: 21,
                                color: Color(0xff64748B),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              isEdit ? "تعديل وثيقة" : "إضافة وثيقة",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff111827),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isEdit
                                  ? Icons.edit_outlined
                                  : Icons.description_outlined,
                              color: primaryBlue,
                              size: 23,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        _fieldLabel("نوع الوثيقة"),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final result = await _selectDocumentType(
                              context,
                              selectedType,
                            );
                            if (result != null) {
                              setDialogState(() {
                                selectedType = result['name']!;
                                selectedIcon = result['icon']!;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 48,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xffE5E7EB),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Color(0xff9CA3AF),
                                ),
                                const Spacer(),
                                Text(
                                  selectedType,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xff374151),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  selectedIcon,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 11),
                        _fieldLabel("اسم الوثيقة"),
                        const SizedBox(height: 6),
                        _textControllerField(
                          nameController,
                          "اسم الوثيقة",
                        ),

                        const SizedBox(height: 11),
                        _fieldLabel("رقم الوثيقة"),
                        const SizedBox(height: 6),
                        _textControllerField(
                          numberController,
                          "رقم الوثيقة",
                        ),

                        const SizedBox(height: 11),
                        _fieldLabel(
                          selectedType == 'السجل التجاري'
                              ? "موعد التأكيد السنوي *"
                              : "تاريخ الانتهاء *",
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final value = await AppDatePicker.show(
                              context,
                              initialDate:
                                  _parseDate(selectedDate) ?? DateTime.now(),
                            );
                            if (value != null) {
                              setDialogState(() => selectedDate = value);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 48,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xffE5E7EB),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                  color: Color(0xff2563EB),
                                ),
                                const Spacer(),
                                Text(
                                  _displayDate(selectedDate),
                                  style: TextStyle(
                                    color: selectedDate == null
                                        ? const Color(0xff9CA3AF)
                                        : const Color(0xff374151),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 11),
                        _fieldLabel("ملاحظات"),
                        const SizedBox(height: 6),
                        TextField(
                          controller: notesController,
                          maxLines: 3,
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            hintText: "ملاحظات",
                            hintStyle: const TextStyle(
                              color: Color(0xff9CA3AF),
                              fontSize: 12,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xffE5E7EB),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xffE5E7EB),
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),

                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xffE5E7EB),
                                    foregroundColor: const Color(0xff111827),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    "إلغاء",
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final name = nameController.text.trim();
                                    final number =
                                        numberController.text.trim();

                                    if (name.isEmpty ||
                                        number.isEmpty ||
                                        selectedDate == null) {
                                      _showMessage(
                                        "أكمل اسم الوثيقة ورقمها وتاريخ الانتهاء",
                                      );
                                      return;
                                    }

                                    if (isEdit) {
                                      final oldNumber =
                                          document!['number']?.toString() ?? '';
                                      setState(() {
                                        document['type'] = selectedType;
                                        document['icon'] = selectedIcon;
                                        document['name'] = name;
                                        document['number'] = number;
                                        document['expiry'] = selectedDate!;
                                        document['notes'] =
                                            notesController.text.trim();
                                      });
                                      _addDocumentLog(
                                        number,
                                        'تم تعديل بيانات الوثيقة',
                                      );
                                      if (oldNumber != number) {
                                        final oldLogs =
                                            _documentLogs.remove(oldNumber);
                                        if (oldLogs != null) {
                                          _documentLogs[number] = oldLogs;
                                        }
                                      }
                                      await _saveDocumentsAndRefreshAlerts();
                                      _showMessage("تم تعديل الوثيقة بنجاح");
                                    } else {
                                      final newDocument = <String, dynamic>{
                                        'type': selectedType,
                                        'icon': selectedIcon,
                                        'name': name,
                                        'number': number,
                                        'expiry': selectedDate!,
                                        'notes':
                                            notesController.text.trim(),
                                      };

                                      setState(() {
                                        _documents.add(newDocument);
                                      });

                                      _addDocumentLog(
                                        number,
                                        'تمت إضافة الوثيقة',
                                      );
                                      await _saveDocumentsAndRefreshAlerts();
                                      _showMessage("تمت إضافة الوثيقة بنجاح");
                                    }

                                    Navigator.pop(dialogContext);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.save_outlined,
                                    size: 18,
                                  ),
                                  label: Text(
                                    isEdit ? "حفظ التعديل" : "حفظ",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    nameController.dispose();
    numberController.dispose();
    notesController.dispose();
  }

  // اختيار نوع الوثيقة داخل شاشة الإضافة
  Future<Map<String, String>?> _selectDocumentType(
    BuildContext parentContext,
    String currentType,
  ) async {
    return showDialog<Map<String, String>>(
      context: parentContext,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, size: 19),
                        ),
                        const Spacer(),
                        const Text(
                          "نوع الوثيقة",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._documentTypes.map((type) {
                      final selected = type['name'] == currentType;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: InkWell(
                          onTap: () => Navigator.pop(context, type),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 48,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xffEFF6FF)
                                  : const Color(0xffFAFBFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? primaryBlue
                                    : const Color(0xffE5E7EB),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  type['icon']!,
                                  style: const TextStyle(fontSize: 19),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  type['name']!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                if (selected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xff2563EB),
                                    size: 19,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // أنواع الوثائق
  // ============================================================

  void showDocumentTypesDialog(BuildContext context) {
    final newTypeController = TextEditingController();
    String selectedIcon = "📄";

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        final screenHeight = MediaQuery.sizeOf(dialogContext).height;
        final double dialogHeight = screenHeight < 620
            ? screenHeight - 48
            : (screenHeight * 0.88).clamp(520.0, 620.0).toDouble();

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
            child: SizedBox(
              width: 500,
              height: dialogHeight,
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  return Column(
                    children: [
                      // رأس ثابت: لا يختفي مهما طال محتوى القائمة.
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 12, 8),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: 'إغلاق',
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: const Icon(
                                Icons.close,
                                size: 20,
                                color: Color(0xff64748B),
                              ),
                            ),
                            const Expanded(
                              child: Text(
                                "أنواع الوثائق",
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xff111827),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xffF1F5F9),
                      ),

                      // المحتوى فقط هو القابل للتمرير، لذلك يبقى زر الإغلاق ثابتًا.
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ..._documentTypes.map(
                                (type) => Padding(
                                  padding: const EdgeInsets.only(bottom: 7),
                                  child: docTypeCard(
                                    type['name']!,
                                    type['icon']!,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: newTypeController,
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                decoration: InputDecoration(
                                  hintText: "اكتب اسم نوع الوثيقة الجديد...",
                                  hintTextDirection: TextDirection.rtl,
                                  hintStyle: const TextStyle(
                                    color: Color(0xff9CA3AF),
                                    fontSize: 13,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xffE5E7EB),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xffE5E7EB),
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "اختر الأيقونة:",
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xff6B7280),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Wrap(
                                alignment: WrapAlignment.end,
                                spacing: 7,
                                runSpacing: 7,
                                children: [
                                  "💰",
                                  "🏢",
                                  "🛡️",
                                  "🤝",
                                  "📄",
                                  "📁",
                                  "🏷️",
                                  "📌",
                                  "🏆",
                                ].map((emoji) {
                                  final selected = selectedIcon == emoji;
                                  return InkWell(
                                    onTap: () {
                                      setDialogState(
                                        () => selectedIcon = emoji,
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 46,
                                      height: 42,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? primaryBlue
                                            : const Color(0xffF8FAFC),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                          color: selected
                                              ? primaryBlue
                                              : const Color(0xffE5E7EB),
                                        ),
                                      ),
                                      child: Text(
                                        emoji,
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // أزرار ثابتة في أسفل النافذة.
                      Container(
                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Color(0xffF1F5F9)),
                          ),
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final name = newTypeController.text.trim();
                                  if (name.isEmpty) {
                                    _showMessage("اكتب اسم نوع الوثيقة أولاً");
                                    return;
                                  }

                                  final exists = _documentTypes.any(
                                    (type) =>
                                        type['name']?.trim().toLowerCase() ==
                                        name.toLowerCase(),
                                  );

                                  if (exists) {
                                    _showMessage("نوع الوثيقة موجود بالفعل");
                                    return;
                                  }

                                  setState(() {
                                    _documentTypes.add({
                                      'name': name,
                                      'icon': selectedIcon,
                                    });
                                  });

                                  newTypeController.clear();
                                  setDialogState(() {});
                                  await _saveDocumentsAndRefreshAlerts();
                                  _showMessage("تمت إضافة نوع الوثيقة");
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff8AAAE5),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text(
                                  "إضافة نوع جديد",
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff1E293B),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "إغلاق",
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    ).then((_) => newTypeController.dispose());
  }

  Widget docTypeCard(String title, String emoji) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xffFAFBFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          SizedBox(
            width: 34,
            child: Text(
              emoji,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff111827),
                  ),
                ),
                Text(
                  title,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xff9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // إجراءات الوثيقة: السجل / تعديل / تجديد / حذف
  // ============================================================

  void _showDocumentActions(
    BuildContext context,
    Map<String, dynamic> document,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 52, vertical: 30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 315),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xffF3F4F6),
                        radius: 15,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.close,
                            size: 17,
                            color: const Color(0xff4B5563),
                          ),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xffEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.edit_note,
                          color: Color(0xff2563EB),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    "إجراءات الوثيقة",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    document['name']?.toString() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xff6B7280),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // نفس ترتيب الموظفين: سجل / تعديل
                  Row(
                    children: [
                      Expanded(
                        child: _actionButton(
                          label: "السجل",
                          icon: Icons.visibility_outlined,
                          color: const Color(0xff2563EB),
                          bgColor: const Color(0xffF0F5FF),
                          onTap: () {
                            Navigator.pop(dialogContext);
                            _showDocumentLogs(context, document);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _actionButton(
                          label: "تعديل",
                          icon: Icons.edit_outlined,
                          color: const Color(0xff2563EB),
                          bgColor: const Color(0xffF0F5FF),
                          onTap: () {
                            Navigator.pop(dialogContext);
                            _showDocumentForm(context, document: document);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // نفس ترتيب الموظفين: تجديد / حذف
                  Row(
                    children: [
                      Expanded(
                        child: _actionButton(
                          label: "تجديد",
                          icon: Icons.autorenew,
                          color: const Color(0xff16A34A),
                          bgColor: const Color(0xffF0FDF4),
                          onTap: () {
                            Navigator.pop(dialogContext);
                            _showRenewDocument(context, document);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _actionButton(
                          label: "حذف",
                          icon: Icons.delete_outline,
                          color: const Color(0xffDC2626),
                          bgColor: const Color(0xffFEF2F2),
                          onTap: () {
                            Navigator.pop(dialogContext);
                            _confirmDeleteDocument(context, document);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111827),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "إغلاق",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xffE5E7EB),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color == const Color(0xffDC2626)
                    ? const Color(0xffDC2626)
                    : Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // سجل الوثيقة
  // ============================================================

  void _showDocumentLogs(
    BuildContext context,
    Map<String, dynamic> document,
  ) {
    final number = document['number']?.toString() ?? '';
    final logs = List<String>.from(_documentLogs[number] ?? []);

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 360, maxHeight: 500),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xffF3F4F6),
                        radius: 16,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xffEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.history,
                          color: Color(0xff2563EB),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "سجل الوثيقة",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    document['name']?.toString() ?? '',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    child: logs.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                "لا يوجد سجل سابق لهذه الوثيقة",
                                style: TextStyle(
                                  color: Color(0xff9CA3AF),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: logs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 7),
                            itemBuilder: (_, index) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(
                                  color: const Color(0xffF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xffE5E7EB),
                                  ),
                                ),
                                child: Text(
                                  logs[index],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xff374151),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xffF3F4F6),
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "إغلاق",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _addDocumentLog(String number, String message) {
    final now = DateTime.now();
    final timestamp =
        '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    _documentLogs.putIfAbsent(number, () => []);
    _documentLogs[number]!.insert(0, '$message — $timestamp');
  }

  // ============================================================
  // التجديد - بنفس شكل الصورة المرفقة
  // ============================================================

  Future<void> _showRenewDocument(
    BuildContext context,
    Map<String, dynamic> document,
  ) async {
    int years = 1;
    bool manualDate = false;
    String? newDate = _calculateDocumentRenewal(
      document['expiry']?.toString() ?? '',
      years,
    );

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            // لا نعيد حساب التاريخ إذا اختاره المستخدم يدويًا.
            if (!manualDate) {
              newDate = _calculateDocumentRenewal(
                document['expiry']?.toString() ?? '',
                years,
              );
            }

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                insetPadding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xffF3F4F6),
                              radius: 18,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.close,
                                  size: 17,
                                  color: Colors.grey,
                                ),
                                onPressed: () =>
                                    Navigator.pop(dialogContext),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: const Color(0xffF0FDF4),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(
                                Icons.autorenew,
                                color: Color(0xff16A34A),
                                size: 23,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          document['type']?.toString() == 'السجل التجاري'
                              ? "التأكيد السنوي"
                              : "تجديد الوثيقة",
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff111827),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          document['name']?.toString() ?? '',
                          style: const TextStyle(
                            color: Color(0xff6B7280),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // تاريخ الانتهاء الحالي والجديد
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xffF8FAFC),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: const Color(0xffE2E8F0),
                            ),
                          ),
                          child: Column(
                            children: [
                              _renewRow(
                                document['type']?.toString() == 'السجل التجاري'
                                    ? "موعد التأكيد الحالي:"
                                    : "الانتهاء الحالي:",
                                _displayDate(
                                  document['expiry']?.toString(),
                                ),
                                const Color(0xff6B7280),
                              ),
                              const SizedBox(height: 9),
                              _renewRow(
                                document['type']?.toString() == 'السجل التجاري'
                                    ? "موعد التأكيد الجديد:"
                                    : "الانتهاء الجديد:",
                                _displayDate(newDate),
                                manualDate
                                    ? const Color(0xff16A34A)
                                    : primaryBlue,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            document['type']?.toString() == 'السجل التجاري'
                                ? "التأكيد السنوي للسجل التجاري"
                                : "مدة التجديد",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xff111827),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (document['type']?.toString() == 'السجل التجاري')
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xffEFF6FF),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: const Color(0xffDBEAFE),
                              ),
                            ),
                            child: const Text(
                              "وفق نظام السجل التجاري الجديد: لا يوجد تاريخ انتهاء للسجل التجاري، ويكون الإجراء هو التأكيد السنوي للبيانات كل 12 شهراً من تاريخ القيد.",
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: Color(0xff1E40AF),
                                fontSize: 11,
                                height: 1.5,
                              ),
                            ),
                          )
                        else ...[
                          Row(
                            children: [
                              Expanded(
                                child: _yearChoice(
                                  label: "سنة واحدة",
                                  value: 1,
                                  selected: years == 1 && !manualDate,
                                  onTap: () {
                                    setDialogState(() {
                                      years = 1;
                                      manualDate = false;
                                      newDate = _calculateDocumentRenewal(
                                        document['expiry']?.toString() ?? '',
                                        years,
                                      );
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _yearChoice(
                                  label: "سنتان",
                                  value: 2,
                                  selected: years == 2 && !manualDate,
                                  onTap: () {
                                    setDialogState(() {
                                      years = 2;
                                      manualDate = false;
                                      newDate = _calculateDocumentRenewal(
                                        document['expiry']?.toString() ?? '',
                                        years,
                                      );
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _yearChoice(
                                  label: "3 سنوات",
                                  value: 3,
                                  selected: years == 3 && !manualDate,
                                  onTap: () {
                                    setDialogState(() {
                                      years = 3;
                                      manualDate = false;
                                      newDate = _calculateDocumentRenewal(
                                        document['expiry']?.toString() ?? '',
                                        years,
                                      );
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _yearChoice(
                                  label: "5 سنوات",
                                  value: 5,
                                  selected: years == 5 && !manualDate,
                                  onTap: () {
                                    setDialogState(() {
                                      years = 5;
                                      manualDate = false;
                                      newDate = _calculateDocumentRenewal(
                                        document['expiry']?.toString() ?? '',
                                        years,
                                      );
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: const Text(
                            "تعديل تاريخ التجديد",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff111827),
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        InkWell(
                          onTap: () async {
                            final picked = await AppDatePicker.show(
                              context,
                              initialDate:
                                  _parseDate(newDate) ?? DateTime.now(),
                            );

                            if (picked != null) {
                              setDialogState(() {
                                manualDate = true;
                                newDate = picked;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(13),
                          child: Container(
                            width: double.infinity,
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: manualDate
                                  ? const Color(0xffF0FDF4)
                                  : const Color(0xffF8FAFC),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: manualDate
                                    ? const Color(0xff86EFAC)
                                    : const Color(0xffE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_month_outlined,
                                  size: 20,
                                  color: manualDate
                                      ? const Color(0xff16A34A)
                                      : primaryBlue,
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    manualDate
                                        ? 'تم اختيار تاريخ مخصص'
                                        : 'اختيار تاريخ التجديد يدويًا',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: manualDate
                                          ? const Color(0xff15803D)
                                          : const Color(0xff475569),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _displayDate(newDate),
                                  style: TextStyle(
                                    color: manualDate
                                        ? const Color(0xff15803D)
                                        : primaryBlue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final expiry = newDate;
                                    if (expiry == null) {
                                      _showMessage(
                                        "تعذر تحديد تاريخ التجديد",
                                      );
                                      return;
                                    }

                                    setState(() {
                                      document['expiry'] = expiry;
                                    });

                                    final number =
                                        document['number']?.toString() ?? '';

                                    _addDocumentLog(
                                      number,
                                      document['type']?.toString() == 'السجل التجاري'
                                          ? 'تم التأكيد السنوي لبيانات السجل التجاري حتى ${_displayDate(expiry)}'
                                          : manualDate
                                              ? 'تم تعديل تاريخ تجديد الوثيقة يدويًا إلى ${_displayDate(expiry)}'
                                              : 'تم تجديد الوثيقة لمدة $years '
                                                '${years == 1 ? 'سنة' : 'سنوات'} '
                                                'حتى ${_displayDate(expiry)}',
                                    );

                                    await _saveDocumentsAndRefreshAlerts();

                                    if (!dialogContext.mounted) return;
                                    Navigator.pop(dialogContext);
                                    _showMessage(
                                      document['type']?.toString() == 'السجل التجاري'
                                          ? "تم تحديث موعد التأكيد السنوي بنجاح"
                                          : "تم تجديد الوثيقة بنجاح",
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    "تأكيد التجديد",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext),
                                  style: TextButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xffF3F4F6),
                                    foregroundColor: Colors.black87,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    "إلغاء",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _yearChoice({
    required String label,
    required int value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected
                ? primaryBlue
                : const Color(0xffE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xff111827),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _renewRow(String title, String value, Color valueColor) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xff6B7280),
              fontSize: 11,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  String? _calculateDocumentRenewal(String current, int years) {
    final start = _parseDate(current);
    if (start == null) return null;

    final target = DateTime(
      start.year + years,
      start.month,
      start.day,
    );

    // معالجة 29 فبراير إذا لم تكن السنة الجديدة كبيسة.
    if (target.month != start.month) {
      return '${target.year.toString().padLeft(4, '0')}-'
          '${start.month.toString().padLeft(2, '0')}-'
          '${DateTime(target.year, start.month + 1, 0).day.toString().padLeft(2, '0')}';
    }

    return _dateToStorage(target);
  }

  // ============================================================
  // حذف - نفس فكرة الموظفين والزيارات
  // ============================================================

  Future<void> _confirmDeleteDocument(
    BuildContext context,
    Map<String, dynamic> document,
  ) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: "تأكيد حذف الوثيقة",
      message:
          "هل أنت متأكد من حذف الوثيقة؟\n${document['name'] ?? ''}",
      confirmText: "حذف نهائي",
    );

    if (!confirmed || !context.mounted) return;

    final number = document['number']?.toString() ?? '';

    setState(() {
      _documents.remove(document);
    });

    _documentLogs.remove(number);
    await _saveDocumentsAndRefreshAlerts();

    if (!context.mounted) return;
    _showMessage("تم حذف الوثيقة من القائمة بنجاح");
  }

  // ============================================================
  // قائمة الوثائق - بنفس ترتيب الصورة:
  // اسم الوثيقة | رقم الوثيقة | الحالة
  // ============================================================

  Widget _buildDocumentsList() {
    final query = searchController.text.trim().toLowerCase();

    final filtered = _documents.where((document) {
      final matchesSearch = query.isEmpty ||
          (document['name']?.toString() ?? '').toLowerCase().contains(query) ||
          (document['number']?.toString() ?? '').toLowerCase().contains(query) ||
          (document['type']?.toString() ?? '').toLowerCase().contains(query);

      if (!matchesSearch) return false;

      final days = _daysRemaining(document['expiry']?.toString());

      if (selectedFilter == 0) return true;
      if (selectedFilter == 1) return days >= 0 && days > 30;
      if (selectedFilter == 2) return days >= 0 && days <= 30;
      if (selectedFilter == 3) return days < 0;

      return true;
    }).toList();

    // ترتيب الوثائق حسب المدة المتبقية: الأقرب انتهاءً أولاً.
    filtered.sort((a, b) {
      final daysA = _daysRemaining(a['expiry']?.toString());
      final daysB = _daysRemaining(b['expiry']?.toString());
      return daysA.compareTo(daysB);
    });

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          "لا توجد وثائق مسجلة",
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: filtered.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildDocumentsHeader();
        }

        final document = filtered[index - 1];
        return _buildDocumentRow(document);
      },
    );
  }

  Widget _buildDocumentsHeader() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xffF7F8FC),
      child: Row(
        children: const [
          Expanded(
            flex: 4,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                "اسم الوثيقة",
                textAlign: TextAlign.right,
                style: TextStyle(
                color: Color(0xff6B7280),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              "رقم الوثيقة",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xff6B7280),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "الحالة",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xff6B7280),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(Map<String, dynamic> document) {
    final days = _daysRemaining(document['expiry']?.toString());
    final status = _documentStatus(days);
    final statusColor = _statusColor(status);
    final statusBg = _statusBackground(status);

    return InkWell(
      // فتح إجراءات الوثيقة بالضغط المطول فقط.
      onTap: () => _showDocumentActions(context, document),
      child: Container(
        constraints: const BoxConstraints(minHeight: 82),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Color(0xffE5E7EB),
              width: 0.8,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // اسم الوثيقة - نفس محاذاة عنوان العمود تماماً (يمين)
            Expanded(
              flex: 4,
              child: Align(
                alignment: Alignment.centerRight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // منطقة ثابتة العرض حتى تكون أسماء جميع الوثائق على
                    // نفس المحور، بغض النظر عن طول اسم الوثيقة.
                    SizedBox(
                      width: 210,
                      child: Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Expanded(
                            child: Text(
                              document['name']?.toString() ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: Color(0xff111827),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 28,
                            child: Text(
                              document['icon']?.toString() ?? '📄',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 19),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      width: 210,
                      child: Text(
                        '${document['type']?.toString() == 'السجل التجاري' ? 'التأكيد السنوي' : 'الانتهاء'}: ${_displayDate(document['expiry']?.toString())}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Color(0xff6B7280),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // رقم الوثيقة - الوسط
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  document['number']?.toString().isNotEmpty == true
                      ? document['number'].toString()
                      : '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xff111827),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // الحالة - اليسار
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          status,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (days >= 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'متبقي $days يوم',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xff6B7280),
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _documentStatus(int days) {
    if (days < 0) return "منتهي";
    if (days <= 30) return "تحتاج متابعة";
    return "نشط";
  }

  Color _statusColor(String status) {
    if (status == "منتهي") return const Color(0xffC62828);
    if (status == "تحتاج متابعة") return const Color(0xffD97706);
    return const Color(0xff16A34A);
  }

  Color _statusBackground(String status) {
    if (status == "منتهي") return const Color(0xffFFEBEE);
    if (status == "تحتاج متابعة") return const Color(0xffFFF7ED);
    return const Color(0xffF0FDF4);
  }

  int _daysRemaining(String? value) {
    final date = _parseDate(value);
    if (date == null) return 0;

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    return dateOnly.difference(todayOnly).inDays;
  }

  String _displayDate(String? value) {
    if (value == null || value.trim().isEmpty) return "DD-MM-YYYY";

    final date = _parseDate(value);
    if (date == null) return value;

    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year.toString().padLeft(4, '0')}';
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final text = value.trim();

    final iso = DateTime.tryParse(text);
    if (iso != null) {
      return DateTime(iso.year, iso.month, iso.day);
    }

    final parts = text.split('-');
    if (parts.length == 3) {
      final first = int.tryParse(parts[0]);
      final second = int.tryParse(parts[1]);
      final third = int.tryParse(parts[2]);

      if (first != null && second != null && third != null) {
        // dd-MM-yyyy
        if (third > 1900) {
          return DateTime(third, second, first);
        }
        // yyyy-MM-dd
        if (first > 1900) {
          return DateTime(first, second, third);
        }
      }
    }

    return null;
  }

  String _dateToStorage(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      textAlign: TextAlign.right,
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xff6B7280),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _textControllerField(
    TextEditingController controller,
    String hint,
  ) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xff9CA3AF),
          fontSize: 12,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xffE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xffE5E7EB)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }

  Future<void> _showMessage(String message) async {
    if (!mounted) return;

    _messageEntry?.remove();
    _messageEntry = null;

    final overlay = Overlay.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        return Positioned(
          top: topPadding + 10,
          left: 16,
          right: 16,
          child: SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: -1, end: 0),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, value * 85),
                    child: child,
                  );
                },
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 520),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xffE2E8F0),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x240F172A),
                          blurRadius: 24,
                          spreadRadius: 1,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: IntrinsicHeight(
                        child: Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Container(
                              width: 5,
                              color: const Color(0xff16A34A),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xffDCFCE7),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        color: Color(0xff16A34A),
                                        size: 23,
                                      ),
                                    ),
                                    const SizedBox(width: 11),
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          const Text(
                                            "تمت العملية بنجاح",
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                              color: Color(0xff0F172A),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            message,
                                            textAlign: TextAlign.right,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xff64748B),
                                              fontSize: 11.5,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      tooltip: "إغلاق",
                                      onPressed: () {
                                        _messageEntry?.remove();
                                        _messageEntry = null;
                                      },
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        color: Color(0xff94A3B8),
                                        size: 19,
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
                ),
              ),
            ),
          ),
        );
      },
    );

    _messageEntry = entry;
    overlay.insert(entry);

    await Future.delayed(const Duration(seconds: 3));

    if (identical(_messageEntry, entry)) {
      entry.remove();
      _messageEntry = null;
    }
  }

}
