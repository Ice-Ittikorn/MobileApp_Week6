class Item {
  final String id;
  final String title;
  final double price;

  const Item({required this.id, required this.title, required this.price});
}

final catalog = <Item>[
  const Item(id: 'i1', title: 'หนังสือ Calculus มือสอง', price: 150),
  const Item(id: 'i2', title: 'หูฟังไร้สาย (สภาพดี 90%)', price: 450),
  const Item(id: 'i3', title: 'โคมไฟตั้งโต๊ะหอพัก', price: 120),
];
