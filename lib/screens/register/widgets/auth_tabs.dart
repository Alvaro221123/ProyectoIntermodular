import 'package:flutter/material.dart';

/// Widget reutilizable que muestra los tabs:
/// "Iniciar sesión" y "Registrarse".
///
/// IMPORTANTE:
/// - Este widget NO guarda el estado.
/// - El estado (qué tab está seleccionado) lo controla el padre.
/// - Este widget solo pinta la UI y notifica cuando el usuario toca algo.
class AuthTabs extends StatelessWidget {
  /// Indica cuál tab está seleccionado:
  /// 0 = Iniciar sesión
  /// 1 = Registrarse
  final int selectedIndex;

  /// Función callback que se ejecuta cuando el usuario cambia de tab.
  /// Le devolvemos al padre el índice seleccionado (0 o 1).
  final ValueChanged<int> onChanged;

  const AuthTabs({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Altura total del "selector" (lo que parece un botón dividido en 2).
      height: 50,

      // Padding interno para que el botón seleccionado no toque los bordes.
      padding: const EdgeInsets.all(4),

      // Decoración del contenedor exterior (fondo redondeado)
      decoration: BoxDecoration(
        // Un blanco semitransparente, estilo "card" como en tus capturas
        color: Colors.white.withOpacity(0.75),

        // Bordes redondeados del contenedor exterior
        borderRadius: BorderRadius.circular(14),
      ),

      // Row para poner 2 opciones una al lado de la otra
      child: Row(
        children: [
          // Expanded hace que ocupe la mitad exacta del ancho
          Expanded(
            child: _TabButton(
              text: 'Iniciar Sesión',

              // Si el selectedIndex es 0, este botón se dibuja como "seleccionado"
              selected: selectedIndex == 0,

              // Cuando se toca, llamamos al callback del padre con el valor 0
              onTap: () => onChanged(0),
            ),
          ),

          // Segundo botón (también ocupa la mitad del ancho)
          Expanded(
            child: _TabButton(
              text: 'Registrarse',
              // Si el selectedIndex es 1, este botón se dibuja como "seleccionado"
              selected: selectedIndex == 1,

              // Cuando se toca, avisamos al padre con el valor 1
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget privado (solo se usa dentro de este archivo)
/// Representa cada "mitad" del selector.
///
/// El "_" significa que NO se importa desde otro archivo:
/// solo vive aquí para mantener el proyecto ordenado.
class _TabButton extends StatelessWidget {
  /// Texto que aparece en el botón
  final String text;

  /// Indica si este botón está seleccionado
  final bool selected;

  /// Acción al tocar el botón
  final VoidCallback onTap;

  const _TabButton({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // InkWell da efecto de "tap" (onda/ripple) si hay Material arriba
      // y además detecta el toque.
      onTap: onTap,

      // Bordes redondeados para que el toque respete la forma
      borderRadius: BorderRadius.circular(12),

      // AnimatedContainer permite que el cambio de selección
      // se vea suave (con animación)
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,

        // Decoración del botón
        decoration: BoxDecoration(
          // Si está seleccionado se pinta con color.
          // Si no, queda transparente.
          color: selected ? const Color(0xFF6E8CA6) : Colors.transparent,

          // Bordes redondeados del botón interior
          borderRadius: BorderRadius.circular(12),
        ),

        // Texto del botón
        child: Text(
          text,
          style: TextStyle(
            // Si está seleccionado, texto blanco; si no, gris
            color: selected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
