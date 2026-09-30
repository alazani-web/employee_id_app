import 'package:flutter/material.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  int selectedFilter = 0;
  final TextEditingController searchController = TextEditingController();

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
        backgroundColor: Colors.white,
        body: Column(
          children: [
            const SizedBox(height: 15),

            // البحث
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: TextField(
                controller: searchController,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "البحث بالاسم أو رقم الهوية...",
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // الفلاتر معدلة متطابقة مع شاشة الزيارات
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(filters.length, (index) {
                  bool active = selectedFilter == index;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: index == filters.length - 1 ? 0 : 8.0,
                      ),
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
                            color: active ? const Color(0xff2962C7) : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: active ? const Color(0xff2962C7) : Colors.grey.shade200,
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

            // عناوين الجدول
            Container(
              height: 45,
              color: const Color(0xffEEF1F7),
              child: const Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        "اسم الموظف",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "رقم الهوية",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "الحالة",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "لا يوجد موظفين مسجلين",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // زر (+) في أقصى اليسار
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showEmployeeActions(context);
          },
          backgroundColor: const Color(0xff0d47a1),
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

  void showEmployeeActions(BuildContext context) {
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
              borderRadius: BorderRadius.all(
                Radius.circular(28),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xffF3F5FA),
                      child: IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ),
                    const Text(
                      "اختر العملية",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                actionCard(
                  icon: Icons.person_add_alt_1,
                  title: "إضافة موظف",
                  subtitle: "إضافة موظف جديد إلى النظام",
                  onTap: () {
                    Navigator.pop(context);
                    showAddEmployeeDialog(context);
                  },
                ),
                const SizedBox(height: 15),
                actionCard(
                  icon: Icons.upload_file,
                  title: "استيراد موظفين",
                  subtitle: "استيراد موظفين من ملف بيانات",
                  onTap: () {
                    Navigator.pop(context);
                    showImportExcelDialog(context);
                  },
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff101828),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "إغلاق",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
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
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: const Color(0xffF1F5FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: const Color(0xff2962C7),
                size: 28,
              ),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void showAddEmployeeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey.shade100,
                        radius: 18,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                        ),
                      ),
                      const Text(
                        "إضافة موظف جديد",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "اسم الموظف",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: "أدخل اسم الموظف...",
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "رقم الهوية / الإقامة",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "أدخل رقم الهوية...",
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "تاريخ انتهاء الإقامة",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: "DD-MM-YYYY",
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                        prefixIcon: Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xff2962C7)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff2962C7),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "حفظ",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xfff5f7fa),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "إلغاء",
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
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
        );
      },
    );
  }

  void showImportExcelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey.shade100,
                        radius: 18,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                        ),
                      ),
                      const Text(
                        "استيراد الموظفين من Excel",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "قم بتحميل ملف Excel أو CSV يحتوي على بيانات الموظفين",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xfff0f4fd),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.file_download_outlined, color: Color(0xff2962C7), size: 18),
                          SizedBox(width: 6),
                          Text(
                            "تحميل قالب استيراد الموظفين",
                            style: TextStyle(
                              color: Color(0xff2962C7),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xfffafbfc),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.blue.shade100,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.file_upload_outlined,
                          size: 38,
                          color: Color(0xff2962C7),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "اسحب وأفلت ملف الموظفين هنا",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "أو",
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff2962C7),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          icon: const Icon(Icons.insert_drive_file_outlined, size: 16, color: Colors.white),
                          label: const Text(
                            "اختر ملف",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xfff7f9fc),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "متطلبات ملف الموظفين:",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff1d5cc8),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text("•  الاسم الكامل (اسم الموظف)", style: TextStyle(fontSize: 11, color: Colors.grey)),
                        SizedBox(height: 2),
                        Text("•  رقم الهوية / رقم الإقامة", style: TextStyle(fontSize: 11, color: Colors.grey)),
                        SizedBox(height: 2),
                        Text("•  تاريخ انتهاء الهوية (بالتنسيق الصحيح)", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
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
}