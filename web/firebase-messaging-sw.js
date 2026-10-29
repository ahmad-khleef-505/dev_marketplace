importScripts(
  'https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js',
);
importScripts(
  'https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js',
);

firebase.initializeApp({
  apiKey: 'AIzaSyBa4XhSpUj_tifN2NHjKRXER4pE5RprFgo',
  appId: '1:18451032455:web:1f6aafe69074bf23358b22',
  messagingSenderId: '18451032455',
  projectId: 'devmarketplace-5e82d',
  authDomain: 'devmarketplace-5e82d.firebaseapp.com',
  storageBucket: 'devmarketplace-5e82d.firebasestorage.app',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notification = payload.notification || {};
  const title = notification.title || 'إشعار جديد';
  const options = {
    body: notification.body || '',
    icon: '/icons/Icon-192.png',
    data: payload.data || {},
  };

  self.registration.showNotification(title, options);
});
