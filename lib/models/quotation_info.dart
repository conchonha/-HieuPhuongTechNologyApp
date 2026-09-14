import 'quotation_item.dart';

class QuotationInfo {
  String soBG;
  String ngayBG;
  String sdtHotline;
  String kinhGui;
  String sdt;
  String maSoThue;
  String diaChi;
  List<QuotationItem> items;

  QuotationInfo({
    this.soBG = 'HP-BG-170726',
    this.ngayBG = '08/09/2026',
    this.sdtHotline = '0888 611 779',
    this.kinhGui = 'Quý Khách Hàng',
    this.sdt = '',
    this.maSoThue = '',
    this.diaChi = '',
    List<QuotationItem>? items,
  }) : items = items ?? [];

  double get tongTruocThue => items.fold(0.0, (sum, item) => sum + item.thanhTien);
  double get tongTienVat => items.fold(0.0, (sum, item) => sum + item.tienVat);
  double get tongSauThue => tongTruocThue + tongTienVat;
}
