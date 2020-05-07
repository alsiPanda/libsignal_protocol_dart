import 'dart:collection';
import 'dart:typed_data';

import 'package:libsignalprotocoldart/src/state/SessionState.dart';

import 'LocalStorageProtocol.pb.dart';

class SessionRecord {
  static final int ARCHIVED_STATES_MAX_LENGTH = 40;
  var _sessionState = SessionState();
  final _previousStates = LinkedList<SessionState>();
  bool _fresh = false;

  SessionRecord() {
    _fresh = true;
  }

  SessionRecord.fromSessionState(SessionState sessionState) {
    _sessionState = sessionState;
    _fresh = false;
  }

  SessionRecord.fromSerialized(Uint8List serialized) {
    var record = RecordStructure.fromBuffer(serialized);
    _sessionState = SessionState.fromStructure(record.currentSession);
    _fresh = false;

    for (var previousStructure in record.previousSessions) {
      _previousStates.add(SessionState.fromStructure(previousStructure));
    }
  }

  bool hasSessionState(int version, Uint8List aliceBaseKey) {
    if (_sessionState.getSessionVersion() == version &&
        aliceBaseKey == _sessionState.getAliceBaseKey()) {
      return true;
    }

    for (var state in _previousStates) {
      if (state.getSessionVersion() == version &&
          aliceBaseKey == _sessionState.getAliceBaseKey()) {
        return true;
      }
    }
    return false;
  }

  SessionState getSessionState() {
    return _sessionState;
  }

  LinkedList<SessionState> getPreviousSessionStates() {
    return _previousStates;
  }

  void removePreviousSessionStates() {
    _previousStates.clear();
  }

  bool isFresh() {
    return _fresh;
  }

  void archiveCurrentState() {
    promoteState(SessionState());
  }

  void promoteState(SessionState promotedState) {
    this._previousStates.addFirst(_sessionState);
    this._sessionState = promotedState;

    if (_previousStates.length > ARCHIVED_STATES_MAX_LENGTH) {
      _previousStates.remove(_previousStates.last);
    }
  }

  void setState(SessionState sessionState) {
    this._sessionState = sessionState;
  }

  Uint8List serialize() {
    // List<SessionStructure> previousStructures = LinkedList<SessionStructure>();

    // for (SessionState previousState : previousStates) {
    //   previousStructures.add(previousState.getStructure());
    // }

    var record = RecordStructure.create();
    record.currentSession = _sessionState.getStructure();
    // record.previousSession = _;
    // .addAllPreviousSessions(previousStructures)
    // .build();

    return record.toBuilder().writeToBuffer();
  }
}
