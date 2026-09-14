class QuotationItem {
  final int stt;
  final String quyCach;
  final String nhanHieu;
  final String dvt;
  final double soLuong;
  final double donGia;
  final double vat; // theo % (ví dụ 8, 10, hoặc 0)
  final String ghiChu;

  QuotationItem({
    required this.stt,
    required this.quyCach,
    required this.nhanHieu,
    required this.dvt,
    required this.soLuong,
    required this.donGia,
    this.vat = 8.0,
    this.ghiChu = '',
  });

  double get thanhTien => soLuong * donGia;
  double get tienVat => thanhTien * (vat / 100.0);
  double get tongSauThue => thanhTien + tienVat;

  QuotationItem copyWith({
    int? stt,
    String? quyCach,
    String? nhanHieu,
    String? dvt,
    double? soLuong,
    double? donGia,
    double? vat,
    String? ghiChu,
  }) {
    return QuotationItem(
      stt: stt ?? this.stt,
      quyCach: quyCach ?? this.quyCach,
      nhanHieu: nhanHieu ?? this.nhanHieu,
      dvt: dvt ?? this.dvt,
      soLuong: soLuong ?? this.soLuong,
      donGia: donGia ?? this.donGia,
      vat: vat ?? this.vat,
      ghiChu: ghiChu ?? this.ghiChu,
    );
  }
}
