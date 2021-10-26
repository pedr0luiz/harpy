part of 'likes_timeline_bloc.dart';

abstract class LikesTimelineEvent extends Equatable {
  const LikesTimelineEvent();

  Stream<LikesTimelineState> applyAsync({
    required LikesTimelineState currentState,
    required LikesTimelineBloc bloc,
  });
}

/// Requests the likes timeline tweets for the [LikesTimelineBloc.screenName].
class RequestLikesTimeline extends LikesTimelineEvent with HarpyLogger {
  const RequestLikesTimeline();

  @override
  List<Object> get props => <Object>[];

  @override
  Stream<LikesTimelineState> applyAsync({
    required LikesTimelineState currentState,
    required LikesTimelineBloc bloc,
  }) async* {
    log.fine('requesting likes timeline');

    yield const LikesTimelineInitialLoading();

    String? maxId;

    final tweets = await app<TwitterApi>()
        .tweetService
        .listFavorites(
          screenName: bloc.screenName,
          count: 200,
        )
        .then((tweets) {
          if (tweets.isNotEmpty) {
            maxId = tweets.last.idStr;
          }
          return tweets;
        })
        .then(handleTweets)
        .handleError(twitterApiErrorHandler);

    if (tweets != null) {
      log.fine('found ${tweets.length} initial tweets');

      if (tweets.isNotEmpty) {
        yield LikesTimelineResult(
          tweets: tweets,
          maxId: maxId,
        );
      } else {
        yield const LikesTimelineNoResult();
      }
    } else {
      yield const LikesTimelineFailure();
    }
  }
}

/// An event to request older likes timeline tweets.
///
/// This is used when the end of the likes timeline has been reached and the
/// user wants to load the older (previous) tweets.
///
/// Only the last 800 tweets in a likes timeline can be requested.
class RequestOlderLikesTimeline extends LikesTimelineEvent with HarpyLogger {
  const RequestOlderLikesTimeline();

  @override
  List<Object> get props => <Object>[];

  String? _findMaxId(LikesTimelineResult state) {
    final lastId = int.tryParse(state.maxId ?? '');

    if (lastId != null) {
      return '${lastId - 1}';
    } else {
      return null;
    }
  }

  @override
  Stream<LikesTimelineState> applyAsync({
    required LikesTimelineState currentState,
    required LikesTimelineBloc bloc,
  }) async* {
    if (bloc.lock()) {
      bloc.requestOlderCompleter.complete();
      bloc.requestOlderCompleter = Completer<void>();
      return;
    }

    if (currentState is LikesTimelineResult) {
      final maxId = _findMaxId(currentState);

      if (maxId == null) {
        log.info('tried to request older but max id was null');
        return;
      }

      log.fine('requesting older likes timeline tweets');

      yield LikesTimelineLoadingOlder(oldResult: currentState);

      String? newMaxId;
      var canRequestOlder = false;

      final tweets = await app<TwitterApi>()
          .tweetService
          .listFavorites(
            screenName: bloc.screenName,
            count: 200,
            maxId: maxId,
          )
          .then((tweets) {
            if (tweets.isNotEmpty) {
              newMaxId = tweets.last.idStr;
              canRequestOlder = true;
            } else {
              canRequestOlder = false;
            }
            return tweets;
          })
          .then(handleTweets)
          .handleError(twitterApiErrorHandler);

      if (tweets != null) {
        log
          ..fine('found ${tweets.length} older tweets')
          ..finer('can request older: $canRequestOlder');

        yield LikesTimelineResult(
          tweets: currentState.tweets.followedBy(tweets).toList(),
          maxId: newMaxId,
          canRequestOlder: canRequestOlder,
        );
      } else {
        // re-yield result state with previous tweets but new max id
        yield LikesTimelineResult(
          tweets: currentState.tweets,
          maxId: currentState.maxId,
        );
      }
    }

    bloc.requestOlderCompleter.complete();
    bloc.requestOlderCompleter = Completer<void>();
  }
}
