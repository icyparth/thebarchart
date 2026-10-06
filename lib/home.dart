import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool showPercentage = false;
  bool isLoading = true;

  List<Map<String, dynamic>> data = [];

  final List<String> selectedStates = [
    'Uttar Pradesh',
    'Madhya Pradesh',
    'Rajasthan',
    'Meghalaya',
    'Kerala',
  ];

  @override
  void initState() {
    super.initState();
    loadCsvData();
  }

  Future<void> loadCsvData() async {
    String csvString = await rootBundle.loadString(
      'assets/states_forest_tree_cover.csv',
    );

    List<List<dynamic>> rows = csv.decode(csvString);

    Map<String, Map<String, dynamic>> stateData = {};

    for (int i = 1; i < rows.length; i++) {
      String state = rows[i][0].toString();
      String category = rows[i][1].toString();

      if (!selectedStates.contains(state)) {
        continue;
      }

      if (!stateData.containsKey(state)) {
        stateData[state] = {'state': state};
      }

      if (category == 'Area') {
        stateData[state]!['treeArea'] = double.parse(rows[i][2].toString());

        stateData[state]!['forestArea'] = double.parse(rows[i][3].toString());
      }

      if (category == 'Percentage of Geographical area') {
        stateData[state]!['treePercent'] = double.parse(rows[i][2].toString());

        stateData[state]!['forestPercent'] = double.parse(
          rows[i][3].toString(),
        );
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      data.clear();

      for (final state in selectedStates) {
        if (stateData.containsKey(state)) {
          data.add(stateData[state]!);
        }
      }

      isLoading = false;
    });
  }

  double getMaxY() {
    double highest = 0;

    for (final item in data) {
      double forest = showPercentage
          ? item['forestPercent']
          : item['forestArea'];
      double tree = showPercentage ? item['treePercent'] : item['treeArea'];
      double total = forest + tree;

      if (total > highest) {
        highest = total;
      }
    }

    return highest * 1.1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forest & Tree Cover'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Area (km²)')),
                      ButtonSegment(value: true, label: Text('Percentage (%)')),
                    ],
                    selected: {showPercentage},
                    onSelectionChanged: (value) {
                      setState(() {
                        showPercentage = value.first;
                      });
                    },
                  ),

                  const SizedBox(height: 30),

                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.square,
                        color: Color.fromARGB(255, 50, 105, 52),
                      ),
                      SizedBox(width: 5),
                      Text('Forest Cover'),
                      SizedBox(width: 20),
                      Icon(Icons.square, color: Colors.lightGreen),
                      SizedBox(width: 5),
                      Text('Tree Cover'),
                    ],
                  ),

                  const SizedBox(height: 30),

                  Expanded(
                    child: BarChart(
                      BarChartData(
                        maxY: getMaxY(),
                        barGroups: createBarGroups(),

                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),

                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),

                          bottomTitles: AxisTitles(
                            axisNameWidget: const Text(
                              'States',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            axisNameSize: 30,
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              getTitlesWidget: (value, meta) {
                                int index = value.toInt();

                                if (index < 0 || index >= data.length) {
                                  return const SizedBox();
                                }

                                return SideTitleWidget(
                                  meta: meta,
                                  space: 8,
                                  child: Text(data[index]['state']),
                                );
                              },
                            ),
                          ),

                          leftTitles: AxisTitles(
                            axisNameWidget: Text(
                              showPercentage ? 'Percentage (%)' : 'Area (km²)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            axisNameSize: 35,
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 70,
                              getTitlesWidget: (value, meta) {
                                if (value == meta.max) {
                                  return const SizedBox();
                                }

                                if (showPercentage) {
                                  return Text('${value.toInt()}%');
                                }

                                return Text(value.toInt().toString());
                              },
                            ),
                          ),
                        ),

                        gridData: const FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  List<BarChartGroupData> createBarGroups() {
    return List.generate(data.length, (index) {
      double forest = showPercentage
          ? data[index]['forestPercent']
          : data[index]['forestArea'];
      double tree = showPercentage
          ? data[index]['treePercent']
          : data[index]['treeArea'];
      double total = forest + tree;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: total,
            width: 35,
            rodStackItems: [
              BarChartRodStackItem(
                0,
                forest,
                const Color.fromARGB(255, 50, 105, 52),
              ),
              BarChartRodStackItem(forest, total, Colors.lightGreen),
            ],
          ),
        ],
      );
    });
  }
}
