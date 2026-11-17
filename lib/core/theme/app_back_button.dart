import 'package:shadcn_flutter/shadcn_flutter.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Button.ghost(
      onPressed: () => Navigator.of(context).maybePop(),
      leading: ExcludeSemantics(
        child: Icon(Directionality.of(context) == TextDirection.rtl
            ? LucideIcons.arrowRight
            : LucideIcons.arrowLeft),
      ),
      child: const Text('Back'),
    );
  }
}
