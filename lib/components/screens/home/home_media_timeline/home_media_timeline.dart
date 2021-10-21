import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:harpy/components/components.dart';
import 'package:provider/provider.dart';

class HomeMediaTimeline extends StatelessWidget {
  const HomeMediaTimeline();

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<NewHomeTimelineBloc>();
    final state = bloc.state;

    return ChangeNotifierProvider<MediaTimelineModel>(
      create: (_) => MediaTimelineModel(
        initialTweets: bloc.state.timelineTweets,
      ),
      child: BlocListener<NewHomeTimelineBloc, TimelineState>(
        listener: (context, state) {
          context
              .read<MediaTimelineModel>()
              .updateEntries(state.timelineTweets);
        },
        child: ScrollToStart(
          child: LoadMoreListener(
            listen: state.enableRequestOlder,
            onLoadMore: () async {
              bloc.add(const RequestOlderTimeline());
              // todo
              // await bloc.requestOlderCompleter.future;
            },
            child: MediaTimeline(
              showInitialLoading: state.showInitialLoading,
              showLoadingOlder: state.showLoadingOlder,
              beginSlivers: const [
                HomeTopSliverPadding(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
