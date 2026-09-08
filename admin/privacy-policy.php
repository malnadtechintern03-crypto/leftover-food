<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Privacy Policy — Home Pantry</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <style>
    :root {
      --primary: #10B981;
      --primary-dark: #059669;
      --dark-bg: #0F172A;
      --card-bg: #FFFFFF;
      --text-main: #1E293B;
      --text-muted: #64748B;
      --border-color: #E2E8F0;
    }
    body {
      font-family: 'Plus Jakarta Sans', system-ui, -apple-system, sans-serif;
      background-color: #F8FAFC;
      color: var(--text-main);
      line-height: 1.7;
    }
    .header-banner {
      background: linear-gradient(135deg, #0F172A 0%, #1E293B 100%);
      color: #FFFFFF;
      padding: 60px 0 50px 0;
      border-bottom: 1px solid #334155;
    }
    .policy-card {
      background: var(--card-bg);
      border: 1px solid var(--border-color);
      border-radius: 20px;
      padding: 40px;
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
      margin-top: -30px;
      margin-bottom: 60px;
    }
    h2 {
      font-size: 20px;
      font-weight: 800;
      color: #0F172A;
      margin-top: 32px;
      margin-bottom: 14px;
      border-bottom: 2px solid #F1F5F9;
      padding-bottom: 8px;
    }
    h3 {
      font-size: 16px;
      font-weight: 700;
      color: #334155;
      margin-top: 20px;
      margin-bottom: 10px;
    }
    .badge-app {
      background: rgba(16, 185, 129, 0.2);
      color: #10B981;
      font-weight: 700;
      padding: 6px 14px;
      border-radius: 30px;
      font-size: 12px;
      display: inline-block;
      margin-bottom: 14px;
    }
    .info-box {
      background-color: #F0FDF4;
      border-left: 4px solid #10B981;
      padding: 16px 20px;
      border-radius: 8px;
      margin: 20px 0;
      color: #166534;
      font-size: 14.5px;
    }
    footer {
      background: #FFFFFF;
      border-top: 1px solid var(--border-color);
      padding: 24px 0;
      font-size: 13px;
      color: var(--text-muted);
    }
  </style>
</head>
<body>

  <!-- Header Banner -->
  <header class="header-banner text-center">
    <div class="container">
      <span class="badge-app">Official Google Play Privacy Policy</span>
      <h1 class="fw-bold mb-2" style="font-size: 32px; letter-spacing: -0.5px;">Privacy Policy</h1>
      <p class="text-white-50 mb-0">Home Pantry: Smart Food & Expiry Manager (`com.homepantry.app`)</p>
      <p class="text-white-50 small mt-1">Effective Date: September 7, 2026 • Last Updated: September 7, 2026</p>
    </div>
  </header>

  <!-- Content Container -->
  <main class="container">
    <div class="row justify-content-center">
      <div class="col-lg-10">
        <article class="policy-card">
          <div class="info-box">
            <strong>Key Summary:</strong> Home Pantry is built with an <strong>offline-first privacy architecture</strong>. Your pantry items, expiry dates, grocery receipts, and notes remain entirely on your private device. We do not sell, track, or share your personal data.
          </div>

          <h2>1. Introduction</h2>
          <p>
            Home Pantry ("we", "our", or "the application") is committed to protecting the privacy and personal data of our users ("you"). This Privacy Policy explains how our mobile application and connected services handle information when you use <strong>Home Pantry</strong> on Android devices.
          </p>

          <h2>2. Data Collection & Storage (Offline-First Guarantee)</h2>
          <p>
            The core functionality of Home Pantry operates entirely offline. 
          </p>
          <ul>
            <li><strong>Local SQLite Database:</strong> All grocery records, product names, categories, purchase prices, expiration dates, reminders, and consumption history are stored strictly on your local device in an application-private database.</li>
            <li><strong>No Compulsory Cloud Account:</strong> You can use all core features of Home Pantry without creating an online account, providing an email address, or submitting personal identifiers.</li>
            <li><strong>Optional Self-Hosted Admin Sync:</strong> If you voluntarily connect Home Pantry to a self-hosted local Home Pantry Web Admin Console (via local Wi-Fi or your custom server URL), data synchronization occurs solely between your mobile device and your self-controlled server.</li>
          </ul>

          <h2>3. Device Permissions & How They Are Used</h2>
          <p>Home Pantry only requests permissions strictly essential for user-facing features:</p>

          <h3>A. Camera Permission (`android.permission.CAMERA`)</h3>
          <p>
            <strong>Purpose:</strong> Used exclusively when you open the in-app Barcode Scanner to recognize product barcodes (such as EAN-13 or UPC) for quick grocery logging.
            <br>
            <strong>Privacy Protection:</strong> All barcode analysis occurs on-device in real-time. Camera frames are never recorded, transmitted across the internet, or stored on external servers.
          </p>

          <h3>B. Notification Permission (`android.permission.POST_NOTIFICATIONS`)</h3>
          <p>
            <strong>Purpose:</strong> Used on Android 13 (API level 33) and above to schedule and display local alerts before your groceries reach their expiration date.
            <br>
            <strong>Privacy Protection:</strong> Reminders are scheduled locally on your device via the operating system alarm service. No third-party push notification services receive your food item names.
          </p>

          <h3>C. Vibration Permission (`android.permission.VIBRATE`)</h3>
          <p>
            <strong>Purpose:</strong> Provides haptic feedback when a barcode is scanned and alerts you when an expiration reminder fires.
          </p>

          <h3>D. Internet Access (`android.permission.INTERNET`)</h3>
          <p>
            <strong>Purpose:</strong> Used when opening web recipe instructions or synchronizing data with your self-hosted Home Pantry Admin Console.
          </p>

          <h2>4. Third-Party Services & Analytics</h2>
          <p>
            Home Pantry does not embed invasive third-party ad networks or behavioral advertising trackers.
          </p>
          <ul>
            <li><strong>Zero Ad Tracking:</strong> We do not serve third-party ads and do not collect advertising IDs.</li>
            <li><strong>External Recipe Videos:</strong> If you choose to watch cooking guides via YouTube links, the YouTube application or browser handles the video stream under Google’s standard privacy policies.</li>
          </ul>

          <h2>5. Data Retention & Deletion Rights</h2>
          <p>
            You have complete sovereignty over your data at all times:
          </p>
          <ul>
            <li><strong>In-App Purge:</strong> You can wipe all grocery records and history anytime by navigating to <strong>Chef Profile → Purge All Pantry Data</strong>.</li>
            <li><strong>App Uninstall:</strong> Uninstalling the application completely deletes the local SQLite database and all cached files from your device.</li>
            <li><strong>Data Export:</strong> You can export all your grocery records to a standard CSV file or full JSON backup anytime via the Profile tools.</li>
          </ul>

          <h2>6. Children's Privacy</h2>
          <p>
            Home Pantry does not knowingly collect or solicit personal information from children under 13. The app is a general-utility grocery organization tool suitable for general audiences.
          </p>

          <h2>7. Security Safeguards</h2>
          <p>
            We implement industry-standard secure coding practices, including prepared SQL statements (to prevent injection), strict input validation, CSRF verification on admin endpoints, and sandboxed mobile app storage.
          </p>

          <h2>8. Changes to This Policy</h2>
          <p>
            We may update this Privacy Policy periodically. Any revisions will be reflected on this page with an updated "Last Updated" timestamp and highlighted in application release notes.
          </p>

          <h2>9. Contact Us</h2>
          <p>
            If you have questions, feedback, or requests regarding this Privacy Policy or Home Pantry, please contact our privacy compliance team:
          </p>
          <div class="p-3 bg-light rounded-3 border">
            <div><strong>Home Pantry Development Team</strong></div>
            <div>Email: <a href="mailto:privacy@homepantry.com">privacy@homepantry.com</a> / <a href="mailto:admin@homepantry.com">admin@homepantry.com</a></div>
            <div>Official Portal: <code>http://localhost/leftover/admin/</code></div>
          </div>
        </article>
      </div>
    </div>
  </main>

  <!-- Footer -->
  <footer class="text-center">
    <div class="container">
      &copy; <?= date('Y') ?> <strong>Home Pantry</strong> — Smart Food & Expiry Manager. All rights reserved.
    </div>
  </footer>

</body>
</html>
