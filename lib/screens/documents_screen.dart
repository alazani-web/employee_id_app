import 'package:flutter/material.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  int selectedFilter = 0;
  final TextEditingController searchController = TextEditingController();

  // اللون الأزرق الرئيسي الموحد
  final Color primaryBlue = const Color(0xff2563EB);

  final List<String> filters = [
    "الكل",
    "نشط",
    "تنتهي قريباً",
    "منتهي",
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF7F8FC),
        body: Column(
          children: [
            const SizedBox(height: 15),

            // شريط البحث
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

            // الفلاتر (تم تحديث اللون الأزرق هنا)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(filters.length, (index) {
                  bool active = selectedFilter == index;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: index == filters.length - 1 ? 0 : 8.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedFilter = index;
                          });
                        },
                        child: Container(
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active ? primaryBlue : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: active ? primaryBlue : Colors.grey.shade200,
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

            // قائمة الوثائق الخالية
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    "لا توجد وثائق مسجلة",
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
          ],
        ),

        // زر (+) (تم تحديث اللون الأزرق هنا)
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

  // نافذة اختر العملية
  void showDocumentActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  "اختر العملية",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                actionCard(
                  icon: Icons.article_outlined,
                  title: "إضافة وثيقة",
                  subtitle: "إضافة وثيقة جديدة إلى النظام",
                  bgColor: const Color(0xffF0F5FF),
                  iconColor: primaryBlue,
                  onTap: () {
                    Navigator.pop(context);
                    showAddDocumentDialog(context);
                  },
                ),
                const SizedBox(height: 12),
                actionCard(
                  icon: Icons.layers_outlined,
                  title: "أنواع الوثائق",
                  subtitle: "إضافة أنواع الوثائق المخصصة",
                  bgColor: const Color(0xffF0F5FF),
                  iconColor: primaryBlue,
                  onTap: () {
                    Navigator.pop(context);
                    showDocumentTypesDialog(context);
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff1E293B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text("إلغاء", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  void showAddDocumentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 20, color: Colors.black54),
                      ),
                      Row(
                        children: [
                          const Text("إضافة وثيقة", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 6),
                          Icon(Icons.article_outlined, color: primaryBlue, size: 20),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  const Text("نوع الوثيقة", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                        Row(
                          children: [
                            Text("أخرى", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            SizedBox(width: 6),
                            Text("📁", style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Text("اسم الوثيقة", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 6),
                  customTextField("اسم الوثيقة"),

                  const SizedBox(height: 12),
                  const Text("رقم الوثيقة", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 6),
                  customTextField("رقم الوثيقة"),

                  const SizedBox(height: 12),
                  const Text("تاريخ الانتهاء *", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 6),
                  customDateField(),

                  const SizedBox(height: 12),
                  const Text("ملاحظات", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const TextField(
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "ملاحظات",
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade200,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("إلغاء", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.save_outlined, color: Colors.white, size: 18),
                            label: const Text("حفظ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showDocumentTypesDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            margin: const EdgeInsets.only(top: 60),
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("أنواع الوثائق", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 20, color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  docTypeCard("السجل التجاري", "🏢"),
                  docTypeCard("الرخصة", "📄"),
                  docTypeCard("التأمين", "🛡️"),
                  docTypeCard("أخرى", "📁"),

                  const SizedBox(height: 15),
                  customTextField("اكتب اسم نوع الوثيقة الجديد..."),
                  const SizedBox(height: 12),

                  const Text("اختر الأيقونة:", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      emojiTile("💰", false),
                      emojiTile("🏢", false),
                      emojiTile("🛡️", false),
                      emojiTile("🤝", false),
                      emojiTile("📄", true),
                      emojiTile("📁", false),
                      emojiTile("🏷️", false),
                      emojiTile("📌", false),
                      emojiTile("🏆", false),
                    ],
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff8AAAE5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add, color: Colors.white, size: 18),
                      label: const Text("إضافة نوع جديد", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff1E293B),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("إغلاق", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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

  Widget docTypeCard(String title, String emoji) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget emojiTile(String emoji, bool isSelected) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? primaryBlue : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 18)),
    );
  }

  Widget customTextField(String hint) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Widget customDateField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: "DD-MM-YYYY",
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}