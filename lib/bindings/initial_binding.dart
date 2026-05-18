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
    
    // Lazy Controllers
    Get.lazyPut(() => CustomerHomeController(), fenix: true);
    Get.lazyPut(() => DriverHomeController(), fenix: true);
    Get.lazyPut(() => VehicleProfileController(), fenix: true);
  }
}
