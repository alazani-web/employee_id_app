import 'package:flutter/material.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'أرشفة وثائق الشركة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.upload_file, color: Colors.white, size: 18),
                  label: const Text('رفع وثيقة', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: const [
                  DocItemCard(title: 'عقد الإيجار الرئيسي', type: 'PDF', date: '2026-01-10'),
                  DocItemCard(title: 'السجل التجاري', type: 'PDF', date: '2026-03-15'),
                  DocItemCard(title: 'رخصة البلديّة', type: 'Image', date: '2026-05-20'),
                  DocItemCard(title: 'التأمينات الاجتماعية', type: 'PDF', date: '2026-02-01'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DocItemCard extends StatelessWidget {
  final String title;
  final String type;
  final String date;

  const DocItemCard({super.key, required this.title, required this.type, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.folder_open, color: Colors.purple, size: 28),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(4)),
                child: Text(type, style: const TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Spacer(),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('تاريخ الرفع: $date', style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}