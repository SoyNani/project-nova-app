import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/monitoring/app_monitoring.dart';
import '../core/widgets/organisms/app_bottom_nav.dart';
import '../features/auth/domain/entities/user_entity.dart';
import '../features/auth/presentation/screens/profile_screen.dart';
import '../features/calendar/presentation/screens/conferences_calendar_screen.dart';
import '../features/map/presentation/screens/events_map_screen.dart';
import 'screens/home_screen.dart';

abstract final class ShellTab {
  static const int home = 0;
  static const int calendar = 1;
  static const int map = 2;
  static const int profile = 3;
}

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key, required this.user});

  final UserEntity user;

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _currentIndex = ShellTab.home;

  /// Nombres con los que cada pestaña aparece en Analytics/Crashlytics.
  static const List<String> _screenNames = [
    'home',
    'calendar',
    'map',
    'profile',
  ];

  @override
  void initState() {
    super.initState();
    AppMonitoring.logScreen(_screenNames[_currentIndex]);
  }

  void _select(int index) {
    if (index != _currentIndex) AppMonitoring.logScreen(_screenNames[index]);
    setState(() => _currentIndex = index);
  }

  List<AppNavDestination> _destinations() => [
    AppNavDestination(
      label: 'Inicio',
      icon: Icons.home_outlined,
      builder: (_) => HomeScreen(
        user: widget.user,
        onOpenMap: () => _select(ShellTab.map),
      ),
    ),
    AppNavDestination(
      label: 'Calendario',
      icon: Icons.calendar_today_outlined,
      builder: (_) => ConferencesCalendarScreen(createdBy: widget.user.uid),
    ),
    const AppNavDestination(
      label: 'Mapa',
      icon: Icons.location_on_outlined,
      builder: _mapScreen,
    ),
    AppNavDestination(
      label: 'Perfil',
      icon: Icons.person_outline,
      builder: (_) => ProfileScreen(user: widget.user),
    ),
  ];

  static Widget _mapScreen(BuildContext context) => const EventsMapScreen();

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations();

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          for (var i = 0; i < destinations.length; i++)
            KeyedSubtree(
              key: ValueKey(i),
              child: Builder(builder: destinations[i].builder),
            ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        destinations: destinations,
        currentIndex: _currentIndex,
        onDestinationSelected: _select,
      ),
    );
  }
}
