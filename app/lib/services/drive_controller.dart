import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/route_maneuver.dart';
import '../models/route_option.dart';
import '../models/survey.dart';
import '../models/vibration_profile.dart';
import 'assessment_controller.dart';
import 'auth_controller.dart';
import 'ble_controller.dart';
import 'cue_scheduler.dart';
import 'haptic_cue_player.dart';
import 'proximity_pulser.dart';
import 'route_progress.dart';

enum DriveStatus { idle, driving, arrived }

/// Snapshot of an in-progress (simulated) drive for the Drive screen.
class DriveState {
  const DriveState({
    this.status = DriveStatus.idle,
    this.route,
    this.position,
    this.bearingDeg = 0,
    this.progressM = 0,
    this.totalM = 0,
    this.nextManeuver,
    this.nextManeuverIndex = 0,
    this.distanceToNextM,
    this.lastCue,
    this.cueLog = const [],
    this.speedMultiplier = 1,
    this.hapticsAvailable = true,
  });

  final DriveStatus status;
  final RouteOption? route;
  final LatLng? position;
  final double bearingDeg;
  final double progressM;
  final double totalM;
  final RouteManeuver? nextManeuver;
  final int nextManeuverIndex;
  final double? distanceToNextM;
  final FiredCue? lastCue;
  final List<FiredCue> cueLog;
  final double speedMultiplier;

  /// False when a band dropped mid-drive: cues are suppressed, screen guides.
  final bool hapticsAvailable;

  DriveState copyWith({
    DriveStatus? status,
    RouteOption? route,
    LatLng? position,
    double? bearingDeg,
    double? progressM,
    double? totalM,
    RouteManeuver? nextManeuver,
    bool clearNextManeuver = false,
    int? nextManeuverIndex,
    double? distanceToNextM,
    bool clearDistance = false,
    FiredCue? lastCue,
    List<FiredCue>? cueLog,
    double? speedMultiplier,
    bool? hapticsAvailable,
  }) =>
      DriveState(
        status: status ?? this.status,
        route: route ?? this.route,
        position: position ?? this.position,
        bearingDeg: bearingDeg ?? this.bearingDeg,
        progressM: progressM ?? this.progressM,
        totalM: totalM ?? this.totalM,
        nextManeuver:
            clearNextManeuver ? null : (nextManeuver ?? this.nextManeuver),
        nextManeuverIndex: nextManeuverIndex ?? this.nextManeuverIndex,
        distanceToNextM:
            clearDistance ? null : (distanceToNextM ?? this.distanceToNextM),
        lastCue: lastCue ?? this.lastCue,
        cueLog: cueLog ?? this.cueLog,
        speedMultiplier: speedMultiplier ?? this.speedMultiplier,
        hapticsAvailable: hapticsAvailable ?? this.hapticsAvailable,
      );
}

/// The Haptic Engine: follows the chosen route with a simulated position
/// (fixed driving speed × a demo multiplier) and fires wrist cues ahead of
/// each maneuver via [CueScheduler] + [HapticCuePlayer].
///
/// The position is simulated so the whole feature is demoable and testable
/// without a car, GPS, or hardware. Real GPS later becomes just another
/// source of `progressM` (project the fix onto the path via [RoutePath]).
class DriveController extends Notifier<DriveState> {
  static const _tick = Duration(milliseconds: 500);
  static const _baseSpeedKmh = 40.0; // simulated city driving speed
  static const _arriveWithinM = 15.0;

  Timer? _timer;
  RoutePath? _path;
  CueScheduler? _scheduler;
  ProximityPulser? _pulser;
  int _elapsedMs = 0;
  VibrationProfile? _profile;

  /// Fallback when the user never completed an assessment: medium everything.
  static const _defaultProfile = VibrationProfile(
    scores: <ProfileDimension, double>{},
    intensity: 0.6,
    leadTimeSeconds: 5,
    rhythm: HapticRhythm.medium,
    spatialType: 'Balanced profile',
  );

  @override
  DriveState build() {
    ref.onDispose(_cancelTimer);
    // End the drive if the user signs out mid-drive.
    ref.listen<dynamic>(authControllerProvider, (prev, next) {
      if (next == null) stop();
    });
    return const DriveState();
  }

  double get _speedMps => _baseSpeedKmh / 3.6 * state.speedMultiplier;

  /// Begin a simulated drive along [route]. Requires both bands connected
  /// (the UI enforces this too — double guard on a safety feature).
  void start(RouteOption route) {
    stop();

    final path = RoutePath(route.points);

    // Plan maneuvers onto the path: project each onto the polyline,
    // searching only forward of the previous one so an out-and-back route
    // can't order them wrongly. Enforce strictly increasing positions.
    final planned = <PlannedManeuver>[];
    var minM = 0.0;
    for (final m in route.maneuvers) {
      final proj = path.project(m.position, minM: minM);
      var along = proj.alongM;
      if (planned.isNotEmpty && along <= planned.last.alongM) {
        along = planned.last.alongM + 1;
      }
      planned.add(PlannedManeuver(maneuver: m, alongM: along));
      minM = along;
    }

    _profile = ref.read(assessmentControllerProvider).profile ??
        _defaultProfile;
    _path = path;
    _scheduler = CueScheduler(
      maneuvers: planned,
      leadTimeSeconds: _profile!.leadTimeSeconds,
      speedMps: _baseSpeedKmh / 3.6,
      nowM: ProximityPulser.handoverM,
    );
    _pulser = ProximityPulser();
    _elapsedMs = 0;

    state = DriveState(
      status: DriveStatus.driving,
      route: route,
      position: path.pointAt(0),
      bearingDeg: path.bearingAt(0),
      totalM: path.totalM,
      nextManeuver:
          route.maneuvers.isNotEmpty ? route.maneuvers.first : null,
      distanceToNextM: planned.isNotEmpty ? planned.first.alongM : null,
      hapticsAvailable: ref.read(bleControllerProvider).bothConnected,
    );

    _timer = Timer.periodic(_tick, (_) => _advance(_tick.inMilliseconds / 1000));
  }

  /// Demo control: 1× / 2× / 4× simulation speed.
  void setSpeedMultiplier(double multiplier) {
    state = state.copyWith(speedMultiplier: multiplier.clamp(1, 4));
  }

  /// End the drive and return to idle.
  void stop() {
    _cancelTimer();
    _path = null;
    _scheduler = null;
    _pulser = null;
    _profile = null;
    state = const DriveState();
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _advance(double dtSeconds) {
    final path = _path;
    final scheduler = _scheduler;
    final profile = _profile;
    if (path == null || scheduler == null || profile == null) return;
    if (state.status != DriveStatus.driving) return;

    final progress = state.progressM + _speedMps * dtSeconds;
    final ble = ref.read(bleControllerProvider);
    final hapticsOk = ble.bothConnected;

    // Arrived?
    if (progress >= path.totalM - _arriveWithinM) {
      _cancelTimer();
      state = state.copyWith(
        status: DriveStatus.arrived,
        progressM: path.totalM,
        position: path.pointAt(path.totalM),
        clearNextManeuver: true,
        clearDistance: true,
        hapticsAvailable: hapticsOk,
      );
      if (hapticsOk) {
        unawaited(HapticCuePlayer(ref.read(bleControllerProvider.notifier))
            .playArrival());
      }
      return;
    }

    // Fire due cues (suppressed while a band is down, but still logged so
    // the screen can explain what would have buzzed).
    final cues = scheduler.onProgress(progress);
    if (cues.isNotEmpty && hapticsOk) {
      final player =
          HapticCuePlayer(ref.read(bleControllerProvider.notifier));
      for (final c in cues) {
        // ALERT is no longer played during a drive: ProximityPulser owns the
        // 250-20 m window, and firing both would put a burst in the middle of
        // the tap train. The cue is still scheduled and logged so the screen
        // can show the stage it reached.
        if (c.stage == CueStage.alert) continue;
        unawaited(player.playCue(c.stage, c.wrist, profile));
      }
    }

    final next = scheduler.nextManeuver;

    // Approach ladder: single taps that get faster and stronger as the turn
    // closes. The wrist still comes from the maneuver, never from geometry.
    _elapsedMs += (dtSeconds * 1000).round();
    final pulser = _pulser;
    if (pulser != null && next != null && hapticsOk) {
      final wrist = next.wrist;
      if (wrist != null) {
        final tap = pulser.onProgress(
          distanceM: next.alongM - progress,
          nowMs: _elapsedMs,
          maneuverIndex: scheduler.nextManeuverIndex,
        );
        if (tap != null) {
          unawaited(
            HapticCuePlayer(ref.read(bleControllerProvider.notifier))
                .playApproachTap(wrist, tap),
          );
        }
      }
    }
    state = state.copyWith(
      progressM: progress,
      position: path.pointAt(progress),
      bearingDeg: path.bearingAt(progress),
      nextManeuver: next?.maneuver,
      clearNextManeuver: next == null,
      nextManeuverIndex: scheduler.nextManeuverIndex,
      distanceToNextM: next != null ? next.alongM - progress : null,
      clearDistance: next == null,
      lastCue: cues.isNotEmpty ? cues.last : null,
      cueLog: cues.isEmpty ? null : [...state.cueLog, ...cues],
      hapticsAvailable: hapticsOk,
    );
  }
}

final driveControllerProvider =
    NotifierProvider<DriveController, DriveState>(DriveController.new);
