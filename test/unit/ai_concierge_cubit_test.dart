import 'package:flutter_test/flutter_test.dart';
import 'package:estate_view_app/presentation/ai_concierge/bloc/ai_concierge_cubit.dart';

import '../helpers/mock_repositories.dart';

void main() {
  group('AiConciergeCubit Unit Tests', () {
    late MockAppDatabase mockDb;
    late MockPropertyRepository mockPropertyRepo;
    late MockTourRepository mockTourRepo;
    late MockArMeasurementRepository mockArRepo;
    late AiConciergeCubit cubit;

    setUp(() {
      mockDb = MockAppDatabase();
      mockPropertyRepo = MockPropertyRepository();
      mockTourRepo = MockTourRepository();
      mockArRepo = MockArMeasurementRepository();

      cubit = AiConciergeCubit(
        mockDb,
        mockPropertyRepo,
        mockTourRepo,
        mockArRepo,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('1. Initial state has welcome message and isStreaming is false', () {
      expect(cubit.state.isStreaming, isFalse);
      expect(cubit.state.messages.length, 1);
      expect(
        cubit.state.messages.first.content,
        contains('Welcome to EstateView AI Concierge'),
      );
      expect(cubit.state.promptShortcuts.length, 4);
    });

    test('2. Sending message sets isStreaming to true and STRICTLY resets to false upon completion', () async {
      final future = cubit.sendMessage(
        'Compare My Shortlisted Properties by ROI & Price/SqFt',
      );

      // While running, isStreaming is active
      expect(cubit.state.isStreaming, isTrue);
      expect(cubit.state.statusIndicator, contains('Evaluating'));

      await future;

      // STRICT RULE CHECK: isStreaming must be false after completion
      expect(cubit.state.isStreaming, isFalse);
      expect(cubit.state.statusIndicator, isEmpty);

      // Verify that synthesized response contains portfolio shortlist citations
      final lastMsg = cubit.state.messages.last;
      expect(lastMsg.sender, 'concierge');
      expect(lastMsg.content, contains('Portfolio Shortlist Synthesis'));
      expect(lastMsg.content, contains('The Cantilever Courtyard Villa'));
    });

    test('3. Query regarding mortgage produces debt service audit', () async {
      await cubit.sendMessage('Audit Mortgage Affordability & Rental Yield');

      expect(cubit.state.isStreaming, isFalse);
      final lastMsg = cubit.state.messages.last;
      expect(lastMsg.content, contains('Affordability & Debt Service Audit'));
      expect(lastMsg.content, contains('Debt Service Coverage Ratio'));
    });

    test('4. Clear chat resets state to initial welcome message', () async {
      await cubit.sendMessage('Hello Concierge');
      expect(cubit.state.messages.length, greaterThan(2));

      await cubit.clearChat();
      expect(cubit.state.messages.length, 1);
      expect(cubit.state.messages.first.id, 'welcome-01');
    });
  });
}
