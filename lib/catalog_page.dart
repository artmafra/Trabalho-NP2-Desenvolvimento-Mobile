import 'package:flutter/material.dart';

import 'cantina_product.dart';
import 'order_form_page.dart';
import 'orders_page.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  String _category = 'Todos';

  List<CantinaProduct> get _visibleProducts => _category == 'Todos'
      ? cantinaProducts
      : cantinaProducts
            .where((product) => product.category == _category)
            .toList();

  void _order(CantinaProduct product) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => OrderFormPage(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cantina do Campus'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            tooltip: 'Acompanhar pedidos',
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const OrdersPage()),
            ),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CantinaBanner(onOrder: () => _order(cantinaProducts.first)),
            const SizedBox(height: 22),
            Text(
              'Bateu a fome?',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Escolha seu lanche e receba no campus.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: ['Todos', 'Lanches', 'Bebidas']
                  .map(
                    (category) => ChoiceChip(
                      label: Text(category),
                      selected: _category == category,
                      onSelected: (_) => setState(() => _category = category),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            ..._visibleProducts.map(
              (product) => _ProductCard(
                product: product,
                onOrder: () => _order(product),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(builder: (_) => const OrdersPage()),
                ),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Ver pedidos enviados'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CantinaBanner extends StatelessWidget {
  const _CantinaBanner({required this.onOrder});

  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 188,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              cantinaProducts.first.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Image.asset(
                'assets/cantina_placeholder.png',
                fit: BoxFit.cover,
              ),
            ),
            Container(color: Colors.black.withValues(alpha: 0.45)),
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pausa gostosa, sem sair do campus',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Seu intervalo merece esse capricho.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filled(
                    tooltip: 'Pedir agora',
                    onPressed: onOrder,
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onOrder});

  final CantinaProduct product;
  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.network(
            product.imageUrl,
            height: 155,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Image.asset(
              'assets/cantina_placeholder.png',
              height: 155,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 12, 15, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'R\$ ${product.price.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onOrder,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Pedir'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
