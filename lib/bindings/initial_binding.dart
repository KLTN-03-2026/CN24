import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/customer_home_controller.dart';
import '../controllers/driver_home_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/vehicle_profile_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core
    Get.put(AuthController(), permanent: true);
    
    // Core & Permanent Controllers
    Get.put(CustomerHomeController(), permanent: true);
    Get.put(DriverHomeController(), permanent: true);
    Get.lazyPut(() => VehicleProfileController(), fenix: true);
  }
}
