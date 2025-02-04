import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:harpy/components/components.dart';

/// Shows a [ListTimeline] for the [listId] in its own screen.
class ListTimelineScreen extends StatelessWidget {
  const ListTimelineScreen({
    required this.listId,
    this.name,
  });

  final String listId;
  final String? name;

  static const route = 'list_timeline';

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return BlocProvider(
      create: (_) => ListTimelineCubit(listId: listId),
      child: HarpyScaffold(
        body: ScrollDirectionListener(
          child: ListTimeline(
            name: name,
            beginSlivers: [
              HarpySliverAppBar(
                title: name,
                floating: true,
              ),
            ],
            refreshIndicatorOffset: -mediaQuery.padding.top,
          ),
        ),
      ),
    );
  }
}
