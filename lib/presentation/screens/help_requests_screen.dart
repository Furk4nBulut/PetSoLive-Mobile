import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../blocs/help_request_cubit.dart';
import '../widgets/help_request_card.dart';
import '../../core/network/auth_service.dart';
import 'add_help_request_screen.dart';
import '../../core/constants/admob_banner_widget.dart';

class HelpRequestsScreen extends StatefulWidget {
  const HelpRequestsScreen({Key? key}) : super(key: key);

  @override
  State<HelpRequestsScreen> createState() => _HelpRequestsScreenState();
}

class _HelpRequestsScreenState extends State<HelpRequestsScreen> {
  final List<String> baseTabs = [
    'help_requests.tab_all',
    'help_requests.tab_low',
    'help_requests.tab_medium',
    'help_requests.tab_high',
  ];

  bool _showFab = false;
  Map<String, dynamic>? _user;

  List<String> getTabs(bool showMyAds) {
    if (showMyAds) {
      return [...baseTabs, 'help_requests.tab_my_ads']; // En sağda
    }
    return baseTabs;
  }

  @override
  void initState() {
    super.initState();
    _checkUserLoggedIn();
    Future.microtask(() => context.read<HelpRequestCubit>().getAll(forceRefresh: true));
  }

  Future<void> _checkUserLoggedIn() async {
    final authService = AuthService();
    final user = await authService.getUser();
    setState(() {
      _user = user;
      _showFab = user != null && user['id'] != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: BlocBuilder<HelpRequestCubit, HelpRequestState>(
        builder: (context, state) {
          List<dynamic> helpRequests = [];
          bool hasMore = false;
          if (state is HelpRequestLoaded) {
            helpRequests = state.helpRequests;
            hasMore = state.hasMore;
          }
          final userId = _user != null ? _user!['id'] : null;
          final hasMyAds = userId != null && helpRequests.any((e) => e.userId == userId);
          final tabs = getTabs(hasMyAds);

          return DefaultTabController(
            key: ValueKey(tabs.length),
            length: tabs.length,
            child: Column(
              children: [
                TabBar(
                  tabs: tabs.map((e) => Tab(text: e.tr())).toList(),
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: colorScheme.primary,
                ),
                AdmobBannerWidget(),
                Expanded(
                  child: TabBarView(
                    children: tabs.map((selectedTab) {
                      List<dynamic> filtered;
                      bool tabHasMore = hasMore;
                      if (selectedTab == 'help_requests.tab_my_ads') {
                        filtered = helpRequests.where((e) => e.userId == userId).toList();
                        tabHasMore = false; // Only show paging for 'all' tab
                      } else if (selectedTab == 'help_requests.tab_all') {
                        filtered = helpRequests;
                        tabHasMore = hasMore;
                      } else {
                        final level = selectedTab.replaceAll('help_requests.tab_', '').toLowerCase();
                        filtered = helpRequests.where((e) => e.emergencyLevel.toString().split('.').last == level).toList();
                        tabHasMore = false;
                      }
                      if (state is HelpRequestLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is HelpRequestError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, color: Colors.red, size: 48),
                              const SizedBox(height: 12),
                              Text('help_requests.error'.tr(), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.red)),
                              const SizedBox(height: 8),
                              Text(state.error.toString(), style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                            ],
                          ),
                        );
                      }
                      if (filtered.isEmpty) {
                        return Center(child: Text('help_requests.empty').tr());
                      }
                      return NotificationListener<ScrollNotification>(
                        onNotification: (scrollInfo) {
                          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent && tabHasMore) {
                            context.read<HelpRequestCubit>().loadMore();
                          }
                          return false;
                        },
                        child: RefreshIndicator(
                          onRefresh: () async {
                            await context.read<HelpRequestCubit>().getAll(forceRefresh: true);
                            setState(() {});
                          },
                          child: ListView.builder(
                            itemCount: filtered.length + (tabHasMore ? 1 : 0),
                            itemBuilder: (context, i) {
                              if (i < filtered.length) {
                                final req = filtered[i];
                                return HelpRequestCard(
                                  request: req,
                                  onTap: () async {
                                    final result = await Navigator.of(context).pushNamed('/help_request', arguments: req.id);
                                    if (result == true && context.mounted) {
                                      await context.read<HelpRequestCubit>().getAll();
                                      setState(() {});
                                    }
                                  },
                                );
                              } else {
                                return const Center(child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ));
                              }
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _showFab
          ? FloatingActionButton(
              heroTag: 'help_requests_fab',
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: context.read<HelpRequestCubit>()),
                      ],
                      child: AddHelpRequestScreen(),
                    ),
                  ),
                );
                if (context.mounted) {
                  await context.read<HelpRequestCubit>().getAll();
                  setState(() {});
                }
              },
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              child: const Icon(Icons.add, size: 28),
              tooltip: 'help_requests.add'.tr(),
            )
          : null,
    );
  }
} 