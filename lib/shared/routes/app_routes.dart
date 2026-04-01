import 'package:get/get.dart';
import '../../admin/screens/admin_login_screen.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../admin/screens/admin_edit_profile_screen.dart';
import '../../admin/screens/user_detail_screen.dart';
import '../../user/screens/user_login_screen.dart';
import '../../user/screens/user_dashboard_screen.dart';
import '../../user/screens/user_edit_profile_screen.dart';
import '../screens/splash_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String adminLogin = '/admin-login';
  static const String adminDashboard = '/admin-dashboard';
  static const String adminEditProfile = '/admin-edit-profile';
  static const String userDetail = '/user-detail';
  static const String userLogin = '/user-login';
  static const String userDashboard = '/user-dashboard';
  static const String userEditProfile = '/user-edit-profile';

  static final List<GetPage> pages = [
    GetPage(name: splash, page: () => const SplashScreen()),
    GetPage(name: adminLogin, page: () => const AdminLoginScreen()),
    GetPage(name: adminDashboard, page: () => const AdminDashboardScreen()),
    GetPage(name: adminEditProfile, page: () => const AdminEditProfileScreen()),
    GetPage(name: userDetail, page: () => const UserDetailScreen()),
    GetPage(name: userLogin, page: () => const UserLoginScreen()),
    GetPage(name: userDashboard, page: () => const UserDashboardScreen()),
    GetPage(name: userEditProfile, page: () => const UserEditProfileScreen()),
  ];
}
