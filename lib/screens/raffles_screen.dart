import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
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
import '../widgets/countdown_timer.dart';
import '../widgets/pressable.dart';

class RafflesScreen extends ConsumerStatefulWidget {
  const RafflesScreen({super.key});

  @override
  ConsumerState<RafflesScreen> createState() => _RafflesScreenState();
}

class _RafflesScreenState extends ConsumerState<RafflesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authStateProvider).value;
    final isAdmin = session?.isAdmin == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Raffles'),
        actions: [
          if (isAdmin)
            IconButton(
              onPressed: () => _showCreateRaffleSheet(context),
              icon: const Icon(Icons.add_box_rounded),
              tooltip: 'Create raffle',
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'My Tickets'),
            Tab(text: 'Winners'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ActiveRafflesTab(onOpen: _openDetails),
          _MyTicketsTab(uid: session?.user.uid),
          _WinnersTab(),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateRaffleSheet(context),
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.campaign_rounded),
              label: const Text('New raffle'),
            )
          : null,
    );
  }

  void _openDetails(Raffle raffle) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RaffleDetailsScreen(raffle: raffle)),
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

class _ActiveRafflesTab extends ConsumerWidget {
  final ValueChanged<Raffle> onOpen;
  const _ActiveRafflesTab({required this.onOpen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activeRafflesStreamProvider);
    final theme = Theme.of(context);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Failed to load raffles\n$e', textAlign: TextAlign.center),
      ),
      data: (raffles) {
        if (raffles.isEmpty) {
          return Center(
            child: Text(
              'No active raffles.',
              style: theme.textTheme.titleMedium,
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
          itemCount: raffles.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) =>
              _RaffleCard(raffle: raffles[i], onTap: () => onOpen(raffles[i])),
        );
      },
    );
  }
}

class _MyTicketsTab extends ConsumerWidget {
  final String? uid;
  const _MyTicketsTab({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (uid == null) {
      return const Center(child: Text('Sign in to view your tickets.'));
    }
    final async = ref.watch(myRaffleTicketsStreamProvider(uid!));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load tickets\n$e')),
      data: (tickets) {
        if (tickets.isEmpty)
          return const Center(child: Text('No tickets purchased yet.'));
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
          itemCount: tickets.length,
          itemBuilder: (_, i) {
            final t = tickets[i];
            return ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              tileColor: Theme.of(context).colorScheme.surface,
              title: Text(t.ticketNumber),
              subtitle: Text('Raffle: ${t.raffleId}'),
              trailing: Text(DateFormat.yMMMd().add_jm().format(t.purchasedAt)),
            );
          },
        );
      },
    );
  }
}

class _WinnersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(winnersHistoryStreamProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load winners\n$e')),
      data: (raffles) {
        if (raffles.isEmpty)
          return const Center(child: Text('No published winners yet.'));
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
          itemCount: raffles.length,
          itemBuilder: (_, i) {
            final r = raffles[i];
            return ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              tileColor: Theme.of(context).colorScheme.surface,
              title: Text(r.title),
              subtitle: Text(
                'Winning ticket: ${r.winningTicketNumber ?? 'Pending'}',
              ),
              trailing: Text(DateFormat.yMMMd().format(r.winnerSelectionAt)),
            );
          },
        );
      },
    );
  }
}

class RaffleDetailsScreen extends ConsumerWidget {
  final Raffle raffle;
  const RaffleDetailsScreen({super.key, required this.raffle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(authStateProvider).value;
    final isAdmin = session?.isAdmin == true;

    return Scaffold(
      appBar: AppBar(title: Text(raffle.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: raffle.bannerImage.isNotEmpty
                ? Image.network(
                    raffle.bannerImage,
                    height: 200,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 200,
                    decoration: const BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                    ),
                    child: const Icon(
                      Icons.card_giftcard_rounded,
                      color: Colors.white,
                      size: 52,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Text(raffle.description, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 12),
          _KV(
            label: 'Ticket price',
            value: 'UGX ${NumberFormat('#,##0').format(raffle.ticketPrice)}',
          ),
          _KV(
            label: 'Tickets sold',
            value: '${raffle.soldTickets}/${raffle.maxTickets}',
          ),
          _KV(label: 'Prize', value: raffle.prizeDetails),
          _KV(
            label: 'Ends',
            value: DateFormat.yMMMd().add_jm().format(raffle.endAt),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Countdown: '),
              CountdownTimer(endTime: raffle.endAt, compact: true),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: Pressable(
                  onTap: session == null
                      ? null
                      : () => _showBuyTicketSheet(context, ref, raffle),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Center(
                      child: Text(
                        'Buy ticket',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (isAdmin) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await ref
                            .read(rafflesRepositoryProvider)
                            .drawWinnerBackend(raffle.id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Winner draw requested.'),
                          ),
                        );
                      } on FirebaseFunctionsException catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '[${e.code}] ${e.message ?? 'draw failed'}',
                            ),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    },
                    icon: const Icon(Icons.casino_rounded),
                    label: const Text('Draw'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showBuyTicketSheet(
    BuildContext context,
    WidgetRef ref,
    Raffle raffle,
  ) async {
    final qtyCtrl = TextEditingController(text: '1');
    String method = 'Mobile Money';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final session = ref.read(authStateProvider).value;
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final qty = int.tryParse(qtyCtrl.text) ?? 1;
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
                    top: Radius.circular(26),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Buy tickets',
                        style: Theme.of(ctx).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                        ),
                        onChanged: (_) => setLocal(() {}),
                      ),
                      const SizedBox(height: 10),
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
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Total: UGX ${NumberFormat('#,##0').format(total.round())}',
                          style: Theme.of(ctx).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: Pressable(
                          onTap: () async {
                            if (session == null) return;
                            try {
                              await ref
                                  .read(rafflesRepositoryProvider)
                                  .buyTickets(
                                    raffle: raffle,
                                    userId: session.user.uid,
                                    userName:
                                        session.user.displayName ??
                                        session.user.email ??
                                        'User',
                                    quantity: qty,
                                    paymentMethod: method,
                                  );
                              if (!context.mounted) return;
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Tickets purchased successfully.',
                                  ),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: AppTheme.mintGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                'Pay & generate tickets',
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
            );
          },
        );
      },
    );
  }
}

class _RaffleCard extends StatelessWidget {
  final Raffle raffle;
  final VoidCallback onTap;
  const _RaffleCard({required this.raffle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pct = raffle.maxTickets == 0
        ? 0.0
        : raffle.soldTickets / raffle.maxTickets;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(raffle.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              raffle.prizeDetails,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: pct.clamp(0, 1),
              minHeight: 7,
              borderRadius: BorderRadius.circular(8),
              backgroundColor: Colors.black12,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('${raffle.remainingTickets} left'),
                const Spacer(),
                Text('UGX ${NumberFormat('#,##0').format(raffle.ticketPrice)}'),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.timer_rounded, size: 14),
                const SizedBox(width: 4),
                CountdownTimer(endTime: raffle.endAt, compact: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KV extends StatelessWidget {
  final String label;
  final String value;
  const _KV({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
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
