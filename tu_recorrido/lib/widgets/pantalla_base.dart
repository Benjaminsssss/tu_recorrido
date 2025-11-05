import 'package:flutter/material.dart';
import '../utils/colores.dart';

/// Widget base reutilizable para pantallas de la app
/// Proporciona estructura consistente con AppBar y body personalizable
class PantallaBase extends StatelessWidget {
  final String titulo;
  final Widget body;
  final bool mostrarCargando;
  final Future<void> Function()? onRefresh;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final Color? appBarBackgroundColor;

  const PantallaBase({
    super.key,
    required this.titulo,
    required this.body,
    this.mostrarCargando = false,
    this.onRefresh,
    this.actions,
    this.floatingActionButton,
    this.backgroundColor,
    this.appBarBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? Coloressito.backgroundDark,
      appBar: AppBar(
        title: Text(
          titulo,
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: appBarBackgroundColor ?? Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Coloressito.borderLight,
          ),
        ),
        actions: actions,
      ),
      body: mostrarCargando
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Coloressito.adventureGreen,
                ),
              ),
            )
          : onRefresh != null
              ? RefreshIndicator(
                  color: Coloressito.adventureGreen,
                  onRefresh: onRefresh!,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: body,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: body,
                ),
      floatingActionButton: floatingActionButton,
    );
  }
}
