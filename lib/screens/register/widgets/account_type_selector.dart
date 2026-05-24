import 'package:flutter/material.dart';

class AccountTypeSelector extends StatelessWidget {
  final int selected; // 0 = Ciudadano, 1 = Asociación
  final ValueChanged<int> onChanged;

  const AccountTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Center(
      child: const Text(
        'Tipo de cuenta',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    const SizedBox(height: 10),
    Row(
      children: [
        Expanded(
          child: _AccountCard(
            title: 'Ciudadano',
            icon: Icons.person_outline,
            selected: selected == 0,
            onTap: () => onChanged(0),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AccountCard(
            title: 'Asociación',
            icon: Icons.apartment_outlined,
            selected: selected == 1,
            onTap: () => onChanged(1),
          ),
        ),
      ],
    ),
  ],
);

  }
}
class _AccountCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _AccountCard({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? Colors.blueGrey.withOpacity(0.12) : Colors.white;
    final border = selected ? Colors.blueGrey : Colors.transparent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 78,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1.2),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(0, 4),
              color: Colors.black.withOpacity(0.06),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black54),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.blueGrey : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

