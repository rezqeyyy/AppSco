// Alamat API di Render
const String apiUrl = 'https://backendscoli.onrender.com/api/v1/detect-scoliosis';

// Batas tingkat risiko. Harus sama dengan risk_thresholds di pipeline_config.json.
const double riskLowMax = 0.35;

const double riskMidMax = 0.65;

const String appName = 'SKOLIOCEK';

// Bentuk foto yang dipakai aplikasi: lebar : tinggi = 3 : 4 (tegak).
// Bingkai kamera dan hasil fotonya memakai perbandingan ini.
const double photoAspect = 3 / 4;