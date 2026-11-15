import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/currency_formatter.dart';
import '../bloc/mortgage_roi_cubit.dart';

class MortgageRoiView extends StatelessWidget {
  const MortgageRoiView({super.key});

  void _copyRoiReport(BuildContext context, MortgageRoiState state) {
    final currencySymbol = state.isPkr ? 'PKR' : '\$';
    final report =
        '''
=============================================
ESTATEVIEW MORTGAGE & ROI ANALYSIS DOSSIER
=============================================
Purchase Price: $currencySymbol ${state.purchasePrice.toStringAsFixed(0)}
Down Payment (${state.downPaymentPercent.toStringAsFixed(0)}%): $currencySymbol ${state.model.downPaymentAmount.toStringAsFixed(0)}
Loan Balance: $currencySymbol ${state.model.loanAmount.toStringAsFixed(0)}
Annual Markup / Interest Rate: ${state.interestRate.toStringAsFixed(2)}%
Tenure: ${state.tenureYears} Years (${state.tenureYears * 12} Months)

FINANCIAL PROJECTIONS:
• Monthly EMI Debt Service: $currencySymbol ${state.model.monthlyEmi.toStringAsFixed(0)}
• Total Interest Payable: $currencySymbol ${state.model.totalInterest.toStringAsFixed(0)}
• Expected Monthly Rental: $currencySymbol ${state.monthlyRentalIncome.toStringAsFixed(0)}

YIELD & RETURNS:
• Gross Rental Yield: ${state.model.grossRentalYieldPercent.toStringAsFixed(2)}%
• Net Rental Yield: ${state.model.netRentalYieldPercent.toStringAsFixed(2)}%
• Cash-on-Cash Annual ROI: ${state.model.cashOnCashRoiPercent.toStringAsFixed(2)}%
• Break-Even Holding Horizon: ${state.model.breakEvenYears < 90 ? '${state.model.breakEvenYears.toStringAsFixed(1)} Years' : 'Neutral / Negative Cash Flow'}

Amortization Schedule:
${state.model.amortizationSchedule.take(5).map((p) => 'Year ${p.year}: Principal Paid $currencySymbol${p.principalPaid.toStringAsFixed(0)} | Remaining $currencySymbol${p.remainingBalance.toStringAsFixed(0)}').join('\n')}
=============================================
''';

    Clipboard.setData(ClipboardData(text: report));
    AppFeedback.showSuccess(
      context,
      'ROI & Amortization Report copied to clipboard.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return BlocBuilder<MortgageRoiCubit, MortgageRoiState>(
      builder: (context, state) {
        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            heroTag: AppConstants.fabRoiExportDossier,
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            onPressed: () => _copyRoiReport(context, state),
            icon: const Icon(Icons.copy, size: 18),
            label: const Text(
              'Copy ROI Report',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          body: isLandscape
              ? _buildLandscapeLayout(context, colors, state)
              : _buildPortraitLayout(context, colors, state),
        );
      },
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    ColorScheme colors,
    MortgageRoiState state,
  ) {
    final cubit = context.read<MortgageRoiCubit>();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Currency Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Financial Modeling Cockpit',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.outlineVariant),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: [
                    _buildCurrencyChip(context, 'USD', !state.isPkr, () {
                      cubit.toggleCurrency(false);
                    }),
                    _buildCurrencyChip(context, 'PKR', state.isPkr, () {
                      cubit.toggleCurrency(true);
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Primary Financial Highlights Banner (EMI, Net Yield, Cash on Cash)
          _buildFinancialHighlightsBanner(context, colors, state),
          const SizedBox(height: 20),

          // Amortization Schedule Chart (fl_chart) edge-to-edge
          _buildAmortizationChartCard(context, colors, state),
          const SizedBox(height: 20),

          // Synced Sliders & Numeric Inputs
          Text(
            'Underwriting Parameters',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          _buildSliderInputTile(
            context,
            colors,
            title: 'Purchase Price',
            formattedValue: state.isPkr
                ? CurrencyFormatter.formatPkr(state.purchasePrice)
                : CurrencyFormatter.formatUsd(state.purchasePrice),
            value: state.purchasePrice,
            min: state.isPkr ? 10000000 : 100000,
            max: state.isPkr ? 2000000000 : 8000000,
            onChanged: (val) => cubit.updateParameters(purchasePrice: val),
          ),
          const SizedBox(height: 10),

          _buildSliderInputTile(
            context,
            colors,
            title: 'Down Payment',
            formattedValue:
                '${state.downPaymentPercent.toStringAsFixed(0)}% (${state.isPkr ? CurrencyFormatter.formatPkr(state.model.downPaymentAmount) : CurrencyFormatter.formatUsd(state.model.downPaymentAmount)})',
            value: state.downPaymentPercent,
            min: 10,
            max: 80,
            divisions: 14,
            onChanged: (val) => cubit.updateParameters(downPaymentPercent: val),
          ),
          const SizedBox(height: 10),

          _buildSliderInputTile(
            context,
            colors,
            title: 'Interest / Markup Rate',
            formattedValue: '${state.interestRate.toStringAsFixed(1)}%',
            value: state.interestRate,
            min: 3.0,
            max: 22.0,
            divisions: 38,
            onChanged: (val) => cubit.updateParameters(interestRate: val),
          ),
          const SizedBox(height: 10),

          _buildSliderInputTile(
            context,
            colors,
            title: 'Loan Tenure',
            formattedValue: '${state.tenureYears} Years',
            value: state.tenureYears.toDouble(),
            min: 5,
            max: 30,
            divisions: 25,
            onChanged: (val) =>
                cubit.updateParameters(tenureYears: val.round()),
          ),
          const SizedBox(height: 10),

          _buildSliderInputTile(
            context,
            colors,
            title: 'Expected Monthly Rental Income',
            formattedValue: state.isPkr
                ? '${CurrencyFormatter.formatPkr(state.monthlyRentalIncome)}/mo'
                : '${CurrencyFormatter.formatUsd(state.monthlyRentalIncome)}/mo',
            value: state.monthlyRentalIncome,
            min: state.isPkr ? 100000 : 1000,
            max: state.isPkr ? 15000000 : 50000,
            onChanged: (val) =>
                cubit.updateParameters(monthlyRentalIncome: val),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    ColorScheme colors,
    MortgageRoiState state,
  ) {
    final cubit = context.read<MortgageRoiCubit>();

    return Row(
      children: [
        // Left Pane: Chart and Highlights
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFinancialHighlightsBanner(context, colors, state),
                const SizedBox(height: 12),
                _buildAmortizationChartCard(context, colors, state),
              ],
            ),
          ),
        ),

        const VerticalDivider(width: 1),

        // Right Pane: Sliders
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Underwriting Inputs',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                _buildSliderInputTile(
                  context,
                  colors,
                  title: 'Price',
                  formattedValue: state.isPkr
                      ? CurrencyFormatter.formatPkr(state.purchasePrice)
                      : CurrencyFormatter.formatUsd(state.purchasePrice),
                  value: state.purchasePrice,
                  min: state.isPkr ? 10000000 : 100000,
                  max: state.isPkr ? 2000000000 : 8000000,
                  onChanged: (val) =>
                      cubit.updateParameters(purchasePrice: val),
                ),
                const SizedBox(height: 6),
                _buildSliderInputTile(
                  context,
                  colors,
                  title: 'Down Payment',
                  formattedValue:
                      '${state.downPaymentPercent.toStringAsFixed(0)}%',
                  value: state.downPaymentPercent,
                  min: 10,
                  max: 80,
                  divisions: 14,
                  onChanged: (val) =>
                      cubit.updateParameters(downPaymentPercent: val),
                ),
                const SizedBox(height: 6),
                _buildSliderInputTile(
                  context,
                  colors,
                  title: 'Interest Rate',
                  formattedValue: '${state.interestRate.toStringAsFixed(1)}%',
                  value: state.interestRate,
                  min: 3.0,
                  max: 22.0,
                  divisions: 38,
                  onChanged: (val) => cubit.updateParameters(interestRate: val),
                ),
                const SizedBox(height: 6),
                _buildSliderInputTile(
                  context,
                  colors,
                  title: 'Tenure',
                  formattedValue: '${state.tenureYears} Yrs',
                  value: state.tenureYears.toDouble(),
                  min: 5,
                  max: 30,
                  divisions: 25,
                  onChanged: (val) =>
                      cubit.updateParameters(tenureYears: val.round()),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyChip(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialHighlightsBanner(
    BuildContext context,
    ColorScheme colors,
    MortgageRoiState state,
  ) {
    final emiStr = state.isPkr
        ? CurrencyFormatter.formatPkr(state.model.monthlyEmi)
        : CurrencyFormatter.formatUsd(state.model.monthlyEmi);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(color: colors.shadow.withOpacity(0.06), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly EMI Installment',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$emiStr / mo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${state.model.cashOnCashRoiPercent.toStringAsFixed(1)}% Cash-on-Cash',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: colors.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          // Yields Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricSubItem(
                context,
                'Gross Yield',
                '${state.model.grossRentalYieldPercent.toStringAsFixed(2)}%',
                colors.onSurface,
              ),
              _buildMetricSubItem(
                context,
                'Net Yield',
                '${state.model.netRentalYieldPercent.toStringAsFixed(2)}%',
                colors.primary,
              ),
              _buildMetricSubItem(
                context,
                'Break-Even',
                state.model.breakEvenYears < 90
                    ? '${state.model.breakEvenYears.toStringAsFixed(1)} Yrs'
                    : 'Neutral',
                colors.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricSubItem(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAmortizationChartCard(
    BuildContext context,
    ColorScheme colors,
    MortgageRoiState state,
  ) {
    final spotsRemaining = state.model.amortizationSchedule.map((pt) {
      return FlSpot(pt.year.toDouble(), pt.remainingBalance);
    }).toList();

    final spotsPrincipal = state.model.amortizationSchedule.map((pt) {
      return FlSpot(pt.year.toDouble(), pt.principalPaid);
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'Amortization Trajectory',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, color: colors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Balance',
                    style: TextStyle(
                      fontSize: 10,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(width: 8, height: 8, color: colors.secondary),
                  const SizedBox(width: 4),
                  Text(
                    'Principal',
                    style: TextStyle(
                      fontSize: 10,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Edge-to-edge chart with reservedSize: 0 on hidden axes
          SizedBox(
            height: 170,
            width: double.infinity,
            child: LineChart(
              LineChartData(
                lineTouchData: const LineTouchData(enabled: true),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colors.outlineVariant.withOpacity(0.5),
                    strokeWidth: 0.8,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false, reservedSize: 0),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false, reservedSize: 0),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (val, meta) {
                        return Text(
                          val >= 1000000
                              ? '${(val / 1000000).toStringAsFixed(1)}M'
                              : '${(val / 1000).toStringAsFixed(0)}k',
                          style: TextStyle(
                            fontSize: 9,
                            color: colors.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      interval: 5,
                      getTitlesWidget: (val, meta) {
                        return Text(
                          'Y${val.toInt()}',
                          style: TextStyle(
                            fontSize: 9,
                            color: colors.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spotsRemaining,
                    isCurved: true,
                    color: colors.primary,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: colors.primary.withOpacity(0.12),
                    ),
                  ),
                  LineChartBarData(
                    spots: spotsPrincipal,
                    isCurved: true,
                    color: colors.secondary,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderInputTile(
    BuildContext context,
    ColorScheme colors, {
    required String title,
    required String formattedValue,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formattedValue,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              activeColor: colors.primary,
              inactiveColor: colors.outlineVariant,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
