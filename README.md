# Cantina do Campus

Aplicativo de delivery da cantina da faculdade. O catálogo apresenta lanches e bebidas; o cliente escolhe tamanho e adicionais, informa nome e dados de entrega, e envia o pedido para o Cloud Firestore.

## Executar no Chrome

1. Confira a configuração do projeto em `lib/firebase_options.dart`.
2. Ative o Cloud Firestore no console Firebase e configure regras de leitura e gravação para a apresentação.
3. Execute `flutter pub get` e `flutter run -d chrome`.
4. Na tela inicial, escolha **Pedir** em um produto. Os pedidos enviados aparecem em **Pedidos da cantina**.

O formulário grava os documentos na coleção `orders` com `add`. A lista usa `snapshots()` e `StreamBuilder`, com indicador de carregamento. Na lista, o ícone de lixeira cancela e remove o pedido do Firestore; a atualização em tempo real o retira da tela. As bebidas têm adicionais próprios, como gelo e açúcar. Para entrega fora do campus, a consulta ao ViaCEP preenche rua, bairro, cidade, estado e complemento a partir do CEP.

## Checklist da aplicação mínima

- [x] Três telas separadas: catálogo, configuração do pedido e lista de pedidos; todas com `Scaffold`, `AppBar` e `body`.
- [x] `MaterialApp`, `runApp`, `TextStyle` e AppBars personalizadas.
- [x] Fotos de produtos com `Image.network`, imagens de fallback com `Image.asset`, `BoxFit`, ícones e asset registrado.
- [x] `Column`, `Row`, alinhamentos, `Stack`, `Positioned`, `Padding` e `SingleChildScrollView`.
- [x] Navegação com `Navigator.push`/`MaterialPageRoute`, retorno e produto passado como parâmetro.
- [x] Formulário com `StatefulWidget`, `setState`, três `TextEditingController`s e leitura de `.text`.
- [x] Adicionais com `CheckboxListTile` e tamanho com `RadioListTile` e enum.
- [x] Firebase inicializado; coleção `orders`, gravação com `add`, consulta com `get` e lista em tempo real com `snapshots()`/`StreamBuilder`.
- [ ] Executar no Chrome e confirmar leitura/gravação no Firebase do grupo.
- [ ] Criar ao menos três pedidos pelo catálogo para a apresentação e conferir os documentos na coleção `orders`.

