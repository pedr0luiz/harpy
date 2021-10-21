import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:dart_twitter_api/twitter_api.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:harpy/api/api.dart';
import 'package:harpy/components/components.dart';
import 'package:harpy/core/core.dart';

part 'timeline_event.dart';
part 'timeline_state.dart';

abstract class TimelineBloc extends Bloc<TimelineEvent, TimelineState>
    with HarpyLogger, RequestLock {
  TimelineBloc({
    required this.timelineFilter,
  }) : super(const TimelineInitialLoading()) {
    on<TimelineEvent>((event, emit) => event.handle(this, emit));

    if (_keepTimelinePosition && _lastVisibleTweet != 0) {
      add(RequestInitialTimeline(lastVisibleTweet: _lastVisibleTweet));
    } else {
      add(const RefreshTimeline());
    }
  }

  @protected
  TimelineFilter timelineFilter;

  @protected
  bool get _keepTimelinePosition;

  @protected
  int get _lastVisibleTweet;

  @protected
  Future<List<Tweet>> requestTimeline({
    required bool excludeReplies,
    String? sinceId,
    String? maxId,
  });
}

// ==================
// home timeline bloc
// ==================

class NewHomeTimelineBloc extends TimelineBloc {
  NewHomeTimelineBloc()
      : super(
          timelineFilter: TimelineFilter.fromJsonString(
            app<TimelineFilterPreferences>().homeTimelineFilter,
          ),
        );

  @override
  bool get _keepTimelinePosition =>
      app<GeneralPreferences>().keepTimelinePosition;

  @override
  int get _lastVisibleTweet =>
      app<TweetVisibilityPreferences>().lastVisibleTweet;

  @override
  Future<List<Tweet>> requestTimeline({
    required bool excludeReplies,
    String? sinceId,
    String? maxId,
  }) =>
      app<TwitterApi>().timelineService.homeTimeline(
            count: 200,
            excludeReplies: excludeReplies,
            sinceId: sinceId,
            maxId: maxId,
          );
}
