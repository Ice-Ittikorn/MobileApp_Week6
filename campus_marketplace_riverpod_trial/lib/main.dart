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

// HomePage ไม่ต้องเก็บ state เอง แค่ต้องอ่าน favoritesProvider จึงใช้ ConsumerWidget
// (StatelessWidget รุ่นที่มี ref) ส่วนคำค้นหาซึ่งเป็น Ephemeral State ถูกยกให้
// _SearchField ด้านล่างซึ่งเป็น StatefulWidget/State ธรรมดา (ไม่ผูกกับ Riverpod)
// เป็นผู้ดูแลเอง แล้วส่งค่าขึ้นมาผ่าน callback เพื่อกรองรายการเท่านั้น
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    // ref.watch อ่านค่าปัจจุบันและสมัครรับการอัปเดตอัตโนมัติ เทียบเท่า context.watch
    final savedItems = ref.watch(favoritesProvider);

    final filteredItems = catalog
        .where(
          (item) =>
              item.title.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('❤️ ${savedItems.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FavoritesPage()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchField(onChanged: (value) => setState(() => _query = value)),
          Expanded(child: ItemListSection(items: filteredItems)),
        ],
      ),
    );
  }
}

// เหมือนกับ HomePage: ใช้ ConsumerStatefulWidget เพราะต้องอ่าน favoritesProvider
// (ref) และคำค้นหาของหน้านี้เป็น Ephemeral State ของหน้านี้เองเช่นเดียวกัน
class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  String _query = '';

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ล้างรายการโปรดทั้งหมด?'),
        content: const Text('การกระทำนี้จะลบรายการโปรดทั้งหมดออก และไม่สามารถย้อนกลับได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ล้างทั้งหมด'),
          ),
        ],
      ),
    );

    // ยืนยันแล้วค่อยสั่งแก้ state จริง (ref.read เพราะเป็นการสั่งครั้งเดียว ไม่ต้อง rebuild ตาม)
    if (confirmed == true) {
      ref.read(favoritesProvider.notifier).clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ref.watch เพราะหน้านี้ต้อง rebuild ตามจำนวนรายการโปรดที่เปลี่ยนไป
    // (ทั้งตัวลิสต์ที่แสดง และเงื่อนไขว่าจะโชว์ปุ่มล้างรายการหรือไม่ ซึ่งอิงจากลิสต์เต็ม ไม่ใช่ลิสต์ที่กรองแล้ว)
    final savedItems = ref.watch(favoritesProvider);

    final filteredItems = savedItems
        .where(
          (item) =>
              item.title.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการโปรด'),
        actions: [
          if (savedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'ล้างรายการโปรดทั้งหมด',
              onPressed: () => _confirmClear(context, ref),
            ),
        ],
      ),
      body: savedItems.isEmpty
          ? const Center(child: Text('ยังไม่มีรายการโปรด'))
          : Column(
              children: [
                _SearchField(
                  onChanged: (value) => setState(() => _query = value),
                ),
                Expanded(
                  child: ListView(
                    children: filteredItems
                        .map(
                          (item) => ListTile(
                            title: Text(item.title),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => ref
                                  .read(favoritesProvider.notifier)
                                  .remove(item),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
    );
  }
}

// Ephemeral State แบบ setState ธรรมดา: ตัว TextEditingController และค่าที่พิมพ์
// เป็นสถานะภายในของกล่องค้นหานี้เท่านั้น จึงใช้ StatefulWidget/State ปกติ
// ไม่เกี่ยวข้องกับ Riverpod เลย แค่แจ้งค่าออกไปให้ parent ผ่าน onChanged
class _SearchField extends StatefulWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'ค้นหาสินค้า...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

class ItemListSection extends ConsumerWidget {
  const ItemListSection({super.key, required this.items});

  final List<Item> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      children: items
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
    );
  }
}
