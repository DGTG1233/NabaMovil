/// Cuántos intentos fallidos lleva el acceso y, si corresponde, hasta cuándo
/// está bloqueado.
class EstadoAcceso {
  final int intentosFallidos;
  final DateTime? bloqueadoHasta;

  const EstadoAcceso({this.intentosFallidos = 0, this.bloqueadoHasta});

  static const limpio = EstadoAcceso();

  bool estaBloqueado(DateTime ahora) {
    final hasta = bloqueadoHasta;
    return hasta != null && ahora.isBefore(hasta);
  }

  int get intentosRestantes => LimiteIntentos.maximo - intentosFallidos;

  Duration tiempoRestante(DateTime ahora) {
    final hasta = bloqueadoHasta;
    if (hasta == null || !ahora.isBefore(hasta)) return Duration.zero;
    return hasta.difference(ahora);
  }
}

/// Regla de bloqueo: después de [maximo] intentos fallidos seguidos, el
/// acceso queda bloqueado durante [duracionBloqueo].
class LimiteIntentos {
  LimiteIntentos._();

  static const maximo = 5;
  static const duracionBloqueo = Duration(minutes: 5);

  /// Estado que resulta de un intento fallido hecho en `ahora`. Al llegar al
  /// máximo se abre el bloqueo y el contador vuelve a cero, de modo que al
  /// terminar el bloqueo hay otros [maximo] intentos.
  static EstadoAcceso registrarFallo(EstadoAcceso actual, DateTime ahora) {
    final venciaBloqueo =
        actual.bloqueadoHasta != null && !actual.estaBloqueado(ahora);
    final base = venciaBloqueo ? EstadoAcceso.limpio : actual;

    final fallidos = base.intentosFallidos + 1;
    if (fallidos >= maximo) {
      return EstadoAcceso(bloqueadoHasta: ahora.add(duracionBloqueo));
    }
    return EstadoAcceso(
      intentosFallidos: fallidos,
      bloqueadoHasta: base.bloqueadoHasta,
    );
  }
}
