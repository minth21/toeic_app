import 'package:flutter/material.dart';

/// OBSOLETE: Password reset is no longer supported in the "Provided Accounts" model.
class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Tính năng này đã bị gỡ bỏ.'),
      ),
    );
  }
}
