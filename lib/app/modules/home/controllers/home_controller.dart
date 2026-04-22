import 'package:get/get.dart';

class ParkingSlot {
  final String id;
  final String label;
  String status; // 'available', 'blocked', 'occupied', 'selected'
  final bool isHandicap;

  ParkingSlot({
    required this.id,
    required this.label,
    this.status = 'available',
    this.isHandicap = false,
  });
}

class HomeController extends GetxController {
  // User Info
  final userName = "MUHAMMAD WAHYUDI".obs;
  final userId = "JK001".obs;
  final userPoints = 700.obs;

  // Wallet
  final walletBalance = "45K".obs;
  final bankPoints = "30.000".obs;

  // Zones
  final zones = ["Zona A", "Zona B", "Zona C", "Zona D", "Zona E"].obs;
  final currentZone = "Zona A".obs;

  // Parking Slots
  final slots = <ParkingSlot>[].obs;
  final selectedSlot = Rxn<ParkingSlot>();

  // Loading state
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadSlots();
  }

  void loadSlots() {
    isLoading.value = true;
    // Mock data based on image
    // Left Column
    var data = [
      ParkingSlot(id: 'A001', label: 'A 001', status: 'blocked'),
      ParkingSlot(id: 'A002', label: 'A 002', status: 'available'),
      ParkingSlot(id: 'A003', label: 'A 003', status: 'occupied'), // Car
      ParkingSlot(id: 'A004', label: 'A 004', status: 'occupied'), // Car
      ParkingSlot(id: 'A008', label: 'A 008', status: 'available', isHandicap: true),

      // Right Column
      ParkingSlot(id: 'A009', label: 'A 009', status: 'available'),
      ParkingSlot(id: 'A010', label: 'A 010', status: 'occupied'), // Car
      ParkingSlot(id: 'A011', label: 'A 011', status: 'occupied'), // Car
      ParkingSlot(id: 'A014', label: 'A 014', status: 'available'),
      ParkingSlot(id: 'A013', label: 'A 013', status: 'selected'),
      ParkingSlot(id: 'A012', label: 'A 012', status: 'available', isHandicap: true),
      ParkingSlot(id: 'A015', label: 'A 015', status: 'available'),
    ];

    // Simulate API delay
    Future.delayed(Duration(milliseconds: 500), () {
      slots.value = data;
      isLoading.value = false;
    });
  }

  void selectZone(String zone) {
    currentZone.value = zone;
    loadSlots(); // Reload slots for new zone
  }

  void toggleSlotSelection(ParkingSlot slot) {
    if (slot.status == 'blocked' || slot.status == 'occupied') return;

    // Deselect others
    for (var s in slots) {
      if (s.status == 'selected') {
        s.status = 'available';
      }
    }

    // Select new
    if (selectedSlot.value == slot) {
      selectedSlot.value = null;
    } else {
      slot.status = 'selected';
      selectedSlot.value = slot;
    }
    slots.refresh();
  }
}
