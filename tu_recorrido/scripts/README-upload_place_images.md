Upload Place Images
===================

This small script uploads image files to Firebase Storage and appends them to the `imagenes` array of an `estaciones/{placeId}` document in Firestore.

Prerequisites
-------------
- Node.js (14+)
- A Firebase service account JSON file with permission to write to Firestore and Storage (create one in Firebase Console > Project settings > Service accounts > Generate new private key).
- Install dependencies in the `scripts/` folder.

Install
-------
Open PowerShell in the `scripts` folder and run:

```powershell
npm init -y;
npm install firebase-admin mime
```

Usage
-----
```powershell
node upload_place_images.js --serviceAccount ./serviceAccountKey.json --bucket your-bucket.appspot.com --placeId PLACE_ID ./img1.jpg ./img2.jpg
```

Notes
-----
- The script uploads each file to Storage path `estaciones/{placeId}/img_<timestamp>_<index>.<ext>`.
- After upload it generates a signed URL (long expiration) and adds an object { url, path, alt } to `estaciones/{placeId}.imagenes` using arrayUnion.
- I cannot run this script against your Firebase from here. Run it locally with your service account.

Example
-------
If you have three files in `scripts/images/` and the `placeId` is `ABC123`, run:

```powershell
node upload_place_images.js --serviceAccount ./serviceAccountKey.json --bucket myproject.appspot.com --placeId ABC123 .\images\palacio1.jpg .\images\palacio2.jpg .\images\palacio3.jpg
```
