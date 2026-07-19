// Day-boundary business logic (cert expiry tiers, overdue checks) used to
// read DateTime.now() directly, so these boundaries were never actually
// tested — only eyeballed. With the clock injected via services/clock.dart,
// "now" is pinned to a fixed instant here so every boundary is exact.
import 'package:flutter_test/flutter_test.dart';

import 'package:maridive_fleet_vessels/models/attachment.dart';
import 'package:maridive_fleet_vessels/models/crew_certificate.dart';
import 'package:maridive_fleet_vessels/models/daily_task.dart';
import 'package:maridive_fleet_vessels/models/urgent_notification.dart';
import 'package:maridive_fleet_vessels/models/vessel_certificate.dart';
import 'package:maridive_fleet_vessels/services/clock.dart';

void main() {
  final fixedNow = DateTime(2026, 7, 17, 12);

  setUp(() => setClockForTesting(() => fixedNow));
  tearDown(resetClock);

  VesselCertificate certExpiringIn(int days) => VesselCertificate(
        id: 'c1',
        vesselId: 'v1',
        documentName: 'Safety Cert',
        issuingAuthority: 'Class Society',
        issueDate: fixedNow.subtract(const Duration(days: 365)),
        expiryDate: fixedNow.add(Duration(days: days)),
        attachments: const <Attachment>[],
      );

  group('VesselCertificate.reminderStatus boundaries', () {
    test('1 day past expiry is expired', () {
      expect(certExpiringIn(-1).reminderStatus, CertReminderStatus.expired);
    });

    test('expires today (0 days left) is red, not expired', () {
      expect(certExpiringIn(0).reminderStatus, CertReminderStatus.red);
    });

    test('exactly 30 days left is still red', () {
      expect(certExpiringIn(30).reminderStatus, CertReminderStatus.red);
    });

    test('31 days left crosses into amber', () {
      expect(certExpiringIn(31).reminderStatus, CertReminderStatus.amber);
    });

    test('exactly 90 days left is still amber', () {
      expect(certExpiringIn(90).reminderStatus, CertReminderStatus.amber);
    });

    test('91 days left crosses into green', () {
      expect(certExpiringIn(91).reminderStatus, CertReminderStatus.green);
    });
  });

  group('CrewCertificate.reminderStatus boundaries', () {
    CrewCertificate certExpiringIn(int days) => CrewCertificate(
          id: 'cc1',
          vesselId: 'v1',
          officerName: 'A. Officer',
          rank: 'Master',
          certType: CrewCertType.coc,
          issueDate: fixedNow.subtract(const Duration(days: 365)),
          expiryDate: fixedNow.add(Duration(days: days)),
        );

    test('1 day past expiry is expired', () {
      expect(certExpiringIn(-1).reminderStatus, CertReminderStatus.expired);
    });

    test('exactly 30 days left is still red', () {
      expect(certExpiringIn(30).reminderStatus, CertReminderStatus.red);
    });

    test('31 days left crosses into amber', () {
      expect(certExpiringIn(31).reminderStatus, CertReminderStatus.amber);
    });

    test('91 days left crosses into green', () {
      expect(certExpiringIn(91).reminderStatus, CertReminderStatus.green);
    });
  });

  group('DailyTask.isOverdue boundary', () {
    DailyTask taskDueAt(DateTime scheduled, {TaskStatus status = TaskStatus.pending}) =>
        DailyTask(
          id: 't1',
          vesselId: 'v1',
          category: TaskCategory.deckRounds,
          title: 'Deck rounds',
          assignedTo: 'Bosun',
          frequency: TaskFrequency.daily,
          scheduledTime: scheduled,
          status: status,
          checklistItems: const [],
          attachments: const <Attachment>[],
          createdAt: scheduled,
        );

    test('exactly at scheduled time is not yet overdue', () {
      expect(taskDueAt(fixedNow).isOverdue, isFalse);
    });

    test('one second past scheduled time is overdue', () {
      expect(
          taskDueAt(fixedNow.subtract(const Duration(seconds: 1))).isOverdue,
          isTrue);
    });

    test('a completed task is never overdue, however late', () {
      expect(
          taskDueAt(fixedNow.subtract(const Duration(days: 5)),
                  status: TaskStatus.completed)
              .isOverdue,
          isFalse);
    });
  });

  group('UrgentNotification.isOverdue boundary', () {
    UrgentNotification actionDueAt(DateTime? due,
            {bool isAction = true,
            ActionStatus actionStatus = ActionStatus.pending}) =>
        UrgentNotification(
          id: 'n1',
          vesselId: 'v1',
          alertType: AlertType.other,
          location: 'Bridge',
          description: 'Investigate',
          timestamp: fixedNow,
          escalationStatus: EscalationStatus.acknowledged,
          isAction: isAction,
          actionStatus: actionStatus,
          dueDate: due,
        );

    test('exactly at due date is not yet overdue', () {
      expect(actionDueAt(fixedNow).isOverdue, isFalse);
    });

    test('one second past due date is overdue', () {
      expect(
          actionDueAt(fixedNow.subtract(const Duration(seconds: 1))).isOverdue,
          isTrue);
    });

    test('a completed action is never overdue', () {
      expect(
          actionDueAt(fixedNow.subtract(const Duration(days: 5)),
                  actionStatus: ActionStatus.completed)
              .isOverdue,
          isFalse);
    });

    test('a plain alert (not an action) is never overdue', () {
      expect(
          actionDueAt(fixedNow.subtract(const Duration(days: 5)),
                  isAction: false)
              .isOverdue,
          isFalse);
    });
  });
}
