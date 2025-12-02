import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:crypto_assistant/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/crypto_coin_entity.dart';
import '../../domain/repositories/i_crypto_repository.dart';
import 'package:crypto_assistant/features/settings/presentation/viewmodels/settings_viewmodel.dart';

class CoinDetailScreen extends StatefulWidget {
  final CryptoCoinEntity coin;

  const CoinDetailScreen({super.key, required this.coin});

  @override
  State<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends State<CoinDetailScreen> {
  String _selectedPeriod = '1D';
  List<List<double>>? _chartData;
  bool _isLoading = true;
  double? _selectedPrice;
  int? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    setState(() => _isLoading = true);
    try {
      final repository = Provider.of<ICryptoRepository>(context, listen: false);
      final data = await repository.getMarketChart(widget.coin.id, _selectedPeriod, widget.coin.currentPrice);
      setState(() {
        _chartData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onPeriodChanged(String period) {
    if (_selectedPeriod != period) {
      setState(() => _selectedPeriod = period);
      _loadChartData();
    }
  }

  String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toLowerCase()) {
      case 'eur':
        return '€';
      case 'gbp':
        return '£';
      case 'jpy':
        return '¥';
      case 'rub':
        return '₽';
      case 'usd':
      default:
        return '\$';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPositive = widget.coin.priceChangePercentage24h >= 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = Provider.of<SettingsViewModel>(context).currency;
    final symbol = _getCurrencySymbol(currency);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.coin.name),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black,
        ),
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1a1a2e),
                    const Color(0xFF16213e),
                    const Color(0xFF0f3460),
                  ]
                : [
                    const Color(0xFFe3f2fd),
                    const Color(0xFFbbdefb),
                    const Color(0xFF90caf9),
                  ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepPurple.withOpacity(0.4),
                              Colors.deepPurple.withOpacity(0.2),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.deepPurple.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(widget.coin.image),
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '$symbol${(_selectedPrice ?? widget.coin.currentPrice).toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isPositive
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isPositive
                                ? Colors.green.withOpacity(0.3)
                                : Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: _selectedDate != null
                            ? Text(
                                DateFormat('MM/dd HH:mm').format(
                                    DateTime.fromMillisecondsSinceEpoch(_selectedDate!)),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark ? Colors.white70 : Colors.grey.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            : Text(
                                '${isPositive ? '+' : ''}${widget.coin.priceChangePercentage24h.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isPositive ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildPeriodSelector(l10n, isDark),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.white.withOpacity(0.4),
                      ),
                    ),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _chartData == null || _chartData!.isEmpty
                            ? const Center(child: Text('No chart data'))
                            : LineChart(
                                LineChartData(
                                  lineTouchData: LineTouchData(
                                    touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                                      if (event is FlPanEndEvent) {
                                        setState(() {
                                          _selectedPrice = null;
                                          _selectedDate = null;
                                        });
                                        return;
                                      }
                                      if (touchResponse != null && touchResponse.lineBarSpots != null && touchResponse.lineBarSpots!.isNotEmpty) {
                                        final spot = touchResponse.lineBarSpots!.first;
                                        setState(() {
                                          _selectedPrice = spot.y;
                                          _selectedDate = spot.x.toInt();
                                        });
                                      }
                                    },
                                    handleBuiltInTouches: true,
                                    touchTooltipData: LineTouchTooltipData(
                                      getTooltipItems: (touchedSpots) {
                                        return touchedSpots.map((LineBarSpot touchedSpot) {
                                          return LineTooltipItem(
                                            '$symbol${touchedSpot.y.toStringAsFixed(2)}',
                                            const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        }).toList();
                                      },
                                    ),
                                  ),
                                  gridData: const FlGridData(show: false),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 30,
                                        interval: _selectedPeriod == '1D' || _selectedPeriod == '3D' ? 3600000 * 4 : 86400000 * 5,
                                        getTitlesWidget: (value, meta) {
                                          final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                                          String text;
                                          if (_selectedPeriod == '1D' || _selectedPeriod == '3D') {
                                            text = DateFormat('HH:mm').format(date);
                                          } else {
                                            text = DateFormat('MM/dd').format(date);
                                          }
                                          return SideTitleWidget(
                                            axisSide: meta.axisSide,
                                            child: Text(
                                              text,
                                              style: TextStyle(
                                                color: isDark ? Colors.white60 : Colors.black54,
                                                fontSize: 12,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: _chartData!
                                          .map((e) => FlSpot(e[0], e[1]))
                                          .toList(),
                                      isCurved: true,
                                      color: isDark ? Colors.purpleAccent : Colors.deepPurple,
                                      barWidth: 3,
                                      isStrokeCapRound: true,
                                      dotData: const FlDotData(show: false),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            (isDark ? Colors.purpleAccent : Colors.deepPurple).withOpacity(0.3),
                                            (isDark ? Colors.purpleAccent : Colors.deepPurple).withOpacity(0.0),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(AppLocalizations l10n, bool isDark) {
    final periods = {
      '1D': l10n.chart1D,
      '3D': l10n.chart3D,
      '1W': l10n.chart1W,
      '1M': l10n.chart1M,
      '1Y': l10n.chart1Y,
    };

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: periods.entries.map((entry) {
          final isSelected = _selectedPeriod == entry.key;
          return GestureDetector(
            onTap: () => _onPeriodChanged(entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? Colors.deepPurpleAccent : Colors.white)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Text(
                entry.value,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.deepPurple)
                      : (isDark ? Colors.white60 : Colors.black54),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
