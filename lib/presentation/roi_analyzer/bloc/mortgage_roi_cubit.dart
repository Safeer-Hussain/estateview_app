import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/mortgage_calc_model.dart';
import '../../../data/models/property_model.dart';

class MortgageRoiState {
  final double purchasePrice;
  final double downPaymentPercent;
  final double interestRate;
  final int tenureYears;
  final double monthlyRentalIncome;
  final bool isPkr;
  final MortgageCalcModel model;

  const MortgageRoiState({
    required this.purchasePrice,
    required this.downPaymentPercent,
    required this.interestRate,
    required this.tenureYears,
    required this.monthlyRentalIncome,
    required this.isPkr,
    required this.model,
  });

  factory MortgageRoiState.initial() {
    const price = AppConstants.defaultPriceUsd;
    const downPercent = AppConstants.defaultDownPaymentPercent;
    const rate = AppConstants.defaultInterestRate;
    const tenure = AppConstants.defaultTenureYears;
    const rent = AppConstants.defaultMonthlyRentalIncome;

    final computed = MortgageCalcModel.compute(
      purchasePrice: price,
      downPaymentPercent: downPercent,
      interestRate: rate,
      tenureYears: tenure,
      monthlyRentalIncome: rent,
      isPkr: false,
    );

    return MortgageRoiState(
      purchasePrice: price,
      downPaymentPercent: downPercent,
      interestRate: rate,
      tenureYears: tenure,
      monthlyRentalIncome: rent,
      isPkr: false,
      model: computed,
    );
  }

  MortgageRoiState copyWith({
    double? purchasePrice,
    double? downPaymentPercent,
    double? interestRate,
    int? tenureYears,
    double? monthlyRentalIncome,
    bool? isPkr,
    MortgageCalcModel? model,
  }) {
    return MortgageRoiState(
      purchasePrice: purchasePrice ?? this.purchasePrice,
      downPaymentPercent: downPaymentPercent ?? this.downPaymentPercent,
      interestRate: interestRate ?? this.interestRate,
      tenureYears: tenureYears ?? this.tenureYears,
      monthlyRentalIncome: monthlyRentalIncome ?? this.monthlyRentalIncome,
      isPkr: isPkr ?? this.isPkr,
      model: model ?? this.model,
    );
  }
}

class MortgageRoiCubit extends Cubit<MortgageRoiState> {
  MortgageRoiCubit() : super(MortgageRoiState.initial());

  void updateParameters({
    double? purchasePrice,
    double? downPaymentPercent,
    double? interestRate,
    int? tenureYears,
    double? monthlyRentalIncome,
    bool? isPkr,
  }) {
    final price = purchasePrice ?? state.purchasePrice;
    final downPercent = downPaymentPercent ?? state.downPaymentPercent;
    final rate = interestRate ?? state.interestRate;
    final tenure = tenureYears ?? state.tenureYears;
    final rent = monthlyRentalIncome ?? state.monthlyRentalIncome;
    final pkr = isPkr ?? state.isPkr;

    final computed = MortgageCalcModel.compute(
      purchasePrice: price,
      downPaymentPercent: downPercent,
      interestRate: rate,
      tenureYears: tenure,
      monthlyRentalIncome: rent,
      isPkr: pkr,
    );

    emit(
      state.copyWith(
        purchasePrice: price,
        downPaymentPercent: downPercent,
        interestRate: rate,
        tenureYears: tenure,
        monthlyRentalIncome: rent,
        isPkr: pkr,
        model: computed,
      ),
    );
  }

  void loadForProperty(PropertyModel property, bool isPkr) {
    final price = isPkr ? property.pricePkr : property.priceUsd;
    // Estimated monthly rental: ~0.55% of property value per month
    final estRent = price * 0.0055;

    updateParameters(
      purchasePrice: price,
      monthlyRentalIncome: estRent,
      isPkr: isPkr,
    );
  }

  void toggleCurrency(bool isPkr) {
    if (state.isPkr == isPkr) return;
    // Convert between USD and PKR roughly (1 USD = 278 PKR)
    const rate = 278.0;
    final newPrice = isPkr
        ? state.purchasePrice * rate
        : state.purchasePrice / rate;
    final newRent = isPkr
        ? state.monthlyRentalIncome * rate
        : state.monthlyRentalIncome / rate;

    updateParameters(
      purchasePrice: newPrice,
      monthlyRentalIncome: newRent,
      isPkr: isPkr,
    );
  }
}
