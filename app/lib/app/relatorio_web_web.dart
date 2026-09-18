import 'dart:js_interop';

@JS('temdasDownloadText')
external void _baixarTexto(
  String nomeArquivo,
  String conteudo,
  String mimeType,
);

@JS('temdasPrintHtml')
external void _imprimirHtml(String html, String titulo);

void baixarTexto(String nomeArquivo, String conteudo, String mimeType) {
  _baixarTexto(nomeArquivo, conteudo, mimeType);
}

void imprimirHtml(String html, String titulo) {
  _imprimirHtml(html, titulo);
}
