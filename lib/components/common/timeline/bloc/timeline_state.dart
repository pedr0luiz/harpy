part of 'timeline_bloc.dart';

abstract class TimelineState extends Equatable {
  const TimelineState();
}

extension TimelineStateExtension on TimelineState {
  bool get showInitialLoading => this is TimelineInitialLoading;

  bool get showLoadingOlder => this is TimelineLoadingOlder;

  bool get showNoTweetsFound => this is TimelineNoResult;

  bool get showTimelineError => this is TimelineFailure;

  bool get showReachedEnd =>
      this is TimelineResult && !(this as TimelineResult).canRequestOlder;

  bool get enableRequestOlder =>
      this is TimelineResult && (this as TimelineResult).canRequestOlder;

  bool get hasTweets => timelineTweets.isNotEmpty;

  // todo
  // bool get enableFilter =>
  //     this is HomeTimelineResult || timelineFilter != TimelineFilter.empty;
  bool get enableFilter => false;

  List<TweetData> get timelineTweets {
    if (this is TimelineResult) {
      return (this as TimelineResult).tweets;
    } else if (this is TimelineLoadingOlder) {
      return (this as TimelineLoadingOlder).oldResult.tweets;
    } else {
      return [];
    }
  }

  int get newInitialTweets {
    if (this is TimelineResult) {
      return (this as TimelineResult).newInitialTweets;
    } else if (this is TimelineLoadingOlder) {
      return (this as TimelineLoadingOlder).oldResult.newInitialTweets;
    } else {
      return 0;
    }
  }

  bool showNewTweetsExist(String? originalIdStr) {
    TimelineResult? result;

    if (this is TimelineResult) {
      result = this as TimelineResult?;
    } else if (this is TimelineLoadingOlder) {
      result = (this as TimelineLoadingOlder).oldResult;
    }

    if (result != null) {
      return result.newInitialTweets > 0 &&
          result.lastInitialTweet == originalIdStr;
    } else {
      return false;
    }
  }
}

class TimelineInitialLoading extends TimelineState {
  const TimelineInitialLoading();

  @override
  List<Object?> get props => [];
}

class TimelineResult extends TimelineState {
  const TimelineResult({
    required this.tweets,
    // TODO: copy values from previous responses in bloc
    this.newInitialTweets = 0,
    this.maxId,
    this.lastInitialTweet = '',
    this.initialResults = false,
    this.canRequestOlder = true,
  });

  final List<TweetData> tweets;

  /// The number of new tweets if the initial request found new tweets that
  /// were not present in a previous session.
  final int newInitialTweets;

  /// The max id used to request older tweets.
  ///
  /// This is the id of the last requested tweet before the tweets got filtered.
  final String? maxId;

  /// The idStr of that last tweet from the initial request.
  final String? lastInitialTweet;

  /// Whether the initial timeline with tweets that are newer than the last
  /// visible tweet from a previous session has been requested in this result.
  final bool initialResults;

  /// Whether older tweets in the timeline can be requested.
  ///
  /// This is `false` when the end of the timeline has been reached.
  /// This is the case when the last 800 tweets have been requested.
  final bool canRequestOlder;

  @override
  List<Object?> get props => [
        tweets,
        newInitialTweets,
        maxId,
        lastInitialTweet,
        initialResults,
        canRequestOlder,
      ];
}

class TimelineLoadingOlder extends TimelineState {
  const TimelineLoadingOlder({
    required this.oldResult,
  });

  final TimelineResult oldResult;

  @override
  List<Object?> get props => [];
}

class TimelineNoResult extends TimelineState {
  const TimelineNoResult();

  @override
  List<Object?> get props => [];
}

class TimelineFailure extends TimelineState {
  const TimelineFailure();

  @override
  List<Object?> get props => [];
}
