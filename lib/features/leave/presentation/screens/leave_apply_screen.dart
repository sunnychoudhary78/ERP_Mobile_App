import 'package:flutter/material.dart';

class LeaveApplyScreen extends StatelessWidget {
  const LeaveApplyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave Apply')),
      body: Center(
        child: Column(
          children: [
            Container(alignment: Alignment.center, child: Text("Apply Leave")),
          ],
        ),
      ),
    );
  }
}
