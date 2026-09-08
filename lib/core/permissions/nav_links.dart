import 'package:flutter/material.dart';

import '../../features/auth/presentation/providers/auth_state.dart';

class LinkSection {
  final String title;
  final List<QuickLink> links;
  final List<String> anyOf;

  const LinkSection(this.title, this.links, {this.anyOf = const []});
}

class QuickLink {
  final String label;
  final String route;
  final IconData icon;

  /// Empty = visible to all authenticated users (web sidebar semantics).
  final List<String> anyOf;

  const QuickLink(this.label, this.route, this.icon, {this.anyOf = const []});
}

/// Keep sections/links the user may see; drop empty sections.
List<LinkSection> filterLinkSections(
  List<LinkSection> sections,
  AuthState auth,
) {
  return sections
      .where((section) => auth.canAny(section.anyOf))
      .map((section) {
        final links = section.links
            .where((link) => auth.canAny(link.anyOf))
            .toList(growable: false);
        return LinkSection(section.title, links);
      })
      .where((section) => section.links.isNotEmpty)
      .toList(growable: false);
}
