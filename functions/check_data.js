const admin = require('firebase-admin');

admin.initializeApp({
  projectId: 'zoop-36b4f'
});

const db = admin.firestore();

async function checkData() {
  console.log('=== Checking links collection ===');
  const linksSnap = await db.collection('links').limit(10).get();
  console.log(`Found ${linksSnap.size} links`);
  linksSnap.forEach(doc => {
    console.log(`- ${doc.id}:`, JSON.stringify(doc.data(), null, 2));
  });

  console.log('\n=== Checking users collection ===');
  const usersSnap = await db.collection('users').limit(5).get();
  console.log(`Found ${usersSnap.size} users`);
  usersSnap.forEach(doc => {
    console.log(`- ${doc.id}:`, doc.data().username, doc.data().email);
  });
}

checkData().then(() => process.exit(0)).catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
