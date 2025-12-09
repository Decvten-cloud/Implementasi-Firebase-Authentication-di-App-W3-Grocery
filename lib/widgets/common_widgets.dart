import 'package:flutter/material.dart';

class SearchBox extends StatelessWidget {
  const SearchBox({
    required this.hint, 
    this.controller,
    this.onChanged,
    super.key,
  });
  
  final String hint;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      enabled: onChanged != null,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded),
        hintText: hint,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class Dot extends StatelessWidget {
  const Dot({required this.color, super.key});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class QtyBtn extends StatelessWidget {
  const QtyBtn({required this.icon, required this.onTap, super.key});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }
}

class Badge extends StatelessWidget {
  const Badge({required this.number, super.key});
  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onError,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class MenuTile extends StatelessWidget {
  const MenuTile({
    required this.icon,
    required this.text,
    this.trailing,
    this.isDestructive = false,
    super.key,
  });
  final IconData icon;
  final String text;
  final Widget? trailing;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: isDestructive ? cs.error : cs.primary),
      title: Text(
        text,
        style: isDestructive
            ? TextStyle(color: cs.error, fontWeight: FontWeight.w500)
            : null,
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class ImgPlaceholder extends StatelessWidget {
  const ImgPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class ImgBroken extends StatelessWidget {
  const ImgBroken({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: const Center(child: Icon(Icons.broken_image_rounded)),
    );
  }
}

// Public product card used across pages.
class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.p,
    required this.inFav,
    required this.onFav,
    required this.onAdd,
    required this.onOpen,
    super.key,
  });

  final dynamic
  p; // keep dynamic to avoid circular import; consumer passes Product
  final bool inFav;
  final VoidCallback onFav;
  final VoidCallback onAdd;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Column(
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 11,
                  child: Image.network(
                    p.img,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (c, e, s) => const ImgBroken(),
                    loadingBuilder: (c, child, progress) =>
                        progress == null ? child : const ImgPlaceholder(),
                  ),
                ),
                const Positioned(
                  left: 8,
                  top: 8,
                  child: SaleBadge(text: '5% OFF'),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: GestureDetector(
                    onTap: onFav,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(
                        inFav ? Icons.favorite : Icons.favorite_border,
                        color: cs.primary,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '\$ ${p.price}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '\$ ${p.oldPrice}',
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Theme.of(context).textTheme.bodySmall!.color,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.star, size: 16),
                      const SizedBox(width: 2),
                      const Text('(243)'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: FilledButton.tonal(
                      onPressed: onAdd,
                      child: const Text('Add to cart'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SaleBadge extends StatelessWidget {
  const SaleBadge({required this.text, super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: cs.onPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}
