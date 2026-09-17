import 'dart:js_interop';

@JS('window.open')
external JSAny? _abrirJanela(String url, String alvo, String recursos);

void abrirRotaEmNovaAba(String rota) {
  // O app usa a estratégia padrão do Flutter Web: rota no fragmento (#).
  // Preserva a origem e o caminho de hospedagem, inclusive em subdiretórios.
  final url = Uri.base.replace(fragment: rota);
  _abrirJanela(url.toString(), '_blank', 'noopener,noreferrer');
}
