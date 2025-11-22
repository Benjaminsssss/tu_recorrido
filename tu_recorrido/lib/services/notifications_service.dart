import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

/// Servicio para notificaciones locales usando Awesome Notifications
class AwesomeNotifService {
	AwesomeNotifService._();
	static final AwesomeNotifService instance = AwesomeNotifService._();

	static const String alertsChannelKey = 'alerts';

	Future<void> init() async {
		await AwesomeNotifications().initialize(
			null, // usa icono por defecto del launcher
			[
				NotificationChannel(
					channelKey: alertsChannelKey,
					channelName: 'Recordatorios Tu Recorrido',
					channelDescription: 'Recordatorios para explorar tu ciudad',
					importance: NotificationImportance.High,
					defaultPrivacy: NotificationPrivacy.Private,
					playSound: true,
					onlyAlertOnce: true,
					ledColor: Colors.deepPurple,
					defaultColor: Colors.deepPurple,
					groupKey: 'tu_recorrido_reminders',
				),
			],
			debug: false,
		);
	}

	Future<void> requestPermissionIfNeeded() async {
		final allowed = await AwesomeNotifications().isNotificationAllowed();
		if (!allowed) {
			await AwesomeNotifications().requestPermissionToSendNotifications();
		}
	}

	/// Dispara una notificación simple con el logo de la app y el mensaje pedido
	Future<void> showExploreReminder() async {
		await AwesomeNotifications().createNotification(
			content: NotificationContent(
				id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
				channelKey: alertsChannelKey,
				title: 'Tu Recorrido',
				body: '¡Ve a explorar tu ciudad!',
				notificationLayout: NotificationLayout.Default,
				// Usa el ícono del app (ya configurado por flutter_launcher_icons)
				largeIcon: 'resource://mipmap/ic_launcher',
			),
		);
	}

	/// Programa solo 3 recordatorios diarios (garantizado, sin duplicados)
	Future<void> scheduleDailyExploreReminders() async {
		await cancelAll(); // Cancela todas las notificaciones previas
		final now = DateTime.now();
		// Horas definitivas aproximadamente cada 8h
		final hours = [9, 17, 22];
		final ids = [8001, 8002, 8003];
		for (var i = 0; i < hours.length; i++) {
			final target = DateTime(now.year, now.month, now.day, hours[i]);
			await AwesomeNotifications().createNotification(
				content: NotificationContent(
					id: ids[i],
					channelKey: alertsChannelKey,
					title: 'Tu Recorrido',
					body: '¡Ve a explorar tu ciudad!',
					largeIcon: 'resource://mipmap/ic_launcher',
					groupKey: 'tu_recorrido_reminders',
					notificationLayout: NotificationLayout.Default,
				),
				schedule: NotificationCalendar(
					hour: target.hour,
					minute: 0,
					second: 0,
					repeats: true,
					allowWhileIdle: true,
				),
			);
		}
	}

	/// Programa un recordatorio cada hora (24 veces al día), a minuto fijo (por defecto :00)
	Future<void> scheduleHourlyExploreReminders({int minute = 0}) async {
		// Cancelamos los anteriores para evitar duplicados si cambiamos de estrategia
		await cancelAll();
		await AwesomeNotifications().createNotification(
			content: NotificationContent(
				id: 8100,
				channelKey: alertsChannelKey,
				title: 'Tu Recorrido',
				body: '¡Ve a explorar tu ciudad!',
				largeIcon: 'resource://mipmap/ic_launcher',
				groupKey: 'tu_recorrido_reminders',
				notificationLayout: NotificationLayout.Default,
			),
			schedule: NotificationCalendar(
				minute: minute.clamp(0, 59),
				second: 0,
				repeats: true, // se disparará cada hora al minuto indicado
				allowWhileIdle: true,
			),
		);
	}

	/// Reprogramar (p.ej. llamado tras reinicio si fuera necesario manualmente)
	Future<void> rescheduleAll() async {
		await cancelAll();
		await scheduleDailyExploreReminders();
	}

	Future<void> cancelAll() async {
		await AwesomeNotifications().cancelAll();
	}
}

