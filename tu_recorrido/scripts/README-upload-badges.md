Bulk upload script for badge images

Files:
- upload_badges.js: Node script that uploads images to Firebase Storage and appends image objects to the 'imagenes' array in Firestore documents under `places/{placeId}`.

Usage

1. Prepare a mapping JSON file. Example `mapping.example.json`:

{
  "placeId1": "plaza_de_armas.jpg",
  "placeId2": "otro_lugar.png"
}

2. Put your images in a folder, e.g. `./images/`.

3. Install dependencies:

```powershell
npm init -y
npm install firebase-admin
```

4. Set credentials and storage bucket. Option A: set `GOOGLE_APPLICATION_CREDENTIALS` to a service account JSON and ensure the service account has permissions for Storage and Firestore. Also set `FIREBASE_STORAGE_BUCKET` env var to your bucket (e.g. `my-project.appspot.com`).

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = 'C:\path\to\serviceAccountKey.json'
$env:FIREBASE_STORAGE_BUCKET = 'my-project.appspot.com'
```

5. Run the script:

```powershell
node scripts\upload_badges.js mapping.json .\images
```

Notes
- The script uploads each file to `places/{placeId}/img_<timestamp>.<ext>` and appends an object `{ url, alt: '', path }` to the `imagenes` array in Firestore.
- The script obtains a signed URL valid for 1 year and stores it in `url`. If you prefer public URLs, adjust the script to call `file.makePublic()`.
- Ensure your Firestore rules allow `set`/`update` operations from the service account (they normally do).
- This script is intended for admin/bulk workflows and must be run securely from your machine or a protected environment.
