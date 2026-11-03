import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'cantina_product.dart';

enum OrderSize { pequeno, medio, grande }

extension OrderSizeLabel on OrderSize {
  String get label => switch (this) {
    OrderSize.pequeno => 'Pequeno',
    OrderSize.medio => 'Médio',
    OrderSize.grande => 'Grande',
  };

  double get priceAdjustment => switch (this) {
    OrderSize.pequeno => -2.00,
    OrderSize.medio => 0,
    OrderSize.grande => 4.00,
  };
}

enum DeliveryType { campus, outsideCampus }

extension DeliveryTypeLabel on DeliveryType {
  String get label => switch (this) {
    DeliveryType.campus => 'No campus',
    DeliveryType.outsideCampus => 'Fora do campus',
  };
}

class OrderFormPage extends StatefulWidget {
  const OrderFormPage({super.key, required this.product});

  final CantinaProduct product;

  @override
  State<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends State<OrderFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _campusLocationController = TextEditingController();
  final _cepController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _complementController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  OrderSize _size = OrderSize.medio;
  DeliveryType _deliveryType = DeliveryType.campus;
  final Set<String> _extras = {};
  bool _saving = false;
  bool _lookingUpCep = false;
  String? _cepMessage;
  String? _lastRequestedCep;
  int _cepRequestId = 0;
  Timer? _cepDebounce;

  static const _foodExtraPrices = <String, double>{
    'Queijo extra': 3.00,
    'Bacon': 4.50,
    'Molho da casa': 1.50,
  };

  static const _beverageExtraPrices = <String, double>{
    'Mais gelo': 0,
    'Mais açúcar': 0,
    'Leite extra': 1.50,
  };

  Map<String, double> get _availableExtras =>
      widget.product.category == 'Bebidas'
      ? _beverageExtraPrices
      : _foodExtraPrices;

  bool get _isOutsideCampus => _deliveryType == DeliveryType.outsideCampus;

  double get _total {
    final extrasTotal = _extras.fold<double>(
      0,
      (subtotal, name) => subtotal + _availableExtras[name]!,
    );
    return widget.product.price + _size.priceAdjustment + extrasTotal;
  }

  @override
  void dispose() {
    _customerController.dispose();
    _campusLocationController.dispose();
    _cepController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _cepDebounce?.cancel();
    super.dispose();
  }

  String? _required(String? value, String field) =>
      value == null || value.trim().isEmpty ? 'Informe $field.' : null;

  String? _requiredForOutside(String? value, String field) =>
      _isOutsideCampus ? _required(value, field) : null;

  String? _validateCep(String? value) {
    if (!_isOutsideCampus) return null;
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return 'O CEP precisa ter 8 números.';
    return null;
  }

  void _onCepChanged(String value) {
    _cepDebounce?.cancel();
    final digits = value.replaceAll(RegExp(r'\D'), '');
    setState(() {
      _cepMessage = null;
      if (digits.length < 8) _lookingUpCep = false;
    });

    if (digits.length == 8 && digits != _lastRequestedCep) {
      _lastRequestedCep = digits;
      _cepDebounce = Timer(const Duration(milliseconds: 500), () {
        if (mounted &&
            _cepController.text.replaceAll(RegExp(r'\D'), '') == digits) {
          _lookupCep(digits);
        }
      });
    } else if (digits.length < 8) {
      _lastRequestedCep = null;
      _cepRequestId++;
    }
  }

  Future<void> _lookupCep([String? cepValue]) async {
    final cep = (cepValue ?? _cepController.text).replaceAll(RegExp(r'\D'), '');
    if (cep.length != 8) {
      setState(() => _cepMessage = 'Digite os 8 números do CEP.');
      return;
    }

    final requestId = ++_cepRequestId;
    setState(() {
      _lookingUpCep = true;
      _cepMessage = 'Consultando o ViaCEP...';
    });

    try {
      final response = await http
          .get(Uri.https('viacep.com.br', '/ws/$cep/json/'))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        throw Exception(
          'O ViaCEP respondeu com status ${response.statusCode}.',
        );
      }

      final result = jsonDecode(response.body) as Map<String, dynamic>;
      if (result['erro'] == true) {
        if (mounted && requestId == _cepRequestId) {
          setState(() => _cepMessage = 'CEP não encontrado. Confira o número.');
        }
        return;
      }

      final currentCep = _cepController.text.replaceAll(RegExp(r'\D'), '');
      if (!mounted || requestId != _cepRequestId || currentCep != cep) return;

      _streetController.text = result['logradouro'] as String? ?? '';
      _complementController.text = result['complemento'] as String? ?? '';
      _neighborhoodController.text = result['bairro'] as String? ?? '';
      _cityController.text = result['localidade'] as String? ?? '';
      _stateController.text = result['uf'] as String? ?? '';
      setState(() => _cepMessage = 'Endereço encontrado e preenchido.');
    } catch (error) {
      if (mounted && requestId == _cepRequestId) {
        setState(
          () => _cepMessage =
              'Não foi possível consultar o CEP. Tente novamente.',
        );
      }
    } finally {
      if (mounted && requestId == _cepRequestId) {
        setState(() => _lookingUpCep = false);
      }
    }
  }

  String get _deliveryAddress {
    if (!_isOutsideCampus) return _campusLocationController.text.trim();
    final streetAndNumber = [
      _streetController.text.trim(),
      _numberController.text.trim(),
    ].where((part) => part.isNotEmpty).join(', ');
    final neighborhoodAndCity = [
      _neighborhoodController.text.trim(),
      [
        _cityController.text.trim(),
        _stateController.text.trim(),
      ].where((part) => part.isNotEmpty).join(' - '),
    ].where((part) => part.isNotEmpty).join(' - ');
    return [
      streetAndNumber,
      _complementController.text.trim(),
      neighborhoodAndCity,
    ].where((part) => part.isNotEmpty).join(', ');
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('orders').add({
        'customer': _customerController.text.trim(),
        'deliveryType': _deliveryType.label,
        'cep': _isOutsideCampus
            ? _cepController.text.replaceAll(RegExp(r'\D'), '')
            : '',
        'address': _deliveryAddress,
        'street': _isOutsideCampus ? _streetController.text.trim() : '',
        'number': _isOutsideCampus ? _numberController.text.trim() : '',
        'complement': _isOutsideCampus ? _complementController.text.trim() : '',
        'neighborhood': _isOutsideCampus
            ? _neighborhoodController.text.trim()
            : '',
        'city': _isOutsideCampus ? _cityController.text.trim() : '',
        'state': _isOutsideCampus ? _stateController.text.trim() : '',
        'productId': widget.product.id,
        'productName': widget.product.name,
        'size': _size.label,
        'extras': _extras.toList(),
        'total': _total,
        'status': 'Recebido',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido enviado para a cantina!')),
        );
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível enviar o pedido: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildOutsideAddressFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _cepController,
          decoration: InputDecoration(
            labelText: 'CEP',
            hintText: '00000-000',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.markunread_mailbox_outlined),
            suffixIcon: _lookingUpCep
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: 'Buscar endereço pelo CEP',
                    onPressed: () => _lookupCep(),
                    icon: const Icon(Icons.search),
                  ),
          ),
          keyboardType: TextInputType.number,
          maxLength: 9,
          validator: _validateCep,
          onChanged: _onCepChanged,
        ),
        if (_cepMessage != null) ...[
          const SizedBox(height: 4),
          Text(
            _cepMessage!,
            style: TextStyle(
              color: _cepMessage!.startsWith('Endereço encontrado')
                  ? Colors.green.shade700
                  : _cepMessage!.startsWith('Consultando')
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 10),
        ],
        TextFormField(
          controller: _streetController,
          decoration: const InputDecoration(
            labelText: 'Rua ou avenida',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.signpost_outlined),
          ),
          validator: (value) => _requiredForOutside(value, 'a rua ou avenida'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(
                  labelText: 'Número',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => _requiredForOutside(value, 'o número'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _complementController,
                decoration: const InputDecoration(
                  labelText: 'Complemento',
                  hintText: 'Apto./casa',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _neighborhoodController,
          decoration: const InputDecoration(
            labelText: 'Bairro',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_city_outlined),
          ),
          validator: (value) => _requiredForOutside(value, 'o bairro'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Cidade',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => _requiredForOutside(value, 'a cidade'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(
                  labelText: 'UF',
                  hintText: 'SP',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 2,
                validator: (value) => _requiredForOutside(value, 'o estado'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monte seu pedido'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  product.imageUrl,
                  height: 185,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Image.asset(
                    'assets/cantina_placeholder.png',
                    height: 185,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                product.name,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(product.description),
              const SizedBox(height: 20),
              Text(
                'Escolha o tamanho',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              RadioGroup<OrderSize>(
                groupValue: _size,
                onChanged: (value) => setState(() => _size = value!),
                child: Column(
                  children: OrderSize.values
                      .map(
                        (size) => RadioListTile<OrderSize>(
                          value: size,
                          title: Text(size.label),
                          subtitle: Text(
                            size.priceAdjustment < 0
                                ? 'R\$ ${(product.price + size.priceAdjustment).toStringAsFixed(2).replaceAll('.', ',')}'
                                : size.priceAdjustment == 0
                                ? 'Preço do catálogo'
                                : '+ R\$ ${size.priceAdjustment.toStringAsFixed(2).replaceAll('.', ',')}',
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                      .toList(),
                ),
              ),
              const Divider(),
              Text(
                'Adicionais',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              ..._availableExtras.entries.map(
                (extra) => CheckboxListTile(
                  value: _extras.contains(extra.key),
                  title: Text(extra.key),
                  subtitle: Text(
                    '+ R\$ ${extra.value.toStringAsFixed(2).replaceAll('.', ',')}',
                  ),
                  onChanged: (checked) => setState(() {
                    if (checked == true) {
                      _extras.add(extra.key);
                    } else {
                      _extras.remove(extra.key);
                    }
                  }),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const Divider(),
              TextFormField(
                controller: _customerController,
                decoration: const InputDecoration(
                  labelText: 'Seu nome',
                  hintText: 'Como podemos chamar você?',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => _required(value, 'seu nome'),
              ),
              const SizedBox(height: 16),
              Text(
                'Tipo de entrega',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              RadioGroup<DeliveryType>(
                groupValue: _deliveryType,
                onChanged: (value) => setState(() {
                  _deliveryType = value!;
                  _cepMessage = null;
                }),
                child: const Column(
                  children: [
                    RadioListTile<DeliveryType>(
                      value: DeliveryType.campus,
                      title: Text('Entrega no Campus'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<DeliveryType>(
                      value: DeliveryType.outsideCampus,
                      title: Text('Entrega fora do Campus'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              if (_deliveryType == DeliveryType.campus) ...[
                Text(
                  'Entrega no Campus',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _campusLocationController,
                  decoration: const InputDecoration(
                    labelText: 'Bloco, sala ou ponto de entrega',
                    hintText: 'Ex.: Bloco B, sala 12',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (value) => _deliveryType == DeliveryType.campus
                      ? _required(value, 'o local de entrega')
                      : null,
                ),
              ] else ...[
                Text(
                  'Entrega fora do Campus',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildOutsideAddressFields(),
              ],
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total do pedido',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'R\$ ${_total.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _saving ? null : _submitOrder,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(_saving ? 'Enviando...' : 'Confirmar pedido'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
