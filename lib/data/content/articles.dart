import 'package:flutter/material.dart' hide Text;

import '../models/article.dart';

const List<Article> articles = <Article>[
  Article(
    title: 'Apa itu skoliosis?',
    shortTitle: 'Apa itu skoliosis?',
    summary: 'Tulang belakang yang melengkung ke samping, dan kenapa penting dikenali sejak dini.',
    icon: Icons.menu_book_outlined,
    body: <String>[
      'Skoliosis adalah kondisi tulang belakang yang melengkung ke samping, sering kali disertai putaran ruas tulang belakang. Dilihat dari belakang, tulang belakang biasanya tampak lurus. Pada skoliosis, bentuknya bisa menyerupai huruf C atau S.',
      'Skoliosis bisa muncul pada usia berapa pun, tetapi paling sering ditemukan pada masa pertumbuhan remaja. Pada sebagian besar kasus penyebab pastinya tidak diketahui. Jenis ini disebut skoliosis idiopatik.',
      'Banyak kasus tergolong ringan dan cukup dipantau secara berkala. Lengkung yang terus bertambah bisa memerlukan penanganan, misalnya penyangga (brace) atau operasi, sesuai penilaian dokter.',
      'Karena itu, mengenali tandanya lebih awal membantu dokter memantau dan menentukan penanganan pada waktu yang tepat.',
    ],
  ),
  Article(
    title: 'Tanda yang bisa dilihat di rumah',
    shortTitle: 'Tanda di rumah',
    summary: 'Bahu, tulang belikat, dan pinggul yang tidak sejajar',
    icon: Icons.visibility_outlined,
    body: <String>[
      'Minta orang yang diperiksa berdiri tegak membelakangi Anda, lalu perhatikan hal berikut:',
      '- Bahu kiri dan kanan tidak sama tinggi',
      '- Salah satu tulang belikat lebih menonjol',
      '- Lekuk pinggang tidak simetris, atau satu pinggul tampak lebih tinggi',
      '- Tubuh tampak condong ke satu sisi',
      '- Saat membungkuk ke depan, satu sisi punggung atau rusuk tampak lebih tinggi',
      'Tanda ini tidak selalu berarti skoliosis. Kebiasaan berdiri dan postur sehari-hari juga bisa membuat tubuh tampak tidak simetris. Yang bisa memastikannya adalah pemeriksaan dokter.',
    ],
  ),
  Article(
    title: 'Cara mengambil foto yang benar',
    shortTitle: 'Cara foto yang benar',
    summary: 'Posisi berdiri, jarak kamera, dan latar foto',
    icon: Icons.photo_camera_outlined,
    body: <String>[
      'Hasil screening sangat bergantung pada fotonya. Ikuti panduan ini setiap kali mengambil foto:',
      '- Minta orang lain memotret dari belakang',
      '- Badan dari pangkal leher sampai pinggul memenuhi bingkai; kepala tidak perlu ikut terfoto',
      '- Jarak kamera sekitar 1 meter, HP setinggi tengah punggung',
      '- Berdiri tegak dan rileks, kedua kaki sejajar, tangan di samping badan',
      '- Kamera tegak dan sejajar punggung, tidak miring atau dari atas',
      '- Pakai latar yang polos dan cahaya yang cukup',
      'Hindari pose lain, misalnya tangan diangkat atau badan menoleh. Pose seperti itu mengubah posisi bahu dan tulang belikat, sehingga skornya bisa tinggi walaupun tulang belakangnya normal.',
    ],
  ),
  Article(
    title: 'Cara membaca hasil screening',
    shortTitle: 'Membaca hasil',
    summary: 'Arti skor, tingkat risiko, dan titik pengukuran',
    icon: Icons.show_chart,
    body: <String>[
      'Skor risiko adalah perkiraan model tentang seberapa besar kemungkinan postur pada foto tidak tergolong normal. Skor ini bukan ukuran derajat lengkung tulang belakang.',
      'Di aplikasi ini skor di bawah 35% disebut rendah, 35% sampai 65% sedang, dan di atas 65% tinggi.',
      'Keyakinan model menunjukkan seberapa yakin model pada jawabannya. Kalau rendah, ulangi dengan foto yang lebih jelas.',
      'Titik pengukuran di atas foto adalah titik tubuh yang dikenali model. Garis kiri-kanan menghubungkan pasangan titik, misalnya kedua bahu. Sumbu tubuh menghubungkan titik tengahnya dari atas ke bawah.',
      'Periksa selalu posisi titiknya. Kalau titik tidak jatuh di bagian tubuh yang benar, hasilnya tidak bisa dipercaya dan fotonya perlu diulang.',
    ],
  ),
  Article(
    title: 'Kapan perlu ke dokter',
    shortTitle: 'Kapan ke dokter',
    summary: 'Langkah setelah hasil sedang atau tinggi',
    icon: Icons.local_hospital_outlined,
    body: <String>[
      'Pertimbangkan periksa ke dokter kalau:',
      '- Tanda seperti bahu atau pinggul tidak sejajar terlihat jelas, atau makin jelas dari waktu ke waktu',
      '- Hasil screening berulang kali sedang atau tinggi pada foto yang diambil dengan benar',
      '- Ada nyeri punggung yang menetap',
      '- Yang diperiksa anak atau remaja yang masih tumbuh dan tandanya terlihat',
      'Dokter biasanya melakukan pemeriksaan fisik dan, bila perlu, meminta rontgen untuk mengukur besar lengkungnya.',
      'Aplikasi ini tidak menggantikan pemeriksaan tersebut.',
    ],
  ),
];