import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/repositories/venta_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import 'estado_visual.dart';

class VentaDetalleScreen extends StatelessWidget {
  final VentaConVendedor item;

  const VentaDetalleScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    const soles = FormatoSoles();
    final v = item.venta;
    final vendedor = item.vendedor;
    final color = v.estado.color;

    final tieneComision = v.comisionCalculada != null;
    final textoComision = tieneComision
        ? '${soles.format(v.comisionCalculada!)} de comisión'
        : (v.estado.generaComision
            ? 'Comisión pendiente de cálculo'
            : 'Todavía no genera comisión');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 36),
          children: [
            Row(
              children: [
                _BotonAtras(onTap: () => Navigator.of(context).pop()),
                const Spacer(),
                Text(
                  'Venta #${v.id}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textoSecundario),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(v.estado.icono, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(v.nombreCliente, style: AppTypography.titulo(size: 24)),
            const SizedBox(height: 10),
            _PastillaEstado(texto: v.estado.label, color: color),
            const SizedBox(height: 28),
            const Text(
              'CARGO FIJO MENSUAL',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textoSecundario,
              ),
            ),
            const SizedBox(height: 4),
            Text(soles.format(v.cargoFijo),
                style: AppTypography.titulo(size: 34)),
            const SizedBox(height: 6),
            Text(
              textoComision,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: tieneComision ? FontWeight.w700 : FontWeight.w400,
                color: tieneComision
                    ? AppColors.positivo
                    : AppColors.textoSecundario,
              ),
            ),
            const SizedBox(height: 34),
            _Seccion(
              titulo: 'CLIENTE',
              filas: [
                _FilaDato(
                    etiqueta: 'DNI', valor: v.dniCliente, ocultable: true),
                _FilaDato(
                    etiqueta: 'Contacto',
                    valor: v.numeroContacto,
                    copiable: true),
                if (v.numeroPorta != null)
                  _FilaDato(
                      etiqueta: 'Número a portar',
                      valor: v.numeroPorta!,
                      copiable: true),
                if (v.operadorCedente != null)
                  _FilaDato(
                      etiqueta: 'Operador cedente',
                      valor: v.operadorCedente!),
                if (v.direccionEntrega != null)
                  _FilaDato(etiqueta: 'Dirección', valor: v.direccionEntrega!),
                if (v.distritoEntrega != null)
                  _FilaDato(etiqueta: 'Distrito', valor: v.distritoEntrega!),
              ],
            ),
            _Seccion(
              titulo: 'PRODUCTO',
              filas: [
                _FilaDato(etiqueta: 'Tipo', valor: v.tipoProducto.label),
                _FilaDato(
                    etiqueta: 'Origen', valor: etiquetaOrigen(v.origenVenta)),
                _FilaDato(etiqueta: 'Canal', valor: v.canal),
              ],
            ),
            _Seccion(
              titulo: 'VENDEDOR',
              filas: [
                if (vendedor != null) ...[
                  _FilaDato(etiqueta: 'Nombre', valor: vendedor.nombreCompleto),
                  _FilaDato(
                      etiqueta: 'Tipo', valor: vendedor.tipoTrabajador.label),
                ] else
                  const _FilaDato(
                      etiqueta: 'Nombre', valor: 'Sin vendedor asignado'),
              ],
            ),
            _Seccion(
              titulo: 'SEGUIMIENTO',
              filas: [
                _FilaDato(
                    etiqueta: 'Registrada', valor: fechaLarga(v.fechaRegistro)),
                _FilaDato(etiqueta: 'Periodo', valor: etiquetaMes(v.mes)),
                if (v.motivoRechazo != null)
                  _FilaDato(etiqueta: 'Motivo', valor: v.motivoRechazo!),
                if (v.subMotivo != null)
                  _FilaDato(etiqueta: 'Detalle', valor: v.subMotivo!),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonAtras extends StatelessWidget {
  final VoidCallback onTap;
  const _BotonAtras({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borde),
        ),
        child: const Icon(Icons.arrow_back_rounded,
            size: 20, color: AppColors.texto),
      ),
    );
  }
}

class _PastillaEstado extends StatelessWidget {
  final String texto;
  final Color color;

  const _PastillaEstado({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Text(
              texto,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  final String titulo;
  final List<Widget> filas;

  const _Seccion({required this.titulo, required this.filas});

  @override
  Widget build(BuildContext context) {
    if (filas.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.textoSecundario,
            ),
          ),
          const SizedBox(height: 4),
          ...filas,
        ],
      ),
    );
  }
}

class _FilaDato extends StatefulWidget {
  final String etiqueta;
  final String valor;
  final bool copiable;
  final bool ocultable;

  const _FilaDato({
    required this.etiqueta,
    required this.valor,
    this.copiable = false,
    this.ocultable = false,
  });

  @override
  State<_FilaDato> createState() => _FilaDatoState();
}

class _FilaDatoState extends State<_FilaDato> {
  bool _visible = false;

  void _copiar() {
    Clipboard.setData(ClipboardData(text: widget.valor));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.etiqueta} copiado'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mostrado = widget.ocultable && !_visible
        ? _enmascarar(widget.valor)
        : widget.valor;

    return InkWell(
      onLongPress: widget.copiable ? _copiar : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borde)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 118,
              child: Text(
                widget.etiqueta,
                style: const TextStyle(
                    fontSize: 13.5, color: AppColors.textoSecundario),
              ),
            ),
            Expanded(
              child: Text(
                mostrado,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            if (widget.ocultable)
              GestureDetector(
                onTap: () => setState(() => _visible = !_visible),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    _visible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 19,
                    color: AppColors.textoSecundario,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _enmascarar(String valor) {
  if (valor.length <= 4) return '•' * valor.length;
  return '${valor.substring(0, 2)}${'•' * (valor.length - 4)}${valor.substring(valor.length - 2)}';
}