import 'dart:async';

import 'package:base_app/core/widgets/loading_view.dart';
import 'package:base_app/core/widgets/message_view.dart';
import 'package:base_app/core/widgets/snack.dart';
import 'package:base_app/features/items/presentation/cubit/items_cubit.dart';
import 'package:base_app/features/items/presentation/cubit/items_state.dart';
import 'package:base_app/features/items/presentation/widgets/item_tile.dart';
import 'package:base_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ItemsPage extends StatelessWidget {
  /// [onLogout] is injected by the router so this feature doesn't depend on auth.
  const ItemsPage({required this.onLogout, super.key});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ItemsCubit>();
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.items),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.signOut,
            onPressed: onLogout,
          ),
        ],
      ),
      body: BlocConsumer<ItemsCubit, ItemsState>(
        // Errors while data is visible go to a snackbar, not a full-screen error.
        listenWhen: (prev, curr) =>
            curr.failure != null &&
            curr.failure != prev.failure &&
            curr.items.isNotEmpty,
        listener: (context, state) =>
            context.showSnack(state.failure!.localized(l10n)),
        builder: (context, state) => switch (state.status) {
          ItemsStatus.initial || ItemsStatus.loading => const LoadingView(),
          ItemsStatus.failure => MessageView(
            icon: Icons.error_outline,
            message: state.failure!.localized(l10n),
            onRetry: cubit.load,
          ),
          ItemsStatus.success when state.items.isEmpty => MessageView(
            icon: Icons.inbox_outlined,
            message: l10n.itemsEmpty,
            onRetry: cubit.load,
          ),
          ItemsStatus.success => _ItemsList(state),
        },
      ),
    );
  }
}

class _ItemsList extends StatelessWidget {
  const _ItemsList(this.state);

  final ItemsState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ItemsCubit>();
    final items = state.items;
    return RefreshIndicator(
      onRefresh: cubit.load,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.extentAfter < 400) unawaited(cubit.loadMore());
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length + (state.hasMore ? 1 : 0),
          itemBuilder: (_, i) => i < items.length
              ? ItemTile(key: ValueKey(items[i].id), item: items[i])
              : const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
        ),
      ),
    );
  }
}
