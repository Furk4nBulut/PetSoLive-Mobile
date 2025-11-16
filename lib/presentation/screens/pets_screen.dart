import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../blocs/pet_cubit.dart';
import '../blocs/account_cubit.dart';
import '../../injection_container.dart';
import '../../data/models/pet_list_item.dart';
import 'pets/pet_tab_bar.dart';
import 'pets/pet_search_bar.dart';
import 'pets/pet_list_tab.dart';
import '../../core/constants/admob_banner_widget.dart';

class PetsScreen extends StatelessWidget {
  const PetsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PetCubit(sl())..fetchPets(reset: true),
      child: _PetsScreenBody(),
    );
  }
}

class _PetsScreenBody extends StatefulWidget {
  @override
  State<_PetsScreenBody> createState() => _PetsScreenBodyState();
}

class _PetsScreenBodyState extends State<_PetsScreenBody> with TickerProviderStateMixin {
  late TabController _tabController;
  int? currentUserId;
  String? speciesFilter;
  String? colorFilter;
  String? breedFilter;
  String? searchQuery;
  String? adoptedStatusFilter;
  List<PetListItem> _allPets = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final accountState = context.watch<AccountCubit>().state;
    if (accountState is AccountSuccess) {
      currentUserId = accountState.response.user.id;
    } else {
      currentUserId = null;
    }
  }

  void _updateTabController(int tabCount) {
    if (_tabController.length != tabCount) {
      final oldIndex = _tabController.index;
      _tabController.dispose();
      _tabController = TabController(length: tabCount, vsync: this);
      _tabController.index = oldIndex.clamp(0, tabCount - 1);
      _tabController.addListener(_onTabChanged);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _fetchTabPets(reset: true);
    }
  }

  void _fetchTabPets({bool reset = false}) {
    final cubit = context.read<PetCubit>();
    String? adoptedStatus;
    if (_tabController.index == 1) adoptedStatus = 'owned';
    if (_tabController.index == 2) adoptedStatus = 'waiting';
    cubit.fetchPets(
      reset: reset,
      adoptedStatus: adoptedStatusFilter ?? adoptedStatus,
      species: speciesFilter,
      color: colorFilter,
      breed: breedFilter,
      search: searchQuery,
    );
  }

  void _openFilterModal(BuildContext context) async {
    String? tempSpecies = speciesFilter;
    String? tempColor = colorFilter;
    String? tempBreed = breedFilter;
    String? tempAdoptedStatus = adoptedStatusFilter;

    final speciesOptions = <String?>[null, 'Kedi', 'Köpek', 'Kuş', 'Hamster'];
    final colorOptions = <String?>[null, 'Siyah', 'Beyaz', 'Kahverengi', 'Sarı', 'Gri'];
    final breedOptions = <String?>[null, 'Tekir', 'Golden', 'Sarman', 'Haski', 'Papağan'];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16, right: 16, top: 24),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text('pets.filter'.tr(), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 18),
                    Text('pets.species'.tr(), style: Theme.of(context).textTheme.labelLarge),
                    DropdownButtonFormField<String>(
                      value: tempSpecies,
                      isDense: true,
                      decoration: InputDecoration(
                        hintText: 'pets.all'.tr(),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      items: speciesOptions.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s ?? 'pets.all'.tr()),
                      )).toList(),
                      onChanged: (v) => setModalState(() => tempSpecies = v),
                    ),
                    const SizedBox(height: 14),
                    Text('pets.color'.tr(), style: Theme.of(context).textTheme.labelLarge),
                    DropdownButtonFormField<String>(
                      value: tempColor,
                      isDense: true,
                      decoration: InputDecoration(
                        hintText: 'pets.all'.tr(),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      items: colorOptions.map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c ?? 'pets.all'.tr()),
                      )).toList(),
                      onChanged: (v) => setModalState(() => tempColor = v),
                    ),
                    const SizedBox(height: 14),
                    Text('pets.breed'.tr(), style: Theme.of(context).textTheme.labelLarge),
                    DropdownButtonFormField<String>(
                      value: tempBreed,
                      isDense: true,
                      decoration: InputDecoration(
                        hintText: 'pets.all'.tr(),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      items: breedOptions.map((b) => DropdownMenuItem(
                        value: b,
                        child: Text(b ?? 'pets.all'.tr()),
                      )).toList(),
                      onChanged: (v) => setModalState(() => tempBreed = v),
                    ),
                    const SizedBox(height: 14),
                    Text('pets.adopted_status'.tr(), style: Theme.of(context).textTheme.labelLarge),
                    DropdownButtonFormField<String>(
                      value: tempAdoptedStatus,
                      isDense: true,
                      decoration: InputDecoration(
                        hintText: 'pets.all'.tr(),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      items: [
                        DropdownMenuItem(value: null, child: Text('pets.all'.tr())),
                        DropdownMenuItem(value: 'owned', child: Text('pets.owned'.tr())),
                        DropdownMenuItem(value: 'waiting', child: Text('pets.waiting'.tr())),
                      ],
                      onChanged: (v) => setModalState(() => tempAdoptedStatus = v),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              speciesFilter = null;
                              colorFilter = null;
                              breedFilter = null;
                              adoptedStatusFilter = null;
                            });
                            _fetchTabPets(reset: true);
                            Navigator.pop(context);
                          },
                          child: Text('pets.clear'.tr()),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              speciesFilter = tempSpecies;
                              colorFilter = tempColor;
                              breedFilter = tempBreed;
                              adoptedStatusFilter = tempAdoptedStatus;
                            });
                            // Eğer sahiplenme durumu seçildiyse, tabı da ona göre değiştir
                            if (tempAdoptedStatus == 'owned') {
                              _tabController.animateTo(1);
                            } else if (tempAdoptedStatus == 'waiting') {
                              _tabController.animateTo(2);
                            } else {
                              _tabController.animateTo(0);
                            }
                            _fetchTabPets(reset: true);
                            Navigator.pop(context);
                          },
                          child: Text('pets.apply'.tr()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Arama kutusu ile searchQuery senkronizasyonu
    if (_controller.text != (searchQuery ?? '')) {
      _controller.text = searchQuery ?? '';
      _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
    }
    return BlocBuilder<PetCubit, PetState>(
      builder: (context, state) {
        if (state is PetLoaded) {
          _allPets = state.pets;
        }
        final myPets = currentUserId == null
            ? <PetListItem>[]
            : _allPets.where((pet) => pet.ownerId == currentUserId).toList();
        final showMyPetsTab = currentUserId != null && myPets.isNotEmpty;
        final tabs = <Tab>[
          Tab(text: 'pets.tab_all'.tr()),
          Tab(text: 'pets.tab_owned'.tr()),
          Tab(text: 'pets.tab_waiting'.tr()),
          if (showMyPetsTab) Tab(text: 'pets.tab_my_pets'.tr()),
        ];
        _updateTabController(tabs.length);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        // Scaffold ile sar ve FAB ekle
        return Scaffold(
          floatingActionButton: FloatingActionButton(
            heroTag: 'addPetFab',
            tooltip: 'pets.add'.tr(),
            child: Icon(Icons.add),
            onPressed: () async {
              if (currentUserId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('pets.login_required'.tr())), // changed key
                );
                await Future.delayed(const Duration(milliseconds: 800));
                if (!mounted) return;
                Navigator.of(context).pushReplacementNamed('/login');
                return;
              }
              final result = await Navigator.of(context).pushNamed('/add_pet');
              if (result == true) {
                context.read<PetCubit>().fetchPets(reset: true);
              }
            },
          ),
          body: Column(
            children: [
              PetTabBar(controller: _tabController, tabs: tabs),
              PetSearchBar(
                controller: _controller,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                  _fetchTabPets(reset: true);
                },
                onFilterPressed: () => _openFilterModal(context),
                isDark: isDark,
              ),
              const AdmobBannerWidget(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    PetListTab(
                      adoptedStatus: null,
                      species: speciesFilter,
                      color: colorFilter,
                      breed: breedFilter,
                      search: searchQuery,
                      currentUserId: currentUserId,
                    ),
                    PetListTab(
                      adoptedStatus: 'owned',
                      species: speciesFilter,
                      color: colorFilter,
                      breed: breedFilter,
                      search: searchQuery,
                      currentUserId: currentUserId,
                    ),
                    PetListTab(
                      adoptedStatus: 'waiting',
                      species: speciesFilter,
                      color: colorFilter,
                      breed: breedFilter,
                      search: searchQuery,
                      currentUserId: currentUserId,
                    ),
                    if (showMyPetsTab)
                      PetListTab(
                        adoptedStatus: null,
                        species: speciesFilter,
                        color: colorFilter,
                        breed: breedFilter,
                        search: searchQuery,
                        myPetsOnly: true,
                        currentUserId: currentUserId,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
