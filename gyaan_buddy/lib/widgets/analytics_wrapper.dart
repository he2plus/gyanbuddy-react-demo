import 'package:flutter/material.dart';
import '../services/posthog_service.dart';

class AnalyticsWrapper extends StatefulWidget {
  final Widget child;
  final String screenName;
  final Map<String, dynamic>? properties;

  const AnalyticsWrapper({
    super.key,
    required this.child,
    required this.screenName,
    this.properties,
  });

  @override
  State<AnalyticsWrapper> createState() => _AnalyticsWrapperState();
}

class _AnalyticsWrapperState extends State<AnalyticsWrapper> {
  @override
  void initState() {
    super.initState();
    // Track screen view when widget is initialized
    PostHogService.screen(
      widget.screenName,
      properties: widget.properties,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// Convenience function to wrap screens with analytics
Widget withAnalytics(
  Widget child,
  String screenName, {
  Map<String, dynamic>? properties,
}) {
  return AnalyticsWrapper(
    screenName: screenName,
    properties: properties,
    child: child,
  );
}
