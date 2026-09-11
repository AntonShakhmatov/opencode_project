import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:app_mobile/providers/review_provider.dart';
import 'package:app_mobile/screens/rate_job_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('rate job screen renders with title', (tester) async {
    final reviewProvider = ReviewProvider();
    await reviewProvider.restoreRatedJobs();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: reviewProvider),
        ],
        child: const MaterialApp(
          home: RateJobScreen(
            jobId: 'job-1',
            revieweeId: 'handyman-1',
            revieweeName: 'John',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rate Job'), findsOneWidget);
    expect(find.text('Rate John'), findsOneWidget);
    expect(find.text('Submit Review'), findsOneWidget);
  });

  testWidgets('submitting review marks job as rated', (tester) async {
    final reviewProvider = ReviewProvider();
    await reviewProvider.restoreRatedJobs();
    expect(reviewProvider.isRated('job-1'), isFalse);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: reviewProvider),
        ],
        child: const MaterialApp(
          home: RateJobScreen(
            jobId: 'job-1',
            revieweeId: 'handyman-1',
            revieweeName: 'John',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('How was your experience?'), findsOneWidget);
    expect(reviewProvider.isRated('job-1'), isFalse);
  });
}