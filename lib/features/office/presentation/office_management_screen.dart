import 'package:flutter/material.dart';

import 'office_screen.dart';

class OfficeManagementScreen extends StatelessWidget {
  const OfficeManagementScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          toolbarHeight: 46,
          titleSpacing: 0,
          title: Text(
            'Office & scouts',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        body: const SafeArea(top: false, child: OfficeScreen()),
      );
}
