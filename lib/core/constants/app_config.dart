// Alamat API di Render
const String apiUrl = 'https://backendscoli.onrender.com/api/v1/detect-scoliosis';

// Batas tingkat risiko. Harus sama dengan risk_thresholds di pipeline_config.json.
const double riskLowMax = 0.35;

const double riskMidMax = 0.65;

const String appName = 'SKOLIOCEK';

// Bentuk foto yang dipakai aplikasi: lebar : tinggi = 3 : 4 (tegak).
// Bingkai kamera dan hasil fotonya memakai perbandingan ini.
const double photoAspect = 3 / 4;

// Skor risiko di atas nilai ini: pengguna wajib masuk, mengisi data diri,
// lalu diarahkan ke rumah sakit terdekat.
const double referralThreshold = 0.60;

// Client ID OAuth jenis "Web application" dari Google Cloud Console
// (bentuknya ...apps.googleusercontent.com). Bukan rahasia. Wajib diisi untuk login Google di Android.
const String googleServerClientId = '275366545565-h6c4pudj1g0ksv14qvhqova4g360u6nr.apps.googleusercontent.com';

// Supabase: Project Settings -> API Keys.
// URL proyek, bentuknya https://xxxx.supabase.co
const String supabaseUrl = 'https://icgnaxpalspfgxizbdwy.supabase.co';
// Publishable key (sb_publishable_...) atau anon key lama. Boleh ada di aplikasi
// karena data dilindungi Row Level Security. JANGAN isi dengan secret / service_role key.
const String supabasePublishableKey = 'sb_publishable_bikSbyyfd35hK3h59xbdFA_nT8ZdLms';

const String chatUrl = 'https://backendscoli.onrender.com/api/v1/chat';