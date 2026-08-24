import 'package:flutter/material.dart';

import '../../../core/widgets/compact_page_chrome.dart';
import 'office_screen.dart';

class FacilitiesManagementScreen extends StatelessWidget {
  const FacilitiesManagementScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          toolbarHeight: 46,
          titleSpacing: 0,
          title: const CompactPageTitle(
            title: 'Facilities',
            eyebrow: 'Office & training ground',
          ),
        ),
        body: const SafeArea(top: false, child: FacilitiesScreen()),
      );
}
