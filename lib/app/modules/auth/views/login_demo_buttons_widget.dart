import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';

class LoginDemoButtonsWidget extends StatelessWidget {
  final AuthController auth;

  const LoginDemoButtonsWidget({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      children: [
        TextButton(
          onPressed: () {
            auth.loginGoogleDemo(asAdmin: true);
            Navigator.of(context).pop();
          },
          child: const Text(
            'Uji Google Admin',
            style: TextStyle(fontSize: 12, color: Color(0xFF1B5E20)),
          ),
        ),
        TextButton(
          onPressed: () {
            auth.loginGoogleDemo(asAdmin: false);
            Navigator.of(context).pop();
          },
          child: const Text(
            'Uji Google Pelanggan',
            style: TextStyle(fontSize: 12, color: Colors.blue),
          ),
        ),
      ],
    );
  }
}
