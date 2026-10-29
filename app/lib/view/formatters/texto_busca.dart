/// Normalização local para pesquisa por título/ID, sem mudar o texto exibido.
String normalizarTextoBusca(String texto) {
  const grupos = {
    'a': 'áàâãäå',
    'e': 'éèêë',
    'i': 'íìîï',
    'o': 'óòôõö',
    'u': 'úùûü',
    'c': 'ç',
    'n': 'ñ',
    'y': 'ýÿ',
  };
  var resultado = texto.toLowerCase().replaceAll(
    RegExp(r'[\u0300-\u036f]'),
    '',
  );
  for (final grupo in grupos.entries) {
    resultado = resultado.replaceAll(RegExp('[${grupo.value}]'), grupo.key);
  }
  return resultado;
}
