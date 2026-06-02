import '../entities/driver.dart';
import '../entities/dispatch_request.dart';
import '../value_objects/geo_location.dart';

abstract class IDriverScorer {
  Future<List<DriverScore>> scoreDrivers({
    required List<Driver> availableDrivers,
    required GeoLocation pickupLocation,
    required GeoLocation dropoffLocation,
  });
}

abstract class IAutoDispatcher {
  Future<void> findAndAssignDriver(String dispatchRequestId, String branchId);

  Stream<DispatchRequest> watchDispatchRequest(String orderId);
}