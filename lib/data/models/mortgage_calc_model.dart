import 'dart:math';

class AmortizationYearPoint {
  final int year;
  final double principalPaid;
  final double interestPaid;
  final double remainingBalance;

  const AmortizationYearPoint({
    required this.year,
    required this.principalPaid,
    required this.interestPaid,
    required this.remainingBalance,
  });
}

class MortgageCalcModel {
  final double purchasePrice;
  final double downPaymentPercent;
  final double interestRate;
  final int tenureYears;
  final double monthlyRentalIncome;
  final bool isPkr;

  final double downPaymentAmount;
  final double loanAmount;
  final double monthlyEmi;
  final double totalPayment;
  final double totalInterest;
  final double grossRentalYieldPercent;
  final double netRentalYieldPercent;
  final double cashOnCashRoiPercent;
  final double breakEvenYears;
  final List<AmortizationYearPoint> amortizationSchedule;

  MortgageCalcModel._({
    required this.purchasePrice,
    required this.downPaymentPercent,
    required this.interestRate,
    required this.tenureYears,
    required this.monthlyRentalIncome,
    required this.isPkr,
    required this.downPaymentAmount,
    required this.loanAmount,
    required this.monthlyEmi,
    required this.totalPayment,
    required this.totalInterest,
    required this.grossRentalYieldPercent,
    required this.netRentalYieldPercent,
    required this.cashOnCashRoiPercent,
    required this.breakEvenYears,
    required this.amortizationSchedule,
  });

  factory MortgageCalcModel.compute({
    required double purchasePrice,
    required double downPaymentPercent,
    required double interestRate,
    required int tenureYears,
    required double monthlyRentalIncome,
    bool isPkr = false,
  }) {
    final downPayment = purchasePrice * (downPaymentPercent / 100.0);
    final loan = purchasePrice - downPayment;
    final monthlyRate = (interestRate / 100.0) / 12.0;
    final totalMonths = tenureYears * 12;

    double emi = 0.0;
    if (loan > 0) {
      if (monthlyRate > 0) {
        emi =
            loan *
            (monthlyRate * pow(1 + monthlyRate, totalMonths)) /
            (pow(1 + monthlyRate, totalMonths) - 1);
      } else {
        emi = loan / totalMonths;
      }
    }

    final totalPaid = (emi * totalMonths) + downPayment;
    final totalInt = max(0.0, (emi * totalMonths) - loan);

    // Yield Calculations
    final annualRent = monthlyRentalIncome * 12.0;
    final grossYield = purchasePrice > 0
        ? (annualRent / purchasePrice) * 100.0
        : 0.0;

    // Maintenance & property tax buffer (~1.5% of value annually)
    final operatingExpenses = purchasePrice * 0.015;
    final netAnnualIncome = annualRent - operatingExpenses;
    final netYield = purchasePrice > 0
        ? (netAnnualIncome / purchasePrice) * 100.0
        : 0.0;

    // Cash on cash ROI: (Net Annual Income - Annual Mortgage Payments) / Initial Cash Invested
    final annualMortgage = emi * 12.0;
    final annualCashFlow = netAnnualIncome - annualMortgage;
    final cashOnCash = downPayment > 0
        ? (annualCashFlow / downPayment) * 100.0
        : 0.0;

    // Break-even years
    final breakEven = annualCashFlow > 0
        ? (downPayment / annualCashFlow)
        : 99.0;

    // Compute Amortization Schedule
    final schedule = <AmortizationYearPoint>[];
    double currentBalance = loan;

    for (int yr = 1; yr <= tenureYears; yr++) {
      double yrPrincipal = 0.0;
      double yrInterest = 0.0;

      for (int m = 1; m <= 12; m++) {
        if (currentBalance <= 0) break;
        final interestForMonth = currentBalance * monthlyRate;
        final principalForMonth = min(currentBalance, emi - interestForMonth);
        yrInterest += interestForMonth;
        yrPrincipal += principalForMonth;
        currentBalance -= principalForMonth;
      }

      schedule.add(
        AmortizationYearPoint(
          year: yr,
          principalPaid: yrPrincipal,
          interestPaid: yrInterest,
          remainingBalance: max(0.0, currentBalance),
        ),
      );
    }

    return MortgageCalcModel._(
      purchasePrice: purchasePrice,
      downPaymentPercent: downPaymentPercent,
      interestRate: interestRate,
      tenureYears: tenureYears,
      monthlyRentalIncome: monthlyRentalIncome,
      isPkr: isPkr,
      downPaymentAmount: downPayment,
      loanAmount: loan,
      monthlyEmi: emi,
      totalPayment: totalPaid,
      totalInterest: totalInt,
      grossRentalYieldPercent: grossYield,
      netRentalYieldPercent: netYield,
      cashOnCashRoiPercent: cashOnCash,
      breakEvenYears: breakEven,
      amortizationSchedule: schedule,
    );
  }
}
