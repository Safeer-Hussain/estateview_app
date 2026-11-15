import 'package:flutter_test/flutter_test.dart';
import 'package:estate_view_app/data/models/mortgage_calc_model.dart';
import 'package:estate_view_app/presentation/roi_analyzer/bloc/mortgage_roi_cubit.dart';

void main() {
  group('MortgageRoiCubit & MortgageCalcModel Unit Tests', () {
    late MortgageRoiCubit cubit;

    setUp(() {
      cubit = MortgageRoiCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test(
      '1. Default model computes realistic initial EMI and positive yield',
      () {
        final state = cubit.state;
        expect(state.purchasePrice, 850000.0);
        expect(state.downPaymentPercent, 25.0);
        expect(state.interestRate, 6.5);
        expect(state.tenureYears, 20);

        // Loan = 850,000 * 0.75 = 637,500
        expect(state.model.loanAmount, 637500.0);
        expect(state.model.downPaymentAmount, 212500.0);

        // Monthly EMI for 637,500 @ 6.5% for 20 yrs is around 4752
        expect(state.model.monthlyEmi, greaterThan(4700.0));
        expect(state.model.monthlyEmi, lessThan(4800.0));

        // Yields
        expect(state.model.grossRentalYieldPercent, greaterThan(6.0));
        expect(state.model.netRentalYieldPercent, greaterThan(4.5));
      },
    );

    test('2. Updating parameters updates computed values reactively', () {
      cubit.updateParameters(
        purchasePrice: 1000000.0,
        downPaymentPercent: 20.0,
        interestRate: 6.0,
        tenureYears: 30,
        monthlyRentalIncome: 6000.0,
      );

      final state = cubit.state;
      expect(state.purchasePrice, 1000000.0);
      expect(state.model.downPaymentAmount, 200000.0);
      expect(state.model.loanAmount, 800000.0);

      // 800,000 @ 6% for 30 yrs EMI is ~4,796
      expect(state.model.monthlyEmi, greaterThan(4750.0));
      expect(state.model.monthlyEmi, lessThan(4850.0));

      // Gross yield: (6000 * 12) / 1,000,000 = 7.2%
      expect(state.model.grossRentalYieldPercent, closeTo(7.2, 0.05));
    });

    test('3. Amortization schedule has exactly 1 entry per tenure year', () {
      final calc = MortgageCalcModel.compute(
        purchasePrice: 500000.0,
        downPaymentPercent: 20.0,
        interestRate: 5.0,
        tenureYears: 15,
        monthlyRentalIncome: 3000.0,
      );

      expect(calc.amortizationSchedule.length, 15);
      expect(calc.amortizationSchedule.first.year, 1);
      expect(calc.amortizationSchedule.last.year, 15);
      expect(
        calc.amortizationSchedule.last.remainingBalance,
        closeTo(0.0, 1.0),
      );
    });

    test(
      '4. Currency toggle preserves financial ratios across USD and PKR',
      () {
        cubit.updateParameters(isPkr: false);
        final initialYield = cubit.state.model.grossRentalYieldPercent;

        cubit.toggleCurrency(true);
        expect(cubit.state.isPkr, isTrue);
        expect(
          cubit.state.model.grossRentalYieldPercent,
          closeTo(initialYield, 0.1),
        );
      },
    );

    test('5. Zero or 100% down payment edge case is guarded safely', () {
      final calc = MortgageCalcModel.compute(
        purchasePrice: 500000.0,
        downPaymentPercent: 80.0,
        interestRate: 0.0,
        tenureYears: 10,
        monthlyRentalIncome: 2500.0,
      );

      expect(calc.loanAmount, 100000.0);
      expect(calc.totalInterest, 0.0);
      expect(calc.monthlyEmi, closeTo(100000.0 / 120.0, 0.01));
    });
  });
}
