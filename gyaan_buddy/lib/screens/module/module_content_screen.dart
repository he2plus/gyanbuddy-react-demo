// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../models/module_model.dart';
// import '../../models/subject_model.dart';
// import '../../models/module_content_model.dart';
// import '../../blocs/module_content/module_content_bloc.dart';
// import '../../widgets/background_container.dart';
// import '../../widgets/animated_screen_layout.dart';
// import '../../models/module_chapter_model.dart';
// import '../quiz/quiz_screen.dart';
// import 'theory_screen.dart';
//
// class ModuleContentScreen extends StatefulWidget {
//   final Module module;
//   final Subject subject;
//   final ModuleChapter chapter;
//   const ModuleContentScreen({
//     super.key,
//     required this.module,
//     required this.subject,
//     required this.chapter,
//   });
//
//   @override
//   State<ModuleContentScreen> createState() => _ModuleContentScreenState();
// }
//
// class _ModuleContentScreenState extends State<ModuleContentScreen> {
//   @override
//   void initState() {
//     super.initState();
//     // Load next content when screen initializes (no contentId for initial load)
//     print('🟡 Screen: initState called, trying to access BLoC...');
//     try {
//       final bloc = context.read<ModuleContentBloc>();
//       print('🟡 Screen: BLoC found, dispatching LoadNextContent event...');
//       bloc.add(LoadNextContent(widget.chapter.id));
//     } catch (e) {
//       print('🟡 Screen: Error accessing BLoC: $e');
//     }
//   }
//
//   Future<void> _refreshContent() async {
//     // Get current content from state to pass contentId for refresh
//     final currentState = context.read<ModuleContentBloc>().state;
//     if (currentState is NextContentLoaded) {
//       context.read<ModuleContentBloc>().add(RefreshNextContent(widget.chapter.id, currentState.content.id));
//     } else {
//       context.read<ModuleContentBloc>().add(RefreshNextContent(widget.chapter.id));
//     }
//   }
//
//   Color _getContentTypeColor(String contentType) {
//     switch (contentType.toLowerCase()) {
//       case 'question':
//         return Colors.blue;
//       case 'theory':
//         return Colors.green;
//       case 'quiz':
//         return Colors.purple;
//       case 'exercise':
//         return Colors.orange;
//       case 'video':
//         return Colors.red;
//       case 'audio':
//         return Colors.teal;
//       default:
//         return Colors.grey;
//     }
//   }
//
//   IconData _getContentTypeIcon(String contentType) {
//     switch (contentType.toLowerCase()) {
//       case 'question':
//         return Icons.quiz;
//       case 'theory':
//         return Icons.book;
//       case 'quiz':
//         return Icons.assignment;
//       case 'exercise':
//         return Icons.fitness_center;
//       case 'video':
//         return Icons.video_library;
//       case 'audio':
//         return Icons.headphones;
//       default:
//         return Icons.description;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: BackgroundContainer(
//         overlayColor: Colors.white,
//         opacity: 0.9,
//         child: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [Color(0xFFE3F2FD), Colors.white],
//             ),
//           ),
//           child: SafeArea(
//             child: AnimatedScreenLayout(
//               appBar: _buildTopNavigationBar(),
//               body: RefreshIndicator(
//                 onRefresh: _refreshContent,
//                 child: BlocBuilder<ModuleContentBloc, ModuleContentState>(
//                   builder: (context, state) {
//                     print('🟡 Screen: Received state: ${state.runtimeType}');
//                     return _buildContent(state);
//                   },
//                 ),
//               ),
//               animationDuration: const Duration(milliseconds: 600),
//               animationCurve: Curves.easeOutCubic,
//               enableStaggeredAnimation: true,
//               staggerDelay: const Duration(milliseconds: 100),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTopNavigationBar() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
//       child: Row(
//         children: [
//           // Back Button
//           GestureDetector(
//             onTap: () => Navigator.of(context).pop(),
//             child: Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.1),
//                     spreadRadius: 1,
//                     blurRadius: 4,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: const Icon(
//                 Icons.arrow_back,
//                 color: Colors.black,
//                 size: 20,
//               ),
//             ),
//           ),
//
//           const SizedBox(width: 16),
//
//           // Title
//           Expanded(
//             child: Text(
//               'Next Content',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87,
//               ),
//             ),
//           ),
//
//           // Refresh Button
//           GestureDetector(
//             onTap: _refreshContent,
//             child: Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.1),
//                     spreadRadius: 1,
//                     blurRadius: 4,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: const Icon(
//                 Icons.refresh,
//                 color: Colors.black,
//                 size: 20,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildContent(ModuleContentState state) {
//     if (state is ModuleContentInitial) {
//       return const Center(
//         child: CircularProgressIndicator(),
//       );
//     }
//
//     if (state is NextContentLoading) {
//       return const Center(
//         child: CircularProgressIndicator(),
//       );
//     }
//
//     if (state is NextContentError) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.error_outline,
//               size: 64,
//               color: Colors.red.withOpacity(0.6),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Error',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               state.message,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Colors.grey[600],
//               ),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: () {
//                 // Get current content from state to pass contentId for retry
//                 final currentState = context.read<ModuleContentBloc>().state;
//                 if (currentState is NextContentLoaded) {
//                   context.read<ModuleContentBloc>().add(LoadNextContent(widget.chapter.id, currentState.content.id));
//                 } else {
//                   context.read<ModuleContentBloc>().add(LoadNextContent(widget.chapter.id));
//                 }
//               },
//               child: const Text('Retry'),
//             ),
//           ],
//         ),
//       );
//     }
//
//     if (state is NoNextContent) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.check_circle_outline,
//               size: 64,
//               color: Colors.green.withOpacity(0.6),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'No More Content',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'You have completed all available content for this chapter.',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Colors.grey[600],
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     if (state is NextContentLoaded) {
//       return SingleChildScrollView(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Module Info Card
//             _buildModuleInfoCard(state.content),
//
//             const SizedBox(height: 24),
//
//                                         // Render content based on type
//                             _buildContentByType(state.content),
//           ],
//         ),
//       );
//     }
//
//     // Default case
//     return const Center(
//       child: CircularProgressIndicator(),
//     );
//   }
//
//   Widget _buildModuleInfoCard(ModuleContentItem content) {
//     final subjectColor = _getSubjectColor(widget.subject.name);
//
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           // Module Icon
//           Container(
//             width: 60,
//             height: 60,
//             decoration: BoxDecoration(
//               color: subjectColor.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(
//               Icons.school,
//               size: 32,
//               color: subjectColor,
//             ),
//           ),
//
//           const SizedBox(width: 16),
//
//           // Module Details
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   widget.module.name,
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Next Content Available',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   widget.subject.name,
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                     color: subjectColor,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildContentByType(ModuleContentItem content) {
//     switch (content.contentType.toLowerCase()) {
//       case 'question':
//         return QuizScreen(
//           subject: widget.subject,
//           module: widget.module,
//           chapter: widget.chapter,
//           content: content,
//           // TODO: Add currentQuestionIndex and totalQuestions when available from BLoC
//         );
//       case 'theory':
//         return _buildTheoryCard(content);
//       default:
//         return _buildContentCard(content);
//     }
//   }
//
//   Widget _buildTheoryCard(ModuleContentItem content) {
//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.green.withOpacity(0.2),
//             spreadRadius: 2,
//             blurRadius: 12,
//             offset: const Offset(0, 6),
//           ),
//         ],
//         border: Border.all(
//           color: Colors.green.withOpacity(0.3),
//           width: 2,
//         ),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header Row
//             Row(
//               children: [
//                 Container(
//                   width: 60,
//                   height: 60,
//                   decoration: BoxDecoration(
//                     color: Colors.green.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(15),
//                   ),
//                   child: const Icon(
//                     Icons.book,
//                     color: Colors.green,
//                     size: 32,
//                   ),
//                 ),
//
//                 const SizedBox(width: 20),
//
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Theory Content',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.green,
//                           letterSpacing: 0.5,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Order: ${content.order}',
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 GestureDetector(
//                   onTap: () {
//                     // Navigate to theory screen
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => TheoryScreen(
//                           subject: widget.subject,
//                           module: widget.module,
//                           chapter: widget.chapter,
//                           content: content,
//                         ),
//                       ),
//                     );
//                   },
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                     decoration: BoxDecoration(
//                       color: Colors.green.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: const Text(
//                       'START',
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.green,
//                         letterSpacing: 1.0,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 24),
//
//             // Content Title
//             Text(
//               content.contentTitle,
//               style: const TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87,
//               ),
//             ),
//
//             const SizedBox(height: 16),
//
//             // Content Preview
//             Text(
//               content.contentPreview,
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Colors.grey[700],
//                 height: 1.5,
//               ),
//             ),
//
//             const SizedBox(height: 24),
//
//             // Action Button
//             GestureDetector(
//               onTap: () {
//                 // Navigate to theory screen
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => TheoryScreen(
//                       subject: widget.subject,
//                       module: widget.module,
//                       chapter: widget.chapter,
//                       content: content,
//                     ),
//                   ),
//                 );
//               },
//               child: Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 decoration: BoxDecoration(
//                   color: Colors.green,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Center(
//                   child: Text(
//                     'Start Theory',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildNextContentCard(ModuleContentItem content) {
//     return _buildContentCard(content);
//   }
//
//   Widget _buildContentCard(ModuleContentItem content) {
//     final contentTypeColor = _getContentTypeColor(content.contentType);
//     final contentTypeIcon = _getContentTypeIcon(content.contentType);
//
//     return GestureDetector(
//       onTap: () {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Tapped on ${content.contentTypeDisplay}'),
//             duration: const Duration(seconds: 1),
//           ),
//         );
//       },
//       child: Container(
//         width: double.infinity,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//               color: contentTypeColor.withOpacity(0.2),
//               spreadRadius: 2,
//               blurRadius: 12,
//               offset: const Offset(0, 6),
//             ),
//           ],
//           border: Border.all(
//             color: contentTypeColor.withOpacity(0.3),
//             width: 2,
//           ),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header Row with Icon, Type, and Order
//               Row(
//                 children: [
//                   Container(
//                     width: 60,
//                     height: 60,
//                     decoration: BoxDecoration(
//                       color: contentTypeColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(15),
//                     ),
//                     child: Icon(
//                       contentTypeIcon,
//                       color: contentTypeColor,
//                       size: 32,
//                     ),
//                   ),
//
//                   const SizedBox(width: 20),
//
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           content.contentTypeDisplay,
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             color: contentTypeColor,
//                             letterSpacing: 0.5,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           'Order: ${content.order}',
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   GestureDetector(
//                     onTap: () {
//                       // Get next content after the current content
//                       context.read<ModuleContentBloc>().add(LoadNextContent(widget.chapter.id, content.id));
//                     },
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: contentTypeColor.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Text(
//                         'NEXT',
//                         style: TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.bold,
//                           color: contentTypeColor,
//                           letterSpacing: 1.0,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//
//               const SizedBox(height: 24),
//
//               // Content Title
//               Text(
//                 content.contentTitle,
//                 style: const TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                 ),
//               ),
//
//               const SizedBox(height: 16),
//
//               // Content Preview
//               Text(
//                 content.contentPreview,
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.grey[700],
//                   height: 1.5,
//                 ),
//               ),
//
//               const SizedBox(height: 24),
//
//               // Action Button
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 decoration: BoxDecoration(
//                   color: contentTypeColor,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Center(
//                   child: Text(
//                     'Start ${content.contentTypeDisplay}',
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Color _getSubjectColor(String subjectName) {
//     final name = subjectName.toLowerCase();
//     if (name.contains('math') || name.contains('mathematics')) {
//       return Colors.blue;
//     } else if (name.contains('science')) {
//       return Colors.purple;
//     } else if (name.contains('economics')) {
//       return Colors.orange;
//     } else if (name.contains('history')) {
//       return Colors.brown;
//     } else if (name.contains('english')) {
//       return Colors.indigo;
//     } else if (name.contains('geography')) {
//       return Colors.teal;
//     } else {
//       return Colors.grey;
//     }
//   }
// }
