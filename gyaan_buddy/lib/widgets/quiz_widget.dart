import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/quiz/quiz_bloc.dart';
import '../models/quiz_models.dart';

class QuizWidget extends StatefulWidget {
  const QuizWidget({super.key});

  @override
  State<QuizWidget> createState() => _QuizWidgetState();
}

class _QuizWidgetState extends State<QuizWidget> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Notify QuizBloc about lifecycle changes
    final quizBloc = context.read<QuizBloc>();
    if (state == AppLifecycleState.paused) {
      quizBloc.add(const AppPaused());
    } else if (state == AppLifecycleState.resumed) {
      quizBloc.add(const AppResumed());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QuizBloc, QuizState>(
      listener: (context, state) {
        if (state is QuizError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        if (state is QuizInitial) {
          return _buildInitialState(context);
        } else if (state is QuizLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is QuizLoaded) {
          return _buildQuizLoaded(context, state);
        } else if (state is QuizFinished) {
          return _buildQuizFinished(context, state);
        } else if (state is QuizError) {
          return _buildErrorState(context, state);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildInitialState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Welcome to GyaanBuddy!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              context.read<QuizBloc>().add(const LoadQuiz('1'));
            },
            child: const Text('Start Quiz'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizLoaded(BuildContext context, QuizLoaded state) {
    final currentQuestion = state.currentQuestion;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Timer and Score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Time: ${state.timeRemaining.inMinutes}:${(state.timeRemaining.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (state.isPausedByBackground) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.pause, color: Colors.orange, size: 16),
                    const Text('Paused', style: TextStyle(color: Colors.orange, fontSize: 12)),
                  ],
                ],
              ),
              Text(
                'Score: ${state.score}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Question Progress
          LinearProgressIndicator(
            value: (state.currentQuestionIndex + 1) / state.quiz.questions.length,
          ),
          const SizedBox(height: 10),
          Text(
            'Question ${state.currentQuestionIndex + 1} of ${state.quiz.questions.length}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 30),
          
          // Question
          Text(
            currentQuestion.questionText,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          
          // Options
          ...currentQuestion.options.map((option) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.hasAnsweredCurrentQuestion ? null : () {
                  final startTime = DateTime.now();
                  context.read<QuizBloc>().add(AnswerQuestion(
                    answer: option.optionText,
                    timeTaken: DateTime.now().difference(startTime),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: Text(
                  option.optionText,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )).toList(),
          
          const SizedBox(height: 30),
          
          // Navigation Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!state.isFirstQuestion)
                ElevatedButton(
                  onPressed: () {
                    context.read<QuizBloc>().add(const PreviousQuestion());
                  },
                  child: const Text('Previous'),
                )
              else
                const SizedBox.shrink(),
              
              if (state.isLastQuestion)
                ElevatedButton(
                  onPressed: () {
                    context.read<QuizBloc>().add(const FinishQuiz());
                  },
                  child: const Text('Finish Quiz'),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    context.read<QuizBloc>().add(const NextQuestion());
                  },
                  child: const Text('Next'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuizFinished(BuildContext context, QuizFinished state) {
    final result = state.result;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Quiz Completed!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Score: ${result.score}/${result.totalQuestions}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text('Percentage: ${result.percentage.toStringAsFixed(1)}%'),
                    const SizedBox(height: 10),
                    Text('Correct Answers: ${result.correctAnswers}'),
                    const SizedBox(height: 10),
                    Text('Wrong Answers: ${result.wrongAnswers}'),
                    const SizedBox(height: 10),
                    Text('Time Taken: ${result.timeTaken.inMinutes}:${(result.timeTaken.inSeconds % 60).toString().padLeft(2, '0')}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.read<QuizBloc>().add(const ResetQuiz());
              },
              child: const Text('Take Another Quiz'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, QuizError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error: ${state.message}',
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              context.read<QuizBloc>().add(const ResetQuiz());
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
