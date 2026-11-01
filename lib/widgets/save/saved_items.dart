import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../state/saves.dart';

/// The "All" pill's id.
const String kAllCollections = 'all';

/// The "Unsorted" pill's id.
const String kUnsortedCollections = 'unsorted';

/// Catalogue items in [view]: `all`, `unsorted` or a board id, newest first.
/// Saves the catalogue has no card for are skipped: an account can hold designs
/// saved on the web that this build doesn't ship, and they stay in the account.
List<Item> savedItems(SavesState s, String view) => <Item>[
      for (final SaveEntry e in switch (view) {
        kAllCollections => s.saves,
        kUnsortedCollections => s.unsorted,
        _ => s.savesIn(view),
      })
        ?bySlug(e.slug),
    ];

/// Saves this build can show, for counts that must match what's on screen.
int visibleSaveCount(SavesState s) => s.saves.where((e) => bySlug(e.slug) != null).length;
