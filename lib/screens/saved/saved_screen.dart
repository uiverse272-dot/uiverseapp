import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../router/routes.dart';
import '../../state/saves.dart';
import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import '../../widgets/feed/feed.dart';
import '../../widgets/section/section.dart';
import 'collection_pills.dart';
import '../../widgets/core/ui_chip.dart';

/// The "All" pill's id.
const String kAllCollections = 'all';

/// Catalogue items saved in [collection] (`all` = every save), newest first.
/// Saves whose slug no longer exists are skipped.
List<Item> savedItems(SavesState s, String collection) => <Item>[
      for (final SaveEntry e in collection == kAllCollections ? s.saves : s.savesIn(collection))
        ?bySlug(e.slug),
    ];

/// `/saved` — saves and collections (§12). Collection pills (All + each,
/// with counts) and a dashed "New collection" button that turns into an
/// inline input; then the [Feed] of the selected collection or an empty state.
///
/// Like the web, the selected collection is local state, not a URL param;
/// [query] is accepted for route symmetry and currently unused.
class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key, this.query = const <String, String>{}});

  final Map<String, String> query;

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  String _active = kAllCollections;

  @override
  Widget build(BuildContext context) {
    final SavesState saves = ref.watch(savesProvider);
    final List<Item> items = savedItems(saves, _active);
    return CustomScrollView(
      slivers: [
        SliverShell(
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PageHeader(
                  title: 'Saved',
                  sub: 'Saving never asks which board. Organising is a separate, later act — '
                      'that is why the toast offers “Move to…” instead of a dialog.',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: CollectionPills(
                    saves: saves,
                    active: _active,
                    onSelect: (String id) => setState(() => _active = id),
                    onCreate: (String name) => ref.read(savesProvider.notifier).createCollection(name),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverShell(
          sliver: items.isEmpty ? const SliverToBoxAdapter(child: SavedEmpty()) : Feed(items: items),
        ),
      ],
    );
  }
}

/// Empty collection: title, hint and "Browse the feed", centred in 40% of
/// the viewport height.
class SavedEmpty extends StatelessWidget {
  const SavedEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height * 0.4),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nothing saved here yet',
              textAlign: TextAlign.center,
              style: UiText.mono(15, bold: true, color: c.text),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 384),
              child: Text(
                'Tap the bookmark under any card to save it here.',
                textAlign: TextAlign.center,
                style: UiText.mono(13.5, color: c.text2),
              ),
            ),
            const SizedBox(height: 20),
            UiChip(
              'Browse the feed',
              onTap: () => context.go(Routes.home),
              link: true,
              height: null,
              hPad: 14,
              vPad: 8,
              style: UiText.button,
              minSize: const Size(48, 48),
            ),
          ],
        ),
      ),
    );
  }
}
