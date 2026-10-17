# AppSco — Early Scoliosis Screening App

AppSco is an Android app for **early scoliosis risk screening** from a photo of the back. Scoliosis is a sideways curvature of the spine. The user takes a photo of the bare back from behind. The system then:

- marks points along the spine;
- measures the tilt and curvature of the spine;
- gives a **risk level: Low, Medium, or High**.

> ⚠️ **Not a diagnostic tool.** Results are only an estimate based on a photo. Only a medical examination (for example by an orthopaedic specialist, using a forward-bend test and X-ray) can confirm scoliosis.

This app was developed as part of a final-year project (FYP2).

---

## Features

- **Camera with a framing guide.** A torso outline (neck to hips) keeps every photo in the same position, and the flash turns on automatically for consistent lighting.
- **Photo guide** every time the camera opens: how to stand, how far away to take the photo, and what background to use.
- **Easy-to-read screening results:**
  - risk level and a score from 0 to 100;
  - the spine line drawn on the photo;
  - plain-language findings such as "Looks straight" or "Slightly curved";
  - recommended next steps;
  - detailed measurements for health professionals.
- **History and chart.** Track how the score changes over time. History is stored on the phone.
- **Educational articles** about scoliosis.
- **Accounts:** sign in with email/password or Google, or continue as a guest.
- **Nearest hospital referral.** When the score is above 60%, the user is asked to sign in and fill in personal details. The app then shows the nearest hospitals with directions.
- **Interactive tutorial** the first time the app is opened.
- **Over-the-air (OTA) updates.** Small updates install themselves without reinstalling the app.

---

## Download and Install (Android)

### 1. Download the APK
1. Open the **[Releases](../../releases)** page of this repository.
2. Choose the top release (the latest version).
3. Under **Assets**, tap **`app-release.apk`** to download it.

> You can open the Releases page directly in your phone's browser, or download the APK on a computer and send it to your phone.

### 2. Install
1. Open the downloaded APK, either from the download notification or from **File Manager → Downloads**.
2. If you see **"Install unknown apps"**, tap **Settings**, enable **Allow from this source**, then go back.
3. Tap **Install**, wait for it to finish, then tap **Open**.
4. Allow **camera** access when asked. **Location** access is only requested when you search for nearby hospitals.

### 3. Updating
- **Small updates** (design changes, bug fixes) are applied automatically:
  1. Fully close the app and open it again.
  2. Close it and open it once more.
- **Major updates** are announced on the Releases page. Download the new APK and install it over the old version. Your history is kept.

### Installation problems
| Problem | Solution |
|---|---|
| "App not installed" | Uninstall the old version first, then install again. This usually happens when the old version was installed over USB during development. |
| The Install button cannot be tapped | Temporarily turn off apps that draw over the screen, such as chat bubbles or screen filters. |
| Play Protect warning | Choose **Install anyway**. This warning appears for every APK that does not come from the Play Store. |

**Requirements:** Android 7.0 or newer, a rear camera with flash, and an internet connection.

---

## How to Use

1. On the **Home** screen, tap **Start screening**.
2. Read the photo guide, then tap **Got it, start**.
3. Ask someone to photograph your **back from behind**, about 1 metre away, with the phone at mid-back height. Before taking the photo:
   - Uncover your back or wear a thin, tight shirt, and tie up long hair.
   - Stand straight with your arms at your sides.
   - Line up your shoulders with the **Shoulders** line and your hips with the **Hips** line.
4. Wait for the analysis. The first request can take about a minute while the server wakes up.
5. Read the result and tap **Save to history** if you want to track your progress.

---

## How It Works

```
App (Flutter)  ──photo──▶  API server (Go + ONNX Runtime)  ──JSON result──▶  App
                             1. Image validation
                             2. Background removal (YOLOv8-seg)
                             3. Back detection + 15 spine keypoints (YOLOv8 Pose)
                             4. Posture feature extraction (angles, tilt, lateral curve deviation)
                             5. Classification (MLP) + score calibration
                             6. Risk level: Low / Medium / High
```

The models are trained in Google Colab on back-photo datasets from Roboflow Universe, exported to ONNX, and served by the API server.

---

## Tech Stack

| Part | Technology |
|---|---|
| Mobile app | Flutter (Dart), camera, geolocator, url_launcher |
| Accounts & database | Supabase (Auth + PostgreSQL with Row Level Security), Google Sign-In |
| API server | Go (Fiber) + ONNX Runtime, deployed on Render |
| Models | YOLOv8 Pose, YOLOv8-seg, MLP (PyTorch → ONNX) |
| Hospital data | OpenStreetMap (Overpass API) |
| OTA updates | Shorebird |

---

## Privacy

- Photos are sent to the server only for analysis and are **not stored on the server**.
- Saved photos and history stay **on the user's phone**.
- Account data, personal details, and result summaries (without photos) are stored in Supabase. Only the account owner can read them.

---

## Credits

- Dataset: [AI SpineCheck – Roboflow Universe](https://universe.roboflow.com/kumpun-dpujw/ai-spinecheck-vsuop) and related datasets on Roboflow Universe.
- Hospital data © [OpenStreetMap contributors](https://www.openstreetmap.org/copyright).
- Detection models: [Ultralytics YOLOv8](https://github.com/ultralytics/ultralytics).