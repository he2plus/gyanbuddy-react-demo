import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'ui_utils.dart';

/// Common screen patterns to eliminate repetitive code
class ScreenPatterns {
  
  // ==================== BLOC CONSUMER PATTERNS ====================

  /// Standard BlocConsumer pattern for error handling
  static Widget buildBlocConsumerWithErrorHandling<T extends BlocBase<S>, S>({
    required Widget Function(BuildContext context, S state) builder,
    required void Function(BuildContext context, S state) listener,
    String? errorMessage,
  }) {
    return BlocConsumer<T, S>(
      listener: (context, state) {
        // Handle error states
        if (state.toString().contains('Error')) {
          UIUtils.showErrorSnackBar(
            context,
            errorMessage ?? 'An error occurred. Please try again.',
          );
        }
        listener(context, state);
      },
      builder: builder,
    );
  }

  /// Loading state pattern
  static Widget buildLoadingState({
    String? message,
    Color? color,
  }) {
    return UIUtils.buildLoadingWidget(
      message: message,
      color: color,
    );
  }

  /// Error state pattern
  static Widget buildErrorState(
    String message, {
    VoidCallback? onRetry,
  }) {
    return UIUtils.buildErrorWidget(
      message,
      onRetry: onRetry,
    );
  }

  /// Empty state pattern
  static Widget buildEmptyState(
    String message, {
    IconData icon = Icons.inbox_outlined,
    VoidCallback? onAction,
    String? actionText,
  }) {
    return UIUtils.buildEmptyStateWidget(
      message,
      icon: icon,
      onAction: onAction,
      actionText: actionText,
    );
  }

  // ==================== SCREEN LAYOUT PATTERNS ====================

  /// Standard screen with app bar and body
  static Widget buildStandardScreen({
    required Widget body,
    String? title,
    List<Widget>? actions,
    Widget? floatingActionButton,
    Widget? bottomNavigationBar,
    PreferredSizeWidget? appBar,
    Color? backgroundColor,
    bool extendBodyBehindAppBar = false,
  }) {
    return Scaffold(
      backgroundColor: backgroundColor ?? Colors.white,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar ?? (title != null ? AppBar(
        title: Text(title),
        actions: actions,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ) : null),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }

  /// Screen with background container
  static Widget buildScreenWithBackground({
    required Widget body,
    String? title,
    List<Widget>? actions,
    Widget? floatingActionButton,
    Widget? bottomNavigationBar,
    Color overlayColor = Colors.white,
    double opacity = 0.9,
  }) {
    return UIUtils.buildScreenWithBackground(
      child: body,
      appBar: title != null ? AppBar(
        title: Text(title),
        actions: actions,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ) : null,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      overlayColor: overlayColor,
      opacity: opacity,
    );
  }

  // ==================== LIST PATTERNS ====================

  /// Standard list item with divider
  static Widget buildListItem({
    required Widget child,
    EdgeInsets? padding,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: child,
      ),
    );
  }

  /// List with pull-to-refresh
  static Widget buildRefreshableList({
    required Widget child,
    required Future<void> Function() onRefresh,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: child,
    );
  }

  // ==================== FORM PATTERNS ====================

  /// Standard form field
  static Widget buildFormField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    int? maxLines,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      maxLines: maxLines ?? 1,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        suffixIcon: suffixIcon,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  /// Form with validation
  static Widget buildForm({
    required GlobalKey<FormState> formKey,
    required List<Widget> children,
    required VoidCallback onSubmit,
    String? submitText,
    bool isLoading = false,
  }) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          ...children,
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              child: isLoading
                  ? UIUtils.buildButtonLoadingWidget()
                  : Text(submitText ?? 'Submit'),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== CARD PATTERNS ====================

  /// Standard card with padding
  static Widget buildCard({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? color,
    double? elevation,
  }) {
    return Card(
      color: color,
      elevation: elevation ?? 2,
      margin: margin ?? const EdgeInsets.all(8),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  /// Info card with icon and text
  static Widget buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return buildCard(
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? Colors.blue,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
          ],
        ),
      ),
    );
  }

  // ==================== BUTTON PATTERNS ====================

  /// Primary action button
  static Widget buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    Color? color,
    double? width,
  }) {
    return SizedBox(
      width: width ?? double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? UIUtils.buildButtonLoadingWidget()
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  /// Secondary action button
  static Widget buildSecondaryButton({
    required String text,
    required VoidCallback onPressed,
    Color? color,
    double? width,
  }) {
    return SizedBox(
      width: width ?? double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color ?? Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ==================== DIALOG PATTERNS ====================

  /// Confirmation dialog
  static Future<bool?> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) {
    return UIUtils.showCustomDialog<bool>(
      context: context,
      title: title,
      content: message,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    );
  }

  /// Loading dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(
              child: Text(message ?? 'Loading...'),
            ),
          ],
        ),
      ),
    );
  }

  /// Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }
}
