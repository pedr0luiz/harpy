part of 'timeline_bloc.dart';

abstract class TimelineEvent {
  const TimelineEvent();

  Future<void> handle(TimelineBloc bloc, Emitter<TimelineState> emit);
}

/// Requests the timeline tweets that are newer than the newest last visible
/// tweet from the previous session.
///
/// If the last visible tweet is older than the last 200 tweets, it has no
/// affect (twitter api bug).
///
/// After successful response, the older tweets are requested using the
/// [RequestOlderHomeTimeline] event, if only a small number of tweets in the
/// initial request existed.
class RequestInitialTimeline extends TimelineEvent with HarpyLogger {
  const RequestInitialTimeline({
    required this.lastVisibleTweet,
  });

  final int lastVisibleTweet;

  @override
  Future<void> handle(TimelineBloc bloc, Emitter<TimelineState> emit) async {
    log.fine('requesting initial timeline');

    emit(const TimelineInitialLoading());

    String? maxId;

    final tweets = await bloc
        .requestTimeline(
          excludeReplies: bloc.timelineFilter.excludesReplies,
          sinceId: '${lastVisibleTweet - 1}',
        )
        .then((tweets) {
          if (tweets.isNotEmpty) {
            maxId = tweets.last.idStr;
          }
          return tweets;
        })
        .then((tweets) => handleTweets(tweets, bloc.timelineFilter))
        .handleError(twitterApiErrorHandler);

    if (tweets != null) {
      log.fine('found ${tweets.length} initial tweets');

      if (tweets.isNotEmpty) {
        // found new tweets since last visit
        emit(
          TimelineResult(
            tweets: tweets,
            maxId: maxId,
            newInitialTweets: tweets.length - 1,
            lastInitialTweet: tweets.last.originalId,
            initialResults: true,
          ),
        );

        if (tweets.length < 50) {
          // automatically request older (already read tweets)
          bloc.add(const RequestOlderTimeline());
        }
      } else {
        // no new tweets exist since last visit, refresh to get the newest
        // batch.
        bloc.add(const RefreshTimeline());
      }
    } else {
      emit(const TimelineFailure());
    }
  }
}

/// Refreshes the timeline by requesting the newest 200 timeline tweets.
///
/// If [clearPrevious] is `true`, [TimelineInitialLoading] is emitted before
/// requesting the timeline to clear the previous tweets.
class RefreshTimeline extends TimelineEvent with HarpyLogger {
  const RefreshTimeline({
    this.clearPrevious = false,
  });

  final bool clearPrevious;

  @override
  Future<void> handle(TimelineBloc bloc, Emitter<TimelineState> emit) async {
    log.fine('refreshing timeline');

    if (clearPrevious) {
      emit(const TimelineInitialLoading());
    }

    String? maxId;

    final tweets = await bloc
        .requestTimeline(
          excludeReplies: bloc.timelineFilter.excludesReplies,
        )
        .then((tweets) {
          if (tweets.isNotEmpty) {
            maxId = tweets.last.idStr;
          }
          return tweets;
        })
        .then((tweets) => handleTweets(tweets, bloc.timelineFilter))
        .handleError(twitterApiErrorHandler);

    if (tweets != null) {
      log.fine('found ${tweets.length} tweets');

      if (tweets.isNotEmpty) {
        emit(
          TimelineResult(
            tweets: tweets,
            maxId: maxId,
          ),
        );
      } else {
        emit(const TimelineNoResult());
      }
    } else {
      emit(const TimelineFailure());
    }
  }
}

/// Requests older timeline tweets.
///
/// This is used when the end of the timeline has been reached and the user
/// wants to load the older (previous) tweets.
///
/// Only the newest 800 tweets in a timeline can be requested.
class RequestOlderTimeline extends TimelineEvent with HarpyLogger {
  const RequestOlderTimeline();

  String? _maxId(String? maxId) {
    final lastId = int.tryParse(maxId ?? '');

    if (lastId != null) {
      return '${lastId - 1}';
    } else {
      return null;
    }
  }

  @override
  Future<void> handle(TimelineBloc bloc, Emitter<TimelineState> emit) async {
    if (bloc.lock()) {
      return;
    }

    final state = bloc.state;

    if (state is TimelineResult) {
      final maxId = _maxId(state.maxId);

      if (maxId == null) {
        log.warning('tried requesting older timeline but max id was null');
        return;
      }

      log.fine('requesting older timeline');

      emit(TimelineLoadingOlder(oldResult: state));

      String? newMaxId;
      var canRequestOlder = false;

      final tweets = await bloc
          .requestTimeline(
            excludeReplies: bloc.timelineFilter.excludesReplies,
            maxId: maxId,
          )
          .then((tweets) {
            if (tweets.isNotEmpty) {
              newMaxId = tweets.last.idStr;
              canRequestOlder = true;
            }
            return tweets;
          })
          .then((tweets) => handleTweets(tweets, bloc.timelineFilter))
          .handleError(twitterApiErrorHandler);

      if (tweets != null) {
        log
          ..fine('found ${tweets.length} older tweets')
          ..finer('can request older: $canRequestOlder');

        emit(
          TimelineResult(
            tweets: state.tweets.followedBy(tweets).toList(),
            maxId: newMaxId,
            lastInitialTweet: state.lastInitialTweet,
            newInitialTweets: state.newInitialTweets,
            canRequestOlder: canRequestOlder,
          ),
        );
      } else {
        emit(const TimelineFailure());
        // todo: isn't newMaxId always null here? I think this should be in a
        //  where tweets is not null but empty (though it can be ignored in that
        //  case)

        // re-yield result state with previous tweets but new max id
        // emit(
        //   TimelineResult(
        //     tweets: state.tweets,
        //     maxId: newMaxId,
        //     // canRequestOlder: canRequestOlder, // todo: is this necessary?
        //   ),
        // );
      }
    }
  }
}

/// Sets the filter for the timeline and refreshes it afterwards.
class FilterTimeline extends TimelineEvent with HarpyLogger {
  const FilterTimeline({
    required this.timelineFilter,
  });

  final TimelineFilter timelineFilter;

  void _saveTimelineFilter() {
    try {
      final encodedFilter = jsonEncode(timelineFilter.toJson());
      log.finer('saving filter: $encodedFilter');

      // TODO: add filters for other timelines
      app<TimelineFilterPreferences>().homeTimelineFilter = encodedFilter;
    } catch (e, st) {
      log.severe('unable to encode timeline filter', e, st);
    }
  }

  @override
  Future<void> handle(TimelineBloc bloc, Emitter<TimelineState> emit) async {
    log.fine('set home timeline filter');

    _saveTimelineFilter();

    bloc.add(const RefreshTimeline(clearPrevious: true));
  }
}
