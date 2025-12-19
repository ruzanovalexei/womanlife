import 'package:flutter/material.dart';
// import 'package:period_tracker/l10n/app_localizations.dart';
import 'package:period_tracker/services/cache_service.dart';

class CacheManagementTab extends StatefulWidget {
  const CacheManagementTab({super.key});

  @override
  _CacheManagementTabState createState() => _CacheManagementTabState();
}

class _CacheManagementTabState extends State<CacheManagementTab> {
  final CacheService _cacheService = CacheService();
  bool _isLoading = false;
  Map<String, dynamic> _dbInfo = {};
  Map<String, dynamic> _usageStats = {};
  List<String> _recommendations = [];
  String _databaseSize = 'Загрузка...';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbInfo = await _cacheService.getDatabaseInfo();
      final stats = await _cacheService.getUsageStatistics();
      final recommendations = await _cacheService.getOptimizationRecommendations();
      final formattedSize = await _cacheService.getFormattedDatabaseSize();

      if (mounted) {
        setState(() {
          _dbInfo = dbInfo;
          _usageStats = stats;
          _recommendations = recommendations;
          _databaseSize = formattedSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Ошибка загрузки данных: $e');
      }
    }
  }

  Future<void> _clearCache() async {
    // final l10n = AppLocalizations.of(context)!;
    
    // Показываем диалог подтверждения
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Очистка кеша'),
        content: Text('Вы уверены, что хотите очистить кеш? Это действие удалит старые данные (старше 2 лет).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Очистить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _cacheService.clearCache();
        await _loadData();
        _showSuccessSnackBar('Кеш успешно очищен');
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Ошибка при очистке кеша: $e');
      }
    }
  }

  Future<void> _optimizeDatabase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _cacheService.optimizeDatabase();
      await _loadData();
      _showSuccessSnackBar('База данных успешно оптимизирована');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Ошибка при оптимизации: $e');
    }
  }

  Future<void> _autoCleanup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _cacheService.autoCleanupIfNeeded();
      await _loadData();
      _showSuccessSnackBar('Автоматическая очистка выполнена');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Ошибка при автоматической очистке: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDatabaseSizeCard(),
          const SizedBox(height: 16),
          _buildUsageStatsCard(),
          const SizedBox(height: 16),
          _buildRecommendationsCard(),
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildDatabaseSizeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Размер базы данных',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _databaseSize,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (_dbInfo['tables'] != null) ...[
              Text(
                'Таблицы:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              ..._dbInfo['tables'].entries.map((entry) {
                final tableName = entry.key;
                final tableData = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tableName),
                      Text(
                        '${tableData['rowCount']} записей (${tableData['sizeKB']?.toStringAsFixed(1) ?? '0'} КБ)',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsageStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Статистика использования',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2,
              children: [
                _buildStatItem('Заметки по дням', _usageStats['dayNotes']?.toString() ?? '0'),
                _buildStatItem('Заметки', _usageStats['notes']?.toString() ?? '0'),
                _buildStatItem('Списки', _usageStats['lists']?.toString() ?? '0'),
                _buildStatItem('Лекарства', _usageStats['medications']?.toString() ?? '0'),
                _buildStatItem('Записи лекарств', _usageStats['medicationRecords']?.toString() ?? '0'),
                _buildStatItem('Привычки', 
                  ((_usageStats['habitExecutions'] ?? 0) + (_usageStats['habitMeasurables'] ?? 0)).toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Рекомендации',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._recommendations.map((recommendation) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.arrow_right, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(recommendation),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _clearCache,
            icon: const Icon(Icons.cleaning_services),
            label: const Text('Очистить кеш'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _optimizeDatabase,
            icon: const Icon(Icons.speed),
            label: const Text('Оптимизировать БД'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _autoCleanup,
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Автоочистка'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ),
      ],
    );
  }
}