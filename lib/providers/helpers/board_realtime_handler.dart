import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/board_element.dart';
import 'board_local_storage.dart';

class BoardRealtimeHandler {
  static void handlePayload({
    required PostgresChangePayload payload,
    required List<BoardElement> elements,
    required void Function() notify,
  }) {
    try {
      final record = payload.newRecord;
      final oldRecord = payload.oldRecord;

      if (payload.eventType == PostgresChangeEvent.delete) {
        final cloudId = (oldRecord['id'] as num?)?.toInt();
        if (cloudId != null) {
          elements.removeWhere((e) => e.cloudId == cloudId);
          notify();
          BoardLocalStorage.deleteByCloudId(cloudId);
        }
        return;
      }

      if (record.isEmpty) return;
      final incoming = BoardElement.fromCloudRow(record);
      if (incoming.cloudId == null) return;

      final idx = elements.indexWhere((e) => e.cloudId == incoming.cloudId);
      if (idx == -1) {
        elements.add(incoming);
        notify();
        BoardLocalStorage.insertFromCloud(incoming).then((newId) {
          final insertedIdx =
              elements.indexWhere((e) => e.cloudId == incoming.cloudId);
          if (insertedIdx != -1) {
            elements[insertedIdx] = incoming.copyWith(id: newId);
          }
        }).catchError((e) {
          developer.log('BoardRealtimeHandler realtime insert error: $e');
        });
      } else {
        final current = elements[idx];
        final currentUp =
            DateTime.tryParse(current.updatedAt ?? '') ?? DateTime(1970);
        final incomingUp =
            DateTime.tryParse(incoming.updatedAt ?? '') ?? DateTime(1970);

        if (incomingUp.isAfter(currentUp) ||
            incomingUp.isAtSameMomentAs(currentUp)) {
          elements[idx] = incoming.copyWith(id: current.id);
          notify();
          BoardLocalStorage.updateElement(
            incoming.copyWith(id: current.id),
          ).catchError((e) {
            developer.log('BoardRealtimeHandler realtime update error: $e');
          });
        }
      }
    } catch (e) {
      developer.log('BoardRealtimeHandler handlePayload error: $e');
    }
  }
}
