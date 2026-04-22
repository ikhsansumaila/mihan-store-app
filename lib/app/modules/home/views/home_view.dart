import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is initialized if not using bindings
    if (!Get.isRegistered<HomeController>()) {
      Get.put(HomeController());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Header (Yellow)
          Column(
            children: [
              Container(
                height: 280, // Adjust height
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.primaryYellow,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        // Top Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.location_on, color: AppColors.primaryDark),
                                SizedBox(width: 5),
                                Text(
                                  "ABANGJUKIR",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppColors.primaryDark,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // User Profile
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.purpleAccent, // Placeholder for image
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Obx(
                                    () => Text(
                                      "HI, ${controller.userName}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    "Have a great day!",
                                    style: TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryDark,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.wallet, color: Colors.white, size: 16),
                                  const SizedBox(width: 5),
                                  Obx(
                                    () => Text(
                                      "Points | ${controller.userPoints}",
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(child: Container()), // Filler
            ],
          ),

          // Main Scrollable Content
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 180), // Offset for header overlap
                // Wallet Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.amber[100], shape: BoxShape.circle),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.black,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "DompetJukir",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              const Text(
                                "IDR ",
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              Obx(
                                () => Text(
                                  controller.walletBalance.value,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.monetization_on_outlined,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Obx(
                                () => Text(
                                  "Bank Points ${controller.bankPoints}",
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Zone Selector
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: [
                      _buildZoneChip("Zona A", true),
                      _buildZoneChip("Zona B", false),
                      _buildZoneChip("Zona C", false),
                      _buildZoneChip("Zona D", false),
                      _buildZoneChip("Zona E", false),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Zone Info Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Obx(
                                () => Text(
                                  controller.currentZone.value,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDark,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Text(
                                  "Zona Anda",
                                  style: TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.swap_horiz, size: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.purpleAccent,
                            child: Icon(Icons.person, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Obx(
                                  () => Text(
                                    controller.userName.value,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Obx(
                                  () => Text(
                                    "(${controller.userId.value})",
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Progress Bar
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: LinearProgressIndicator(
                                    value: 2 / 6,
                                    color: AppColors.primaryYellow,
                                    backgroundColor: Colors.grey.shade100,
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "2/6",
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Parking Grid content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Obx(
                          () => Column(
                            children: controller.slots
                                .where(
                                  (s) => ['A001', 'A002', 'A003', 'A004', 'A008'].contains(s.id),
                                )
                                .map((s) => _buildSlotItem(s))
                                .toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10), // Middle Gap
                      Expanded(
                        child: Obx(
                          () => Column(
                            children: controller.slots
                                .where(
                                  (s) => [
                                    'A009',
                                    'A010',
                                    'A011',
                                    'A014',
                                    'A012',
                                    'A015',
                                    'A013',
                                  ].contains(s.id),
                                )
                                .map((s) => _buildSlotItem(s))
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100), // Space for bottom sheet
              ],
            ),
          ),

          // Process Sheet (Conditional)
          Obx(
            () => controller.selectedSlot.value != null
                ? Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        20,
                        20,
                        100,
                      ), // Extra padding at bottom for nav bar
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Slot Parkir",
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    controller.selectedSlot.value?.label ?? "-",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryDark,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                ),
                                child: const Text("Proses", style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Bottom Navigation (Always Visible)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              width: MediaQuery.of(context).size.width * 0.85,
              decoration: BoxDecoration(
                color: const Color(0xFF555555), // Dark grey bar
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavIcon(Icons.home, true), // Logo icon approximation
                  _buildNavIcon(Icons.history, false),
                  _buildNavIcon(Icons.person_outline, false),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryYellow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.menu, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: isActive
          ? BoxDecoration(
              border: Border.all(color: Colors.white, width: 1),
              shape: BoxShape.circle,
            )
          : null,
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  Widget _buildZoneChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryDark : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSlotItem(ParkingSlot slot) {
    // Determine visuals based on status
    Color bgColor = Colors.white;
    Color borderColor = Colors.grey.shade200;
    Widget content;

    if (slot.status == 'occupied') {
      // Car Image Placeholder
      content = Stack(
        alignment: Alignment.center,
        children: [Icon(Icons.directions_car, size: 50, color: Colors.grey.shade400)],
      );
    } else if (slot.status == 'blocked') {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text(
            "Blocked",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2),
          Icon(Icons.lock, size: 16, color: Colors.grey),
        ],
      );
    } else if (slot.status == 'selected') {
      bgColor = AppColors.slotSelected; // Light yellow
      borderColor = AppColors.primaryYellow;
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text("Selected", style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 4),
          Icon(Icons.check_circle_outline, size: 16),
        ],
      );
    } else {
      // Available
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (slot.isHandicap) const Icon(Icons.accessible, size: 16, color: Colors.black),
          Text(slot.label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      );
      if (slot.id == 'A009' || slot.id == 'A001') {
        // For those with icons on top corner
        content = Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: Icon(Icons.local_gas_station, size: 30, color: Colors.grey),
            ),
            Center(
              child: Text(slot.label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }
    }

    return GestureDetector(
      onTap: () => controller.toggleSlotSelection(slot),
      child: Container(
        height: 80,
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor),
          boxShadow: [
            if (slot.status == 'available' || slot.status == 'selected')
              BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              // Dashed lines background optional
              Center(child: content),
            ],
          ),
        ),
      ),
    );
  }
}
