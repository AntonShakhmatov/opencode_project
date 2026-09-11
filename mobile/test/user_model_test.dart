import 'package:flutter_test/flutter_test.dart';
import 'package:app_mobile/models/user.dart';

void main() {
  test('parses numeric rating delivered as a string (Postgres NUMERIC)', () {
    final user = User.fromJson({
      'id': 'u1',
      'email': 'a@b.com',
      'name': 'Mike',
      'role': 'handyman',
      'rating': '5.00',
      'reviewCount': 3,
      'isAvailable': true,
    });

    expect(user.rating, 5.0);
    expect(user.reviewCount, 3);
    expect(user.isAvailable, isTrue);
  });

  test('parses null / missing rating and reviewCount', () {
    final user = User.fromJson({
      'id': 'u2',
      'email': 'c@d.com',
      'name': 'Client',
      'role': 'client',
    });

    expect(user.rating, isNull);
    expect(user.reviewCount, isNull);
    expect(user.isAvailable, isNull);
  });

  test('parses skills as list, comma string, or empty', () {
    final listUser = User.fromJson({
      'id': 'u3',
      'email': 'e@f.com',
      'name': 'X',
      'role': 'handyman',
      'skills': ['plumbing', 'painting'],
    });
    expect(listUser.skills, ['plumbing', 'painting']);

    final strUser = User.fromJson({
      'id': 'u4',
      'email': 'g@h.com',
      'name': 'Y',
      'role': 'handyman',
      'skills': 'plumbing,painting',
    });
    expect(strUser.skills, ['plumbing', 'painting']);

    final noneUser = User.fromJson({
      'id': 'u5',
      'email': 'i@j.com',
      'name': 'Z',
      'role': 'handyman',
      'skills': null,
    });
    expect(noneUser.skills, isNull);
  });
}