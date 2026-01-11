import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> getUserId() async {
  // Create an instance of UUID
  var uuid = Uuid();

  // Access Shared Preferences
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // Check if the UUID is already stored
  String? storedUserId = prefs.getString('user_id');

  if (storedUserId == null) {
    // Generate a new UUID and store it
    String newUserId = uuid.v4();
    await prefs.setString('user_id', newUserId);
    return newUserId;
  } else {
    // Return the existing UUID
    return storedUserId;
  }
}
