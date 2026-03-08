importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBMArRYYuXEr9sJzijtGd3uuDSefv0HwO0',
  appId: '1:37292745207:web:ef332882cea9790a390ef2',
  messagingSenderId: '37292745207',
  projectId: 'zoop-36b4f',
  authDomain: 'zoop-36b4f.firebaseapp.com',
  storageBucket: 'zoop-36b4f.firebasestorage.app',
});

const messaging = firebase.messaging();

// 백그라운드 메시지 핸들러
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);

  const notificationTitle = payload.notification?.title || 'ZOOP';
  const notificationOptions = {
    body: payload.notification?.body || '새로운 알림이 있습니다.',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data,
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

// 알림 클릭 핸들러
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification click ', event);
  event.notification.close();

  event.waitUntil(
    clients.openWindow('/')
  );
});
