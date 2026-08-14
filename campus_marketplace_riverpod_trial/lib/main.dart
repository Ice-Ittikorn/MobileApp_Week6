import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'item.dart';
import 'favorites_notifier.dart';

void main() {
  // ครอบแอปทั้งหมดด้วย ProviderScope เพียงครั้งเดียวที่จุดเริ่มต้น เทียบเท่า ChangeNotifierProvider
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(
    debugShowCheckedModeBanner:
        false, // ปิดริบบิ้น DEBUG มุมขวาบน ไม่ให้บังไอคอนหัวใจใน AppBar
    home: HomePage(),
  );
}

// ใช้ ConsumerWidget แทน StatelessWidget เพื่อรับพารามิเตอร์ "ref" เข้ามาใน build()
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch อ่านค่าปัจจุบันและสมัครรับการอัปเดตอัตโนมัติ เทียบเท่า context.watch
    final savedItems = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: Text('❤️ ${savedItems.length}')),
      body: ListView(
        children: catalog
            .map(
              (item) => ListTile(
                title: Text(item.title),
                trailing: ElevatedButton(
                  // ref.read(...notifier) ใช้เรียกแก้ไขค่า เทียบเท่า context.read
                  onPressed: () =>
                      ref.read(favoritesProvider.notifier).add(item),
                  child: const Text('บันทึก'),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
