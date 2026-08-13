import 'package:flutter_test/flutter_test.dart';

import 'package:q_reversi_app/domain/time_attack/time_attack_player_identity.dart';

void main() {
  test('next default nickname is the smallest unused QMaster number', () {
    expect(
      TimeAttackPlayerIdentity.nextDefaultNickname(const []),
      'QMaster1',
    );
    expect(
      TimeAttackPlayerIdentity.nextDefaultNickname(const ['QMaster1', 'QMaster2']),
      'QMaster3',
    );
    expect(
      TimeAttackPlayerIdentity.nextDefaultNickname(const ['QMaster1', 'QMaster3']),
      'QMaster2',
    );
  });

  test('default nickname stays within 12 characters', () {
    final name = TimeAttackPlayerIdentity.nextDefaultNickname(const []);
    expect(name.length, lessThanOrEqualTo(12));
    expect(name.startsWith('QMaster'), isTrue);
  });

  test('local UID matches Firebase UID length and charset', () {
    final uid = TimeAttackPlayerIdentity.generateLocalUid();
    expect(uid.length, TimeAttackPlayerIdentity.firebaseUidLength);
    expect(RegExp(r'^[A-Za-z0-9]+$').hasMatch(uid), isTrue);
  });
}
