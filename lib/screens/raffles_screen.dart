import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../features/auth/auth_repository.dart';
import '../models/raffle.dart';
import '../services/cloudinary_service.dart';
import '../services/raffles_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_banner.dart';
import '../widgets/cached_image.dart';
import '../widgets/pressable.dart';

class RafflesScreen extends ConsumerStatefulWidget {
  const RafflesScreen({super.key});

  @override
  ConsumerState<RafflesScreen> createState() => _RafflesScreenState();
}

class _RafflesScreenState extends ConsumerState<RafflesScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _filterChip = 'All'; // All | Active | Ending Soon | Ended | Won

  static const _kFilters = ['All', 'Active', 'Ending Soon', 'Ended', 'Won'];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(
      () => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authStateProvider).value;
    final isAdmin = session?.isAdmin == true;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final activeAsync = ref.watch(activeRafflesStreamProvider);
    final endedAsync = ref.watch(winnersHistoryStreamProvider);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0E0E14)
          : theme.colorScheme.surface,
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateRaffleSheet(context),
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.campaign_rounded),
              label: const Text('New raffle'),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.mint,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.mint.withOpacity(0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.confirmation_num_rounded,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'TICKETS',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Raffles 🎟️',
                                style: theme.textTheme.displayMedium,
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (isAdmin)
                            GestureDetector(
                              onTap: () => _showCreateRaffleSheet(context),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(13),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary.withOpacity(0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Search bar ─────────────────────────────────────────
                      Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF16161F)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.07)
                                : Colors.black.withOpacity(0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 14),
                            Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: isDark
                                  ? Colors.white38
                                  : theme.colorScheme.onSurface.withOpacity(
                                      0.35,
                                    ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : theme.colorScheme.onSurface,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search raffles…',
                                  hintStyle: TextStyle(
                                    color: isDark
                                        ? Colors.white38
                                        : theme.colorScheme.onSurface
                                              .withOpacity(0.35),
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              GestureDetector(
                                onTap: () => _searchCtrl.clear(),
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: isDark
                                        ? Colors.white38
                                        : theme.colorScheme.onSurface
                                              .withOpacity(0.35),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Filter chips ────────────────────────────────────────────
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _kFilters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final f = _kFilters[i];
                      final selected = f == _filterChip;
                      return GestureDetector(
                        onTap: () => setState(() => _filterChip = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            gradient: selected
                                ? AppTheme.primaryGradient
                                : null,
                            color: selected
                                ? null
                                : isDark
                                ? const Color(0xFF16161F)
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primary.withOpacity(0.30),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : isDark
                                  ? Colors.white60
                                  : theme.colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // ── Main content ─────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: () async =>
                  Future.delayed(const Duration(milliseconds: 700)),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                children: [
                  // ── Active raffles section ──────────────────────────
                  _buildActiveSection(
                    context,
                    activeAsync,
                    session?.user.uid,
                    isDark,
                    theme,
                  ),

                  // ── Past raffles section ────────────────────────────
                  _buildPastSection(context, endedAsync, isDark, theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _matchesFilter(Raffle r) {
    if (_searchQuery.isNotEmpty &&
        !r.title.toLowerCase().contains(_searchQuery)) {
      return false;
    }
    if (_filterChip == 'All') return true;
    final now = DateTime.now();
    final secsLeft = r.endAt.difference(now).inSeconds;
    switch (_filterChip) {
      case 'Active':
        return r.status == RaffleStatus.active && secsLeft > 0;
      case 'Ending Soon':
        return r.status == RaffleStatus.active &&
            secsLeft > 0 &&
            secsLeft <= 86400;
      case 'Ended':
        return r.status == RaffleStatus.ended;
      case 'Won':
        return r.status == RaffleStatus.ended && r.winningTicketNumber != null;
    }
    return true;
  }

  Widget _buildActiveSection(
    BuildContext context,
    AsyncValue<List<Raffle>> async,
    String? uid,
    bool isDark,
    ThemeData theme,
  ) {
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (raffles) {
        final filtered = raffles.where(_matchesFilter).toList();
        if (filtered.isEmpty &&
            _filterChip != 'All' &&
            _filterChip != 'Active' &&
            _filterChip != 'Ending Soon') {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 14),
              child: Row(
                children: [
                  Text(
                    'Active Raffles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0B1437),
                    ),
                  ),
                  const Spacer(),
                  if (raffles.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${raffles.length} Ongoing',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  'No active raffles right now.',
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 14,
                  ),
                ),
              )
            else
              ...filtered.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _ActiveRaffleCard(
                    raffle: r,
                    uid: uid,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RaffleDetailsScreen(raffle: r),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPastSection(
    BuildContext context,
    AsyncValue<List<Raffle>> async,
    bool isDark,
    ThemeData theme,
  ) {
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (raffles) {
        final filtered = raffles.where(_matchesFilter).toList();
        if (filtered.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 14),
              child: Row(
                children: [
                  Text(
                    'Past Raffles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0B1437),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'View All >',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0C0C14) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.25)
                        : Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: List.generate(filtered.length, (i) {
                  final r = filtered[i];
                  return Column(
                    children: [
                      _PastRaffleRow(
                        raffle: r,
                        isDark: isDark,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RaffleDetailsScreen(raffle: r),
                          ),
                        ),
                      ),
                      if (i < filtered.length - 1)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: isDark
                              ? const Color(0xFF2A2A3C)
                              : const Color(0xFFE5E7EB),
                          indent: 16,
                          endIndent: 16,
                        ),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Future<void> _showCreateRaffleSheet(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final ticketCtrl = TextEditingController(text: '5000');
    final maxCtrl = TextEditingController(text: '2000');
    final prizeCtrl = TextEditingController();
    var startAt = DateTime.now().add(const Duration(hours: 1));
    var endAt = DateTime.now().add(const Duration(days: 7));
    var drawAt = DateTime.now().add(const Duration(days: 7, hours: 1));
    var status = RaffleStatus.draft;
    File? bannerImageFile;
    bool uploading = false;

    Future<DateTime?> pickDateTime(DateTime initial) async {
      final date = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (date == null || !context.mounted) return null;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
      );
      if (time == null) return null;
      return DateTime(date.year, date.month, date.day, time.hour, time.minute);
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final t = Theme.of(ctx);
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: t.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 44,
                              height: 5,
                              decoration: BoxDecoration(
                                color: t.colorScheme.outline.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text('Create raffle', style: t.textTheme.titleLarge),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: titleCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Raffle title',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: descCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                            ),
                            minLines: 2,
                            maxLines: 4,
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final picked = await picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 85,
                              );
                              if (picked != null) {
                                setLocal(() {
                                  bannerImageFile = File(picked.path);
                                });
                              }
                            },
                            child: Container(
                              height: 140,
                              decoration: BoxDecoration(
                                color: t.colorScheme.surfaceContainerHighest
                                    .withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: t.colorScheme.outline.withOpacity(0.4),
                                ),
                              ),
                              child: bannerImageFile != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        bannerImageFile!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate_rounded,
                                          size: 40,
                                          color: t.colorScheme.onSurface
                                              .withOpacity(0.4),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Tap to pick banner image',
                                          style: t.textTheme.bodySmall
                                              ?.copyWith(
                                                color: t.colorScheme.onSurface
                                                    .withOpacity(0.5),
                                              ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: ticketCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Ticket price (UGX)',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: maxCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Total tickets',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: prizeCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Prize details',
                            ),
                          ),
                          const SizedBox(height: 12),
                          _DatePickerRow(
                            label: 'Start',
                            value: startAt,
                            onTap: () async {
                              final v = await pickDateTime(startAt);
                              if (v != null) setLocal(() => startAt = v);
                            },
                          ),
                          _DatePickerRow(
                            label: 'End',
                            value: endAt,
                            onTap: () async {
                              final v = await pickDateTime(endAt);
                              if (v != null) setLocal(() => endAt = v);
                            },
                          ),
                          _DatePickerRow(
                            label: 'Winner draw date',
                            value: drawAt,
                            onTap: () async {
                              final v = await pickDateTime(drawAt);
                              if (v != null) setLocal(() => drawAt = v);
                            },
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<RaffleStatus>(
                            value: status,
                            items: const [
                              DropdownMenuItem(
                                value: RaffleStatus.draft,
                                child: Text('Draft'),
                              ),
                              DropdownMenuItem(
                                value: RaffleStatus.active,
                                child: Text('Active'),
                              ),
                              DropdownMenuItem(
                                value: RaffleStatus.ended,
                                child: Text('Ended'),
                              ),
                            ],
                            onChanged: (v) => setLocal(
                              () => status = v ?? RaffleStatus.draft,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Status',
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: Pressable(
                              onTap: () async {
                                if (!(formKey.currentState?.validate() ??
                                    false))
                                  return;
                                setLocal(() => uploading = true);
                                try {
                                  String bannerUrl = '';
                                  if (bannerImageFile != null) {
                                    final session = ref
                                        .read(authStateProvider)
                                        .value;
                                    final cloud = ref.read(
                                      cloudinaryServiceProvider,
                                    );
                                    final result = await cloud.uploadFile(
                                      bannerImageFile!,
                                      folder:
                                          'citideals/${session?.user.uid}/raffles',
                                    );
                                    bannerUrl = result.secureUrl;
                                  }
                                  final raffle = Raffle(
                                    id: '',
                                    title: titleCtrl.text.trim(),
                                    description: descCtrl.text.trim(),
                                    bannerImage: bannerUrl,
                                    ticketPrice:
                                        double.tryParse(ticketCtrl.text) ?? 0,
                                    maxTickets: int.tryParse(maxCtrl.text) ?? 0,
                                    soldTickets: 0,
                                    startAt: startAt,
                                    endAt: endAt,
                                    prizeDetails: prizeCtrl.text.trim(),
                                    winnerSelectionAt: drawAt,
                                    status: status,
                                  );
                                  await ref
                                      .read(rafflesRepositoryProvider)
                                      .createRaffle(raffle);
                                  if (!context.mounted) return;
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Raffle created'),
                                    ),
                                  );
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  }
                                } finally {
                                  setLocal(() => uploading = false);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: uploading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text(
                                          'Save raffle',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active raffle card (screenshot-matched design)
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveRaffleCard extends ConsumerStatefulWidget {
  final Raffle raffle;
  final String? uid;
  final VoidCallback onTap;
  const _ActiveRaffleCard({
    required this.raffle,
    required this.uid,
    required this.onTap,
  });

  @override
  ConsumerState<_ActiveRaffleCard> createState() => _ActiveRaffleCardState();
}

class _ActiveRaffleCardState extends ConsumerState<_ActiveRaffleCard> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _update();
    });
  }

  void _update() {
    final diff = widget.raffle.endAt.difference(DateTime.now());
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final raffle = widget.raffle;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pct = raffle.maxTickets == 0
        ? 0.0
        : (raffle.soldTickets / raffle.maxTickets).clamp(0.0, 1.0);

    final secsLeft = _remaining.inSeconds;
    final isEndingSoon = secsLeft > 0 && secsLeft <= 86400;
    final isEnded = secsLeft == 0;

    return Pressable(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0C0C14) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.07),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner image with timer badge ──────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: raffle.bannerImage.isNotEmpty
                      ? CachedImage(
                          url: raffle.bannerImage,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          targetWidth: 900,
                          errorPlaceholder: _PlaceholderBanner(isDark: isDark),
                        )
                      : _PlaceholderBanner(isDark: isDark),
                ),
                // Timer badge — top right
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_rounded,
                          size: 13,
                          color: isEndingSoon ? AppTheme.coral : Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isEnded ? 'Ended' : _fmt(_remaining),
                          style: TextStyle(
                            color: isEndingSoon ? AppTheme.coral : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Card body ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + status chip
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          raffle.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0B1437),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isEndingSoon
                              ? AppTheme.coral.withOpacity(0.13)
                              : AppTheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isEndingSoon ? 'Ending Soon' : 'Active',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isEndingSoon
                                ? AppTheme.coral
                                : AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 7,
                      backgroundColor: isDark
                          ? const Color(0xFF1E1E2E)
                          : const Color(0xFFE8EFFE),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${NumberFormat('#,##0').format(raffle.soldTickets)}/${NumberFormat('#,##0').format(raffle.maxTickets)} Sold',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF6478A3),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Past raffle row
// ─────────────────────────────────────────────────────────────────────────────

class _PastRaffleRow extends StatelessWidget {
  final Raffle raffle;
  final bool isDark;
  final VoidCallback onTap;
  const _PastRaffleRow({
    required this.raffle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasWinner = raffle.winningTicketNumber != null;
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: raffle.bannerImage.isNotEmpty
                  ? CachedImage(
                      url: raffle.bannerImage,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      targetWidth: 180,
                      errorPlaceholder: _SmallPlaceholder(isDark: isDark),
                    )
                  : _SmallPlaceholder(isDark: isDark),
            ),
            const SizedBox(width: 12),

            // Middle: title + status chip + winning ticket
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    raffle.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0B1437),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: hasWinner
                          ? AppTheme.mint.withOpacity(0.15)
                          : Colors.grey.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      hasWinner ? 'Won' : 'Ended',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: hasWinner ? AppTheme.mint : Colors.grey,
                      ),
                    ),
                  ),
                  if (raffle.winningTicketNumber != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Winning Ticket: #${raffle.winningTicketNumber}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF6478A3),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Right: ticket count
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Your Entries',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white38 : const Color(0xFF6478A3),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${NumberFormat('#,##0').format(raffle.soldTickets)} Tickets',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : const Color(0xFF0B1437),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Placeholder widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceholderBanner extends StatelessWidget {
  final bool isDark;
  const _PlaceholderBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      color: isDark ? const Color(0xFF1A1A2C) : const Color(0xFFEBF0FF),
      child: Icon(
        Icons.confirmation_num_rounded,
        size: 48,
        color: isDark ? Colors.white12 : const Color(0xFFB8CCFF),
      ),
    );
  }
}

class _SmallPlaceholder extends StatelessWidget {
  final bool isDark;
  const _SmallPlaceholder({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      color: isDark ? const Color(0xFF1A1A2C) : const Color(0xFFEBF0FF),
      child: Icon(
        Icons.confirmation_num_rounded,
        size: 24,
        color: isDark ? Colors.white12 : const Color(0xFFB8CCFF),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Raffle detail screen
// ─────────────────────────────────────────────────────────────────────────────

class RaffleDetailsScreen extends ConsumerStatefulWidget {
  final Raffle raffle;
  const RaffleDetailsScreen({super.key, required this.raffle});

  @override
  ConsumerState<RaffleDetailsScreen> createState() =>
      _RaffleDetailsScreenState();
}

class _RaffleDetailsScreenState extends ConsumerState<RaffleDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authStateProvider).value;
    final isAdmin = session?.isAdmin == true;
    // Use live Firestore stream so soldTickets, etc. update in real-time
    final liveRaffle =
        ref.watch(singleRaffleStreamProvider(widget.raffle.id)).value ??
        widget.raffle;
    final raffle = liveRaffle;
    final numFmt = NumberFormat('#,##0', 'en_US');

    // Live data
    final myTicketsAsync = session == null
        ? const AsyncValue<List<RaffleTicket>>.data([])
        : ref.watch(
            myTicketsForRaffleProvider((
              uid: session.user.uid,
              raffleId: raffle.id,
            )),
          );
    final activityAsync = ref.watch(raffleActivityProvider(raffle.id));

    final myTickets = myTicketsAsync.value ?? const [];
    final activity = activityAsync.value ?? const [];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0E0E14)
          : theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── Collapsing header ──
          SliverAppBar(
            expandedHeight: 0,
            pinned: true,
            backgroundColor: isDark
                ? const Color(0xFF0E0E14)
                : theme.colorScheme.surface,
            foregroundColor: isDark
                ? Colors.white
                : theme.colorScheme.onSurface,
            elevation: 0,
            title: Text(
              raffle.title,
              style: TextStyle(
                color: isDark ? Colors.white : theme.colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              if (isAdmin)
                IconButton(
                  icon: Icon(
                    Icons.casino_rounded,
                    color: isDark ? Colors.white : theme.colorScheme.onSurface,
                  ),
                  onPressed: () async {
                    try {
                      await ref
                          .read(rafflesRepositoryProvider)
                          .drawWinnerBackend(raffle.id);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Winner draw requested.')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Banner image ──
                if (raffle.bannerImage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          CachedImage(
                            url: raffle.bannerImage,
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                            targetWidth: 1000,
                            errorPlaceholder: Container(
                              height: 220,
                              color: isDark
                                  ? const Color(0xFF16161F)
                                  : theme.colorScheme.surfaceContainerHighest,
                              child: const Icon(
                                Icons.image_rounded,
                                size: 48,
                                color: Colors.white24,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 80,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.55),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // ── Live badge + title ──
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 7, color: Colors.white),
                          SizedBox(width: 5),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'GRAND FINALE DRAW',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withOpacity(0.55)
                            : theme.colorScheme.onSurface.withOpacity(0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  raffle.title,
                  style: TextStyle(
                    color: isDark ? Colors.white : theme.colorScheme.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Prize Pool: ',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white60
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'UGX ${numFmt.format(raffle.ticketPrice * raffle.maxTickets)}',
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),

                // ── Ticket progress ──
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${numFmt.format(raffle.soldTickets)} sold',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white60
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${numFmt.format(raffle.maxTickets)} total',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white38
                            : theme.colorScheme.onSurface.withOpacity(0.38),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: raffle.maxTickets > 0
                        ? (raffle.soldTickets / raffle.maxTickets).clamp(
                            0.0,
                            1.0,
                          )
                        : 0.0,
                    minHeight: 7,
                    backgroundColor: isDark
                        ? Colors.white12
                        : AppTheme.primary.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.accent,
                    ),
                  ),
                ),

                // ── Your Entries ──
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Entries',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${myTickets.length} TICKETS TOTAL',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                if (myTickets.isNotEmpty && raffle.maxTickets > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Your chance of winning: ${(myTickets.length / raffle.maxTickets * 100).toStringAsFixed(myTickets.length / raffle.maxTickets * 100 < 1 ? 2 : 1)}%',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                _TicketsRow(
                  tickets: myTickets,
                  onBuyMore: session == null
                      ? null
                      : () => _showBuySheet(
                          context,
                          session.user.uid,
                          session.user.displayName ??
                              session.user.email ??
                              'User',
                        ),
                ),

                // ── Live Activity ──
                const SizedBox(height: 28),
                _LiveActivitySection(activity: activity),

                // ── Titan Pack CTA ──
                const SizedBox(height: 20),
                _TitanPackCard(
                  onTap: session == null
                      ? null
                      : () => _buyTitanPack(
                          context,
                          session.user.uid,
                          session.user.displayName ??
                              session.user.email ??
                              'User',
                        ),
                ),
              ]),
            ),
          ),
        ],
      ),

      // ── Bottom buy bar ──
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0E0E14) : theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? const Color(0xFF1E1E2C)
                  : theme.colorScheme.outline.withOpacity(0.15),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: session == null
                  ? null
                  : () => _showBuySheet(
                      context,
                      session.user.uid,
                      session.user.displayName ?? session.user.email ?? 'User',
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              child: const Text('Buy Tickets'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showBuySheet(
    BuildContext context,
    String uid,
    String userName, {
    int initialQty = 1,
  }) async {
    // Always use the latest snapshot so ticket price / remaining count is fresh
    final raffle =
        ref.read(singleRaffleStreamProvider(widget.raffle.id)).value ??
        widget.raffle;
    final qtyCtrl = TextEditingController(text: '$initialQty');
    String method = 'Mobile Money';
    final numFmt = NumberFormat('#,##0', 'en_US');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final qty = (int.tryParse(qtyCtrl.text) ?? 1).clamp(1, 9999);
          final total = qty * raffle.ticketPrice;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          ctx,
                        ).colorScheme.onSurface.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Buy Tickets',
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    // Quantity selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _QtyButton(
                          icon: Icons.remove,
                          onTap: () {
                            final v = (int.tryParse(qtyCtrl.text) ?? 1) - 1;
                            if (v >= 1) {
                              qtyCtrl.text = '$v';
                              setLocal(() {});
                            }
                          },
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                            onChanged: (_) => setLocal(() {}),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _QtyButton(
                          icon: Icons.add,
                          onTap: () {
                            final v = (int.tryParse(qtyCtrl.text) ?? 0) + 1;
                            qtyCtrl.text = '$v';
                            setLocal(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Total: UGX ${numFmt.format(total.round())}',
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: method,
                      items: const [
                        DropdownMenuItem(
                          value: 'Mobile Money',
                          child: Text('Mobile Money'),
                        ),
                        DropdownMenuItem(
                          value: 'Card',
                          child: Text('Card payment'),
                        ),
                        DropdownMenuItem(
                          value: 'Wallet',
                          child: Text('Wallet balance'),
                        ),
                      ],
                      onChanged: (v) => setLocal(() => method = v ?? method),
                      decoration: const InputDecoration(
                        labelText: 'Payment method',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await ref
                                .read(rafflesRepositoryProvider)
                                .buyTickets(
                                  raffle: raffle,
                                  userId: uid,
                                  userName: userName,
                                  quantity: qty,
                                  paymentMethod: method,
                                );
                            if (!context.mounted) return;
                            Navigator.pop(ctx);
                            showAppBanner(
                              context,
                              'Tickets purchased!',
                              type: AppBannerType.success,
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            showAppBanner(
                              context,
                              e.toString(),
                              type: AppBannerType.error,
                            );
                          }
                        },
                        child: const Text('Pay & Generate Tickets'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _buyTitanPack(
    BuildContext context,
    String uid,
    String userName,
  ) {
    return _showBuySheet(context, uid, userName, initialQty: 20);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tickets horizontal row
// ─────────────────────────────────────────────────────────────────────────────

class _TicketsRow extends StatelessWidget {
  final List<RaffleTicket> tickets;
  final VoidCallback? onBuyMore;

  const _TicketsRow({required this.tickets, required this.onBuyMore});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: tickets.length + 1, // +1 for buy button
        itemBuilder: (ctx, i) {
          if (i < tickets.length) {
            final t = tickets[i];
            return _TicketCard(ticketNumber: t.ticketNumber);
          }
          // Buy more card
          return Pressable(
            onTap: onBuyMore,
            child: Container(
              width: 80,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.primary.withOpacity(0.5),
                  width: 1.5,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppTheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'BUY',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final String ticketNumber;

  const _TicketCard({required this.ticketNumber});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    // Format: "RF-10402" → show as "#402-A" style
    final parts = ticketNumber.split('-');
    final display = parts.length >= 2 ? '#${parts.last}' : ticketNumber;

    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1A2C)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            display,
            style: TextStyle(
              color: isDark
                  ? Colors.white70
                  : theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              parts.length >= 2 ? parts.last : ticketNumber,
              style: TextStyle(
                color: isDark ? Colors.white : theme.colorScheme.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ),
          Icon(
            Icons.confirmation_number_rounded,
            color: isDark
                ? Colors.white38
                : theme.colorScheme.onSurface.withOpacity(0.38),
            size: 18,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live Activity section
// ─────────────────────────────────────────────────────────────────────────────

class _LiveActivitySection extends StatelessWidget {
  final List<RaffleActivity> activity;

  const _LiveActivitySection({required this.activity});

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF16161F)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hub_rounded, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'LIVE ACTIVITY',
                style: TextStyle(
                  color: isDark ? Colors.white : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (activity.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No activity yet — be the first!',
                style: TextStyle(
                  color: isDark
                      ? Colors.white38
                      : theme.colorScheme.onSurface.withOpacity(0.38),
                  fontSize: 13,
                ),
              ),
            )
          else
            SizedBox(
              height: 260,
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: activity.length.clamp(0, 5),
                itemBuilder: (_, i) => _ActivityRow(
                  activity: activity[i],
                  relTime: _relativeTime(activity[i].timestamp),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final RaffleActivity activity;
  final String relTime;

  const _ActivityRow({required this.activity, required this.relTime});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final isBot = activity.userName.toLowerCase().contains('bot');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isBot
                  ? (isDark ? const Color(0xFF3D1F6E) : const Color(0xFFEDE0FF))
                  : (isDark
                        ? const Color(0xFF1A2A4A)
                        : theme.colorScheme.primaryContainer),
              border: Border.all(
                color: isBot
                    ? const Color(0xFF8B5CF6).withOpacity(0.5)
                    : AppTheme.primary.withOpacity(0.3),
              ),
            ),
            child: Icon(
              isBot ? Icons.smart_toy_rounded : Icons.person_rounded,
              size: 18,
              color: isBot ? const Color(0xFF8B5CF6) : AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? Colors.white70
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                children: [
                  TextSpan(
                    text: activity.userName,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (isBot)
                    TextSpan(
                      text: ' Verified ticket pool: ',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withOpacity(0.7)
                            : theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    )
                  else
                    TextSpan(
                      text: ' just bought ',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withOpacity(0.7)
                            : theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  if (!isBot)
                    TextSpan(
                      text:
                          '${activity.ticketsBought} ticket${activity.ticketsBought > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Color(0xFFFFAA00),
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else
                    TextSpan(
                      text:
                          '${NumberFormat('#,##0').format(activity.ticketsBought * 1000)} Entries',
                      style: const TextStyle(
                        color: Color(0xFFFFAA00),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            relTime,
            style: TextStyle(
              color: isDark
                  ? Colors.white38
                  : theme.colorScheme.onSurface.withOpacity(0.38),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Titan Pack CTA
// ─────────────────────────────────────────────────────────────────────────────

class _TitanPackCard extends StatelessWidget {
  final VoidCallback? onTap;

  const _TitanPackCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFAA44CC), Color(0xFFE0608A)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          // Trophy watermark
          Positioned(
            right: 18,
            top: 16,
            child: Icon(
              Icons.emoji_events_rounded,
              size: 64,
              color: Colors.white.withOpacity(0.15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 100, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Increase Your Odds!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Buy the "Titan Pack" now to get 20 bonus entries instantly.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Pressable(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'GET TITAN PACK',
                          style: TextStyle(
                            color: Color(0xFFAA44CC),
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.bolt_rounded,
                          color: Color(0xFFAA44CC),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Qty stepper button
// ─────────────────────────────────────────────────────────────────────────────

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 20),
      ),
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  final String label;
  final DateTime value;
  final VoidCallback onTap;
  const _DatePickerRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      title: Text(label),
      subtitle: Text(DateFormat.yMMMd().add_jm().format(value)),
      trailing: const Icon(Icons.edit_calendar_rounded),
    );
  }
}
