class CantinaProduct {
  const CantinaProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.category,
  });

  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final String category;
}

const cantinaProducts = <CantinaProduct>[
  CantinaProduct(
    id: 'x-burguer',
    name: 'X-Burguer da Casa',
    description: 'Hambúrguer artesanal, queijo, alface e molho especial.',
    imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=1000',
    price: 22.90,
    category: 'Lanches',
  ),
  CantinaProduct(
    id: 'misto-quente',
    name: 'Misto Quente',
    description: 'Pão tostado, queijo derretido e presunto.',
    imageUrl: 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=1000',
    price: 12.00,
    category: 'Lanches',
  ),
  CantinaProduct(
    id: 'pizza-fatia',
    name: 'Fatia de Pizza',
    description: 'Massa da casa com queijo e tomate fresquinho.',
    imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=1000',
    price: 14.50,
    category: 'Lanches',
  ),
  CantinaProduct(
    id: 'suco-laranja',
    name: 'Suco de Laranja',
    description: 'Suco natural, feito na hora.',
    imageUrl: 'https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=1000',
    price: 8.00,
    category: 'Bebidas',
  ),
  CantinaProduct(
    id: 'cafe-gelado',
    name: 'Café Gelado',
    description: 'Café da cantina com leite e gelo.',
    imageUrl: 'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?w=1000',
    price: 9.50,
    category: 'Bebidas',
  ),
];
