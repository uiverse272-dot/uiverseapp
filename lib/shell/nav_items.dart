import '../router/routes.dart';
import '../widgets/core/ui_icon.dart';

/// One primary-navigation destination.
class NavDest {
  const NavDest(this.path, this.label, this.icon);

  final String path;
  final String label;
  final Ui icon;
}

/// Rail main group (§9.4).
const List<NavDest> railMain = [
  NavDest(Routes.home, 'Home', Ui.home),
  NavDest(Routes.explore, 'Explore', Ui.compass),
  NavDest(Routes.web, 'Web', Ui.monitor),
  NavDest(Routes.apps, 'Apps', Ui.phone),
  NavDest(Routes.components, 'Parts', Ui.grid),
  NavDest(Routes.layouts, 'Layouts', Ui.layout),
  NavDest(Routes.palettes, 'Palettes', Ui.palette),
  NavDest(Routes.saved, 'Saved', Ui.bookmark),
];

/// Rail footer group (theme toggle follows).
const List<NavDest> railFoot = [
  NavDest(Routes.upload, 'Upload', Ui.upload),
  NavDest(Routes.me, 'Profile', Ui.user),
];

/// Phone bottom tabs (§9.5). Upload is deliberately absent.
const List<NavDest> bottomTabs = [
  NavDest(Routes.home, 'Home', Ui.home),
  NavDest(Routes.explore, 'Explore', Ui.compass),
  NavDest(Routes.search, 'Search', Ui.search),
  NavDest(Routes.saved, 'Saved', Ui.bookmark),
  NavDest(Routes.me, 'Profile', Ui.user),
];

/// "More ▾" menu entries (≥1024).
const List<NavDest> moreMenu = [
  NavDest(Routes.threeD, '3D', Ui.sparkle),
  NavDest(Routes.creators, 'Creators', Ui.user),
  NavDest(Routes.pricing, 'Pricing', Ui.check),
  NavDest(Routes.upload, 'Upload', Ui.upload),
];

/// Active rule: `/` exact; others match the path or a sub-path.
bool isNavActive(String location, String href) {
  if (href == Routes.home) return location == Routes.home;
  return location == href || location.startsWith('$href/');
}
