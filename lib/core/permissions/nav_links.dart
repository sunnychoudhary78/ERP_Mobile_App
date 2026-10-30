import 'package:flutter/material.dart';

import '../../features/auth/presentation/providers/auth_state.dart';

class LinkSection {
  final String title;
  final List<QuickLink> links;
  final List<String> anyOf;

  /// Extra entitlement/module check (doc 05). Null = no extra check.
  final bool Function(AuthState auth)? entitlement;

  const LinkSection(
    this.title,
    this.links, {
    this.anyOf = const [],
    this.entitlement,
  });
}

class QuickLink {
  final String label;
  final String route;
  final IconData icon;



  final String? group;

  /// Empty = visible to all authenticated users (web sidebar semantics).
  final List<String> anyOf;

  /// Extra entitlement/module check (doc 05). Null = no extra check.
  final bool Function(AuthState auth)? entitlement;

  const QuickLink(this.label, this.route, this.icon, {this.anyOf = const [],this.group, this.entitlement,});
}

bool _allows(AuthState auth, List<String> anyOf, bool Function(AuthState)? ent) {
  if (!auth.canAny(anyOf)) return false;
  return ent == null || ent(auth);
}

/// Keep sections/links the user may see; drop empty sections.
List<LinkSection> filterLinkSections(
  List<LinkSection> sections,
  AuthState auth,
) {
  return sections
      .where((section) => _allows(auth, section.anyOf, section.entitlement))
      .map((section) {
        final links = section.links
            .where((link) => _allows(auth, link.anyOf, link.entitlement))
            .toList(growable: false);
        return LinkSection(section.title, links);
      })
      .where((section) => section.links.isNotEmpty)
      .toList(growable: false);
}
