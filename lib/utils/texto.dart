/// Pasa a minúsculas y quita tildes y eñes, para comparar texto sin que
/// importe cómo lo escribió quien busca.
String normalizarTexto(String texto) {
  const origen = 'áéíóúüñÁÉÍÓÚÜÑ';
  const destino = 'aeiouunAEIOUUN';
  var resultado = texto;
  for (var i = 0; i < origen.length; i++) {
    resultado = resultado.replaceAll(origen[i], destino[i]);
  }
  return resultado.toLowerCase();
}

/// Pone en mayúscula la primera letra: 'junio 2026' pasa a 'Junio 2026'.
String capitalizar(String texto) =>
    texto.isEmpty ? texto : texto[0].toUpperCase() + texto.substring(1);
