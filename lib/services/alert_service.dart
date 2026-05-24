import 'package:cloud_firestore/cloud_firestore.dart';

// =======================================================
// SERVICIO PRINCIPAL DE ALERTAS
// =======================================================
// Este servicio centraliza toda la lógica relacionada con:
// - Creación de alertas
// - Actualización de alertas
// - Chats
// - Ayudantes
// - Lectura de mensajes
// - Alertas comunitarias
// =======================================================

class AlertService {

  // =======================================================
  // INSTANCIA DE FIRESTORE
  // =======================================================
  // Accedemos a Firebase Firestore para leer y escribir datos
  // =======================================================
  final _db = FirebaseFirestore.instance;

  // =======================================================
  // CREACIÓN DE ALERTAS
  // =======================================================

  // -------------------------------------------------------
  // Crear una nueva alerta
  // -------------------------------------------------------
  Future<void> createAlert({
    required String title,
    required String type,
    required String description,
    required String priority,
    required String createdBy,
    required String createdByEmail,
    required String city,
    required String postalCode,
  }) async {

    await _db.collection('alerts').add({

      // Título de la alerta
      'title': title,

      // Tipo de alerta
      'type': type,

      // Descripción
      'description': description,

      // Estado inicial
      'status': 'activo',

      // Prioridad
      'priority': priority,

      // Usuario creador
      'createdBy': createdBy,

      // Email del creador
      'createdByEmail': createdByEmail,

      // Ciudad del creador
      'city': city,

      // Código postal
      'postalCode': postalCode,

      // Fecha de creación
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // =======================================================
  // CONSULTAS DE ALERTAS
  // =======================================================

  // -------------------------------------------------------
  // Alertas activas o en proceso creadas por un usuario
  // -------------------------------------------------------
  Stream<QuerySnapshot> getActiveAlertsByUser(
    String userId,
  ) {

    return _db
        .collection('alerts')
        .where(
          'createdBy',
          isEqualTo: userId,
        )
        .where(
          'status',
          whereIn: ['activo', 'en_proceso'],
        )
        .snapshots();
  }

  // -------------------------------------------------------
  // Alertas completadas del usuario actual
  // -------------------------------------------------------
  Stream<QuerySnapshot> getCompletedAlertsByUser(
    String userId,
  ) {

    return _db
        .collection('alerts')
        .where(
          'createdBy',
          isEqualTo: userId,
        )
        .where(
          'status',
          isEqualTo: 'completado',
        )
        .snapshots();
  }

  // -------------------------------------------------------
  // Obtener todas las alertas completadas
  // -------------------------------------------------------
  Stream<QuerySnapshot> getCompletedAlerts() {

    return _db
        .collection('alerts')
        .where(
          'status',
          isEqualTo: 'completado',
        )
        .snapshots();
  }

  // -------------------------------------------------------
  // Alertas donde el usuario ayuda
  // -------------------------------------------------------
  Stream<QuerySnapshot> getAlertsWhereUserHelps(
    String userId,
  ) {

    return _db
        .collection('alerts')
        .where(
          'helpersIds',
          arrayContains: userId,
        )
        .where(
          'status',
          whereIn: ['activo', 'en_proceso'],
        )
        .snapshots();
  }

  // -------------------------------------------------------
  // Alertas creadas por el usuario
  // -------------------------------------------------------
  Stream<QuerySnapshot> getAlertsCreatedByUser(
    String userId,
  ) {

    return _db
        .collection('alerts')
        .where(
          'createdBy',
          isEqualTo: userId,
        )
        .where(
          'status',
          whereIn: ['activo', 'en_proceso'],
        )
        .snapshots();
  }

  // -------------------------------------------------------
  // Alertas comunitarias por código postal
  // -------------------------------------------------------
  Stream<QuerySnapshot> getCommunityAlerts({
    required String postalCode,
    required String currentUserId,
  }) {

    return _db
        .collection('alerts')

        // Mismo código postal
        .where(
          'postalCode',
          isEqualTo: postalCode,
        )

        // Solo alertas activas
        .where(
          'status',
          whereIn: ['activo', 'en_proceso'],
        )

        .snapshots();
  }

  // =======================================================
  // ACTUALIZACIÓN DE ALERTAS
  // =======================================================

  // -------------------------------------------------------
  // Actualizar alerta completa
  // -------------------------------------------------------
  Future<void> updateAlert({
    required String alertId,
    required String type,
    required String description,
    required String priority,
    required String status,
  }) async {

    await _db
        .collection('alerts')
        .doc(alertId)
        .update({

      'type': type,

      'description': description,

      'priority': priority,

      'status': status,

      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // -------------------------------------------------------
  // Actualizar solo el estado
  // -------------------------------------------------------
  Future<void> updateAlertStatus({
    required String alertId,
    required String status,
  }) async {

    await _db
        .collection('alerts')
        .doc(alertId)
        .update({

      'status': status,

      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // -------------------------------------------------------
  // Eliminar alerta
  // -------------------------------------------------------
  Future<void> deleteAlert(String alertId) async {

    await _db
        .collection('alerts')
        .doc(alertId)
        .delete();
  }

  // =======================================================
  // SISTEMA DE AYUDANTES
  // =======================================================

  // -------------------------------------------------------
  // Unirse como ayudante
  // -------------------------------------------------------
  Future<void> joinAlert({
    required String alertId,
    required String userId,
    required String name,
    required String email,
  }) async {

    // Guardamos ayudante en subcolección helpers
    await _db
        .collection('alerts')
        .doc(alertId)
        .collection('helpers')
        .doc(userId)
        .set({

      // UID ayudante
      'userId': userId,

      // Nombre ayudante
      'name': name,

      // Email ayudante
      'email': email,

      // Fecha unión
      'joinedAt': FieldValue.serverTimestamp(),
    });

    // Añadimos ID al array helpersIds
    await _db
        .collection('alerts')
        .doc(alertId)
        .update({

      'helpersIds': FieldValue.arrayUnion([
        userId,
      ]),
    });
  }

  // -------------------------------------------------------
  // Obtener ayudantes de una alerta
  // -------------------------------------------------------
  Stream<QuerySnapshot> getAlertHelpers(
    String alertId,
  ) {

    return _db
        .collection('alerts')
        .doc(alertId)
        .collection('helpers')
        .snapshots();
  }

  // =======================================================
  // SISTEMA DE CHAT
  // =======================================================

  // -------------------------------------------------------
  // Enviar mensaje al chat
  // -------------------------------------------------------
  Future<void> sendMessage({
    required String alertId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {

    await _db
        .collection('alerts')
        .doc(alertId)
        .collection('messages')
        .add({

      // Texto mensaje
      'text': text,

      // UID remitente
      'senderId': senderId,

      // Nombre remitente
      'senderName': senderName,

      // Fecha envío
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // -------------------------------------------------------
  // Obtener mensajes del chat
  // -------------------------------------------------------
  Stream<QuerySnapshot> getMessages(
    String alertId,
  ) {

    return _db
        .collection('alerts')
        .doc(alertId)
        .collection('messages')

        // Orden cronológico
        .orderBy('createdAt')

        .snapshots();
  }

  // =======================================================
  // SISTEMA DE LECTURA DE MENSAJES
  // =======================================================

  // -------------------------------------------------------
  // Marcar chat como leído
  // -------------------------------------------------------
  Future<void> markChatAsRead({
    required String alertId,
    required String userId,
  }) async {

    await _db
        .collection('alerts')
        .doc(alertId)
        .collection('readStatus')
        .doc(userId)
        .set({

      'lastReadAt':
          FieldValue.serverTimestamp(),
    });
  }

  // -------------------------------------------------------
  // Obtener estado de lectura
  // -------------------------------------------------------
  Stream<DocumentSnapshot> getReadStatus({
    required String alertId,
    required String userId,
  }) {

    return _db
        .collection('alerts')
        .doc(alertId)
        .collection('readStatus')
        .doc(userId)
        .snapshots();
  }

  // -------------------------------------------------------
  // Obtener mensajes no leídos
  // -------------------------------------------------------
  Stream<QuerySnapshot> getUnreadMessages({
    required String alertId,
    required String userId,
    required Timestamp lastReadAt,
  }) {

    return _db
        .collection('alerts')
        .doc(alertId)
        .collection('messages')
        .where(
          'createdAt',
          isGreaterThan: lastReadAt,
        )
        .snapshots();
  }
}
