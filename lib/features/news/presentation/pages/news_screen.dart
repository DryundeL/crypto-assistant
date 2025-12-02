import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/news_viewmodel.dart';
import '../widgets/news_article_card.dart';
import 'package:crypto_assistant/l10n/app_localizations.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsViewModel>().loadNews();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.news),
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
          child: Consumer<NewsViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (viewModel.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(viewModel.error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => viewModel.refresh(),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => viewModel.refresh(),
                child: viewModel.news.isEmpty
                    ? Center(child: Text(l10n.noNews))
                    : ListView.builder(
                        itemCount: viewModel.news.length,
                        itemBuilder: (context, index) {
                          return NewsArticleCard(
                            article: viewModel.news[index],
                          );
                        },
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}
