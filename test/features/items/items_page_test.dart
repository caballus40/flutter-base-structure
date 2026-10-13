import 'package:base_app/core/result/result.dart';
import 'package:base_app/features/items/domain/item.dart';
import 'package:base_app/features/items/presentation/cubit/items_cubit.dart';
import 'package:base_app/features/items/presentation/cubit/items_state.dart';
import 'package:base_app/features/items/presentation/items_page.dart';
import 'package:base_app/features/items/presentation/widgets/item_tile.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

class _MockItemsCubit extends MockCubit<ItemsState> implements ItemsCubit {}

void main() {
  late _MockItemsCubit cubit;
  late int logoutCalls;
  const items = [
    Item(id: '1', title: 'One'),
    Item(id: '2', title: 'Two', description: 'Second'),
  ];
  const loaded = ItemsState(
    status: ItemsStatus.success,
    items: items,
    page: 1,
    hasMore: false,
  );

  setUp(() {
    cubit = _MockItemsCubit();
    logoutCalls = 0;
    when(cubit.load).thenAnswer((_) async {});
    when(cubit.loadMore).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester, ItemsState state) {
    when(() => cubit.state).thenReturn(state);
    return tester.pumpApp(
      BlocProvider<ItemsCubit>.value(
        value: cubit,
        child: ItemsPage(onLogout: () => logoutCalls++),
      ),
    );
  }

  testWidgets('loading shows a spinner', (tester) async {
    await pump(tester, const ItemsState(status: ItemsStatus.loading));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('failure shows localized message and retries', (tester) async {
    await pump(
      tester,
      const ItemsState(
        status: ItemsStatus.failure,
        failure: Failure(FailureType.server),
      ),
    );

    expect(find.text('Server error. Try again later.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    verify(cubit.load).called(1);
  });

  testWidgets('empty list shows the empty state', (tester) async {
    await pump(tester, const ItemsState(status: ItemsStatus.success));

    expect(find.text('No items yet'), findsOneWidget);
  });

  testWidgets('success renders a tile per item', (tester) async {
    await pump(tester, loaded);

    expect(find.byType(ItemTile), findsNWidgets(2));
    expect(find.text('Second'), findsOneWidget);
  });

  testWidgets('error while data is visible shows a snackbar', (tester) async {
    whenListen(
      cubit,
      Stream.value(
        loaded.copyWith(failure: const Failure(FailureType.network)),
      ),
      initialState: loaded,
    );
    await pump(tester, loaded);
    await tester.pump();

    expect(find.text('No connection. Check your network.'), findsOneWidget);
    expect(find.byType(ItemTile), findsNWidgets(2));
  });

  testWidgets('sign out calls onLogout', (tester) async {
    await pump(tester, loaded);

    await tester.tap(find.byTooltip('Sign out'));

    expect(logoutCalls, 1);
  });
}
