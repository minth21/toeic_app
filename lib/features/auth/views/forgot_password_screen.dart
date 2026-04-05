import 'package:flutter/material.dart';

/// OBSOLETE: Password reset is no longer supported in the "Provided Accounts" model.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Tính năng này đã bị gỡ bỏ.'),
      ),
    );
  }
}
