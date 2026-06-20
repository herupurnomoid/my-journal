import datetime
import json
from firebase_admin import messaging, firestore
from app.connections.firebase import get_firestore_client
from app.api.ai.use_cases import AIUseCases

class NotificationUseCases:
    @staticmethod
    def process_inactive_users_notifications():
        db = get_firestore_client()
        users_ref = db.collection('users')
        journals_ref = db.collection('journals')
        
        now = datetime.datetime.now(datetime.timezone.utc)
        forty_eight_hours_ago = now - datetime.timedelta(hours=48)
        twenty_four_hours_ago = now - datetime.timedelta(hours=24)
        
        # 1. Ambil semua data pengguna
        users = users_ref.stream()
        
        sent_count = 0
        
        for user_doc in users:
            user_data = user_doc.to_dict()
            uid = user_doc.id
            fcm_token = user_data.get('fcmToken')
            
            # Lewati jika tidak ada FCM Token
            if not fcm_token:
                continue
                
            # Cek kapan terakhir kali kita mengirim notifikasi untuk mencegah spam
            last_notif = user_data.get('lastNotificationSentAt')
            if last_notif:
                if isinstance(last_notif, datetime.datetime):
                    if last_notif.tzinfo is None:
                        last_notif = last_notif.replace(tzinfo=datetime.timezone.utc)
                    
                    if last_notif > twenty_four_hours_ago:
                        continue # Sudah dikirim dalam waktu kurang dari 24 jam, lewati
            
            # 2. Cek jurnal terakhir milik pengguna ini
            user_journals = (
                journals_ref.where('userId', '==', uid)
                .order_by('createdAt', direction=firestore.Query.DESCENDING)
                .limit(1)
                .stream()
            )
            
            latest_journal = None
            for j in user_journals:
                latest_journal = j.to_dict()
                break
            
            # Tentukan apakah inaktif dan pesan yang tepat
            is_inactive = False
            notification_title = "Hai! Gimana harimu? ✨"
            notification_body = ""
            
            if not latest_journal:
                # Tidak ada jurnal sama sekali
                is_inactive = True
                notification_body = "Kamu belum pernah menulis jurnal. Yuk, mulai ceritakan harimu!"
            else:
                created_at = latest_journal.get('createdAt')
                if isinstance(created_at, datetime.datetime):
                    if created_at.tzinfo is None:
                        created_at = created_at.replace(tzinfo=datetime.timezone.utc)
                    
                    if created_at < forty_eight_hours_ago:
                        is_inactive = True
                        hours_inactive = 48
                    elif created_at < twenty_four_hours_ago:
                        is_inactive = True
                        hours_inactive = 24
                        
            # Jika inaktif dan memiliki jurnal sebelumnya, gunakan AI untuk personalisasi pesan
            if is_inactive and latest_journal:
                content_raw = latest_journal.get('content', '')
                try:
                    # Coba parse jika formatnya adalah Quill Delta JSON
                    ops = json.loads(content_raw)
                    text_parts = [op.get('insert', '') for op in ops if isinstance(op.get('insert'), str)]
                    text_content = "".join(text_parts).strip()
                except Exception:
                    # Jika bukan JSON, gunakan raw string
                    text_content = content_raw
                    
                if text_content:
                    ai_message = AIUseCases.generate_notification_message(
                        title=latest_journal.get('title', 'Jurnal'),
                        content=text_content,
                        hours_inactive=hours_inactive
                    )
                    notification_body = ai_message
                        
            # 3. Kirim Push Notification via FCM jika tidak aktif
            if is_inactive:
                message = messaging.Message(
                    notification=messaging.Notification(
                        title=notification_title,
                        body=notification_body
                    ),
                    token=fcm_token,
                )
                
                try:
                    messaging.send(message)
                    # Update field penanda terakhir kali dikirim
                    users_ref.document(uid).update({
                        'lastNotificationSentAt': firestore.SERVER_TIMESTAMP
                    })
                    sent_count += 1
                except Exception as e:
                    print(f"Failed to send notification to {uid}: {e}")
                    
        return {"status": "success", "sent_count": sent_count, "timestamp": now.isoformat()}
