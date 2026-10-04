import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controllers/auth_controller.dart';
import 'admin_access_denied_view.dart';
import 'admin_dashboard_view.dart';

class AdminView extends StatelessWidget {
  const AdminView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Obx(() {
      final user = authController.currentUser.value;
      final bool hasAdminAccess = user != null && user.canAccessAdmin;

      if (!hasAdminAccess) {
        return AdminAccessDeniedView(user: user);
      }

      return AdminDashboardView(user: user);
    });
  }
}
