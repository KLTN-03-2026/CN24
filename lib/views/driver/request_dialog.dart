import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/ride_request_model.dart';
import '../../repositories/ride_repository.dart';

class DriverRequestDialog extends StatelessWidget {
  final RideRequestModel request;
  final RideRepository _rideRepository = RideRepository();

  DriverRequestDialog({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_taxi, size: 50, color: Colors.blue),
            const SizedBox(height: 15),
            const Text(
              'Có yêu cầu đặt xe mới!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Khách hàng: ${request.customerName}'),
            Text('Điểm đón: ${request.pickupAddress}'),
            Text('Điểm đến: ${request.destinationAddress}'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _rideRepository.updateRideStatus(request.id, RideStatus.rejected);
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Từ chối', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () {
                    _rideRepository.updateRideStatus(request.id, RideStatus.accepted);
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Chấp nhận', style: TextStyle(color: Colors.white)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
