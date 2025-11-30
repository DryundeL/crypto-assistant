import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:crypto_assistant/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/crypto_coin_entity.dart';
import '../../domain/repositories/i_crypto_repository.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPositive = widget.coin.priceChangePercentage24h >= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.coin.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(widget.coin.image),
                    backgroundColor: Colors.transparent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '\$${(_selectedPrice ?? widget.coin.currentPrice).toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  _selectedDate != null
                      ? Text(
                          DateFormat('MM/dd HH:mm').format(
                              DateTime.fromMillisecondsSinceEpoch(_selectedDate!)),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : Text(
                          '${isPositive ? '+' : ''}${widget.coin.priceChangePercentage24h.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 18,
                            color: isPositive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildPeriodSelector(l10n),
            const SizedBox(height: 16),
            Expanded(
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
                                      '\$${touchedSpot.y.toStringAsFixed(2)}',
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
                                  interval: _selectedPeriod == '1D' || _selectedPeriod == '3D' ? 3600000 * 4 : 86400000 * 5, // Adjust interval based on period
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
                                        style: const TextStyle(
                                          color: Colors.grey,
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
                                color: Colors.deepPurple,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.deepPurple.withOpacity(0.1),
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(AppLocalizations l10n) {
    final periods = {
      '1D': l10n.chart1D,
      '3D': l10n.chart3D,
      '1W': l10n.chart1W,
      '1M': l10n.chart1M,
      '1Y': l10n.chart1Y,
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: periods.entries.map((entry) {
        final isSelected = _selectedPeriod == entry.key;
        return ChoiceChip(
          label: Text(entry.value),
          selected: isSelected,
          onSelected: (_) => _onPeriodChanged(entry.key),
        );
      }).toList(),
    );
  }
}
