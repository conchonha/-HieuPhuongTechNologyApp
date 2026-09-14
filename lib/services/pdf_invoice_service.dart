import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/quotation_info.dart';
import '../utils/vietnamese_number_to_words.dart';

class PdfInvoiceService {
  static final PdfColor primaryTeal = PdfColor.fromHex('#005C53');
  static final PdfColor lightTeal = PdfColor.fromHex('#E0F2F1');
  static final PdfColor borderColor = PdfColor.fromHex('#424242');
  static final PdfColor lightBorderColor = PdfColor.fromHex('#9E9E9E');

  static final NumberFormat currencyFormatter = NumberFormat('#,###', 'vi_VN');

  static Future<Uint8List> generatePdf(QuotationInfo info) async {
    final pdf = pw.Document();

    // Tải font chữ Roboto hỗ trợ tiếng Việt đầy đủ
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontItalic = await PdfGoogleFonts.robotoItalic();
    final fontBoldItalic = await PdfGoogleFonts.robotoBoldItalic();

    // HPT Logo bằng vector SVG
    final logoSvg = '''
<svg width="100" height="90" viewBox="0 0 100 90" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 70V28L26 28V44H38V12L52 12V70H38V54H26V70H12Z" fill="#00796B"/>
  <path d="M52 12L68 12C78 12 84 18 84 28C84 38 78 44 68 44H52V12ZM66 34C70 34 72 32 72 28C72 24 70 22 66 22H64V34H66Z" fill="#004D40"/>
  <path d="M40 8L74 8L88 20H48L40 8Z" fill="#00897B"/>
</svg>
''';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          italic: fontItalic,
          boldItalic: fontBoldItalic,
        ),
        build: (pw.Context context) {
          return [
            // 1. TOP HEADER
            _buildTopHeader(info, logoSvg, fontBold, fontRegular),
            pw.SizedBox(height: 6),

            // 2. BẢNG BÁO GIÁ BANNER
            _buildBanner(fontBold),
            pw.SizedBox(height: 6),

            // 3. THÔNG TIN KHÁCH HÀNG & LỜI CHÀO
            _buildCustomerSection(info, fontBold, fontRegular, fontItalic),
            pw.SizedBox(height: 6),

            // 4. BẢNG CHI TIẾT VẬT TƯ & TỔNG TIỀN
            _buildQuotationTable(info, fontBold, fontRegular),
            pw.SizedBox(height: 6),

            // 5. BẰNG CHỮ & CÁC ĐIỀU KHOẢN GHI CHÚ
            _buildFooterSection(info, fontBold, fontRegular, fontItalic),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // --- 1. TOP HEADER ---
  static pw.Widget _buildTopHeader(
    QuotationInfo info,
    String logoSvg,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Logo bên trái
        pw.Container(
          width: 80,
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.SvgImage(svg: logoSvg, width: 65, height: 42),
              pw.SizedBox(height: 2),
              pw.Text(
                'HIẾU PHƯƠNG',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 8.5,
                  color: primaryTeal,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 8),

        // Thông tin công ty ở giữa
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'CÔNG TY TNHH HIỂU PHƯƠNG TECHNOLOGY',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 12.5,
                  color: primaryTeal,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'VPKD: 188/13/11A Đường Lò Lu, KP6, P. Long Phước, TP. Hồ Chí Minh, Việt Nam',
                style: pw.TextStyle(font: fontRegular, fontSize: 7.5),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'MST: 0318717656  |  info.hieuphuongtech@gmail.com  |  0888611779',
                style: pw.TextStyle(font: fontRegular, fontSize: 7.5),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 6),

        // Khung Số BG, Ngày BG, SĐT bên phải
        pw.Container(
          width: 135,
          padding: const pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: borderColor, width: 0.7),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildRightInfoRow('Số BG:', info.soBG.isNotEmpty ? info.soBG : 'HP-BG-170726', fontBold, fontRegular),
              pw.SizedBox(height: 2),
              _buildRightInfoRow('Ngày BG:', info.ngayBG.isNotEmpty ? info.ngayBG : '08/09/2026', fontBold, fontRegular),
              pw.SizedBox(height: 2),
              _buildRightInfoRow('SĐT:', info.sdtHotline.isNotEmpty ? info.sdtHotline : '0888 611 779', fontBold, fontRegular),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildRightInfoRow(
    String label,
    String value,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    return pw.Row(
      children: [
        pw.Text(label, style: pw.TextStyle(font: fontBold, fontSize: 7.5)),
        pw.SizedBox(width: 4),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(font: fontRegular, fontSize: 7.5),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  // --- 2. BANNER TIÊU ĐỀ ---
  static pw.Widget _buildBanner(pw.Font fontBold) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      decoration: pw.BoxDecoration(
        color: primaryTeal,
      ),
      child: pw.Center(
        child: pw.Text(
          'BẢNG BÁO GIÁ',
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 13,
            color: PdfColors.white,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  // --- 3. THÔNG TIN KHÁCH HÀNG ---
  static pw.Widget _buildCustomerSection(
    QuotationInfo info,
    pw.Font fontBold,
    pw.Font fontRegular,
    pw.Font fontItalic,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildCustomerLine('Kính gửi:', info.kinhGui.isNotEmpty ? info.kinhGui : 'Quý Khách Hàng', fontBold, fontRegular),
        _buildCustomerLine('SĐT:', info.sdt, fontBold, fontRegular),
        _buildCustomerLine('Mã số thuế:', info.maSoThue, fontBold, fontRegular),
        _buildCustomerLine('Địa chỉ:', info.diaChi, fontBold, fontRegular),
        pw.SizedBox(height: 3),
        pw.Text(
          'Lời đầu tiên, Hiếu Phương Technology CO., LTD xin trân trọng cảm ơn Quý khách hàng đã quan tâm đến sản phẩm và dịch vụ của công ty. Chúng tôi hân hạnh gửi bảng báo giá với nội dung chi tiết như sau:',
          style: pw.TextStyle(font: fontItalic, fontSize: 7.5),
        ),
      ],
    );
  }

  static pw.Widget _buildCustomerLine(
    String label,
    String value,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1.5),
      child: pw.Row(
        children: [
          pw.Text(label, style: pw.TextStyle(font: fontBold, fontSize: 8)),
          pw.SizedBox(width: 4),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(font: fontRegular, fontSize: 8),
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. BẢNG VẬT TƯ & TỔNG KẾT ---
  static pw.Widget _buildQuotationTable(
    QuotationInfo info,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    final headers = [
      'STT',
      'Quy cách vật tư',
      'Nhãn hiệu',
      'ĐVT',
      'SL',
      'Đơn Giá',
      'Thành Tiền',
      'Vat',
      'Ghi Chú',
    ];

    // Tạo danh sách các dòng dữ liệu (tối thiểu 4 dòng để giống mẫu phiếu)
    final rowsCount = info.items.length < 4 ? 4 : info.items.length;
    final List<List<String>> tableData = [];

    for (int i = 0; i < rowsCount; i++) {
      if (i < info.items.length) {
        final item = info.items[i];
        tableData.add([
          '${item.stt}',
          item.quyCach,
          item.nhanHieu,
          item.dvt,
          item.soLuong % 1 == 0 ? item.soLuong.toInt().toString() : item.soLuong.toString(),
          currencyFormatter.format(item.donGia),
          currencyFormatter.format(item.thanhTien),
          '${item.vat.toInt()}%',
          item.ghiChu,
        ]);
      } else {
        // Dòng trống giả lập giống mẫu
        tableData.add([
          '${i + 1}',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
        ]);
      }
    }

    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.6),
      columnWidths: const {
        0: pw.FixedColumnWidth(26), // STT
        1: pw.FlexColumnWidth(3.2), // Quy cách
        2: pw.FlexColumnWidth(1.4), // Nhãn hiệu
        3: pw.FixedColumnWidth(30), // ĐVT
        4: pw.FixedColumnWidth(28), // SL
        5: pw.FlexColumnWidth(1.6), // Đơn Giá
        6: pw.FlexColumnWidth(1.8), // Thành Tiền
        7: pw.FixedColumnWidth(28), // Vat
        8: pw.FlexColumnWidth(1.5), // Ghi Chú
      },
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: primaryTeal),
          children: headers.map((h) {
            return pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: pw.Text(
                h,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 7.5,
                  color: PdfColors.white,
                ),
                textAlign: pw.TextAlign.center,
              ),
            );
          }).toList(),
        ),

        // Các dòng vật phẩm
        ...tableData.map((row) {
          return pw.TableRow(
            children: [
              _buildCell(row[0], fontRegular, align: pw.Alignment.center), // STT
              _buildCell(row[1], fontRegular, align: pw.Alignment.centerLeft), // Quy cách
              _buildCell(row[2], fontRegular, align: pw.Alignment.center), // Nhãn hiệu
              _buildCell(row[3], fontRegular, align: pw.Alignment.center), // ĐVT
              _buildCell(row[4], fontRegular, align: pw.Alignment.center), // SL
              _buildCell(row[5], fontRegular, align: pw.Alignment.centerRight), // Đơn giá
              _buildCell(row[6], fontRegular, align: pw.Alignment.centerRight), // Thành tiền
              _buildCell(row[7], fontRegular, align: pw.Alignment.center), // Vat
              _buildCell(row[8], fontRegular, align: pw.Alignment.centerLeft), // Ghi chú
            ],
          );
        }),

        // 3 DÒNG TỔNG CỘNG
        // 1. TỔNG CỘNG TRƯỚC THUẾ
        pw.TableRow(
          children: [
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
              child: pw.Text(
                'TỔNG CỘNG TRƯỚC THUẾ',
                style: pw.TextStyle(font: fontBold, fontSize: 8),
              ),
            ),
            // Trống cho các cột giữa
            pw.Container(),
            pw.Container(),
            pw.Container(),
            pw.Container(),
            pw.Container(),
            _buildCell(
              info.items.isEmpty ? '-' : currencyFormatter.format(info.tongTruocThue),
              fontBold,
              align: pw.Alignment.centerRight,
            ),
            _buildCell('-', fontRegular, align: pw.Alignment.center),
            _buildCell('', fontRegular),
          ],
        ),

        // 2. THUẾ V.A.T
        pw.TableRow(
          children: [
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
              child: pw.Text(
                'THUẾ V.A.T',
                style: pw.TextStyle(font: fontBold, fontSize: 8),
              ),
            ),
            pw.Container(),
            pw.Container(),
            pw.Container(),
            pw.Container(),
            pw.Container(),
            _buildCell(
              info.items.isEmpty ? '-' : currencyFormatter.format(info.tongTienVat),
              fontBold,
              align: pw.Alignment.centerRight,
            ),
            _buildCell('-', fontRegular, align: pw.Alignment.center),
            _buildCell('', fontRegular),
          ],
        ),

        // 3. TỔNG CỘNG SAU THUẾ (nền xanh)
        pw.TableRow(
          decoration: pw.BoxDecoration(color: primaryTeal),
          children: [
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
              child: pw.Text(
                'TỔNG CỘNG SAU THUẾ',
                style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.white),
              ),
            ),
            pw.Container(),
            pw.Container(),
            pw.Container(),
            pw.Container(),
            pw.Container(),
            _buildCell(
              info.items.isEmpty ? '-' : currencyFormatter.format(info.tongSauThue),
              fontBold,
              align: pw.Alignment.centerRight,
              textColor: PdfColors.white,
            ),
            _buildCell('-', fontRegular, align: pw.Alignment.center, textColor: PdfColors.white),
            _buildCell('', fontRegular),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildCell(
    String text,
    pw.Font font, {
    pw.Alignment align = pw.Alignment.centerLeft,
    PdfColor? textColor,
  }) {
    return pw.Container(
      alignment: align,
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 3),
      constraints: const pw.BoxConstraints(minHeight: 18),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 7.5,
          color: textColor ?? PdfColors.black,
        ),
      ),
    );
  }

  // --- 5. FOOTER & ĐIỀU KHOẢN GHI CHÚ ---
  static pw.Widget _buildFooterSection(
    QuotationInfo info,
    pw.Font fontBold,
    pw.Font fontRegular,
    pw.Font fontItalic,
  ) {
    final words = info.items.isNotEmpty && info.tongSauThue > 0
        ? VietnameseNumberToWords.convert(info.tongSauThue)
        : '........................................................................';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Bằng chữ
        pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: 'Bằng chữ: ',
                style: pw.TextStyle(font: fontBold, fontSize: 8),
              ),
              pw.TextSpan(
                text: words,
                style: pw.TextStyle(font: fontItalic, fontSize: 8),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 3),

        // Tiêu đề Ghi chú
        pw.Text(
          'Ghi chú:',
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 8,
            decoration: pw.TextDecoration.underline,
          ),
        ),
        pw.SizedBox(height: 2),

        // Các điều khoản
        _buildTermItem('1. Đơn giá trên không bao gồm chi phí vận chuyển, chi phí thí nghiệm và lắp đặt tại công trình...', fontRegular),
        _buildTermItem('2. Hiệu lực báo giá: Có giá trị 1 ngày kể từ ngày báo giá.', fontRegular),
        _buildTermItem('3. Tiến độ giao hàng: 2 đến 3 ngày', fontRegular),
        _buildTermItem('4. Địa điểm giao hàng: Tại TPHCM cũ trước xác nhập.', fontRegular),
        _buildTermItem('5. Phương thức thanh toán: Thanh toán 100% trước khi nhận hàng. Theo thỏa thuận', fontRegular),
        _buildTermItem('6. Thời gian bảo hành:', fontRegular),
        _buildTermItem('7. Tài khoản đơn vị thụ hưởng:', fontRegular),

        // Thông tin tài khoản ngân hàng
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 10, top: 1),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '- TK1: Tên tài khoản: CÔNG TY TNHH HIẾU PHƯƠNG TECHNOLOGY',
                style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: primaryTeal),
              ),
              pw.Text(
                'Số tài khoản: 00901613913 - NH TMCP Tiên Phong (TPBank) - CN Bắc Sài Gòn',
                style: pw.TextStyle(font: fontRegular, fontSize: 7.5),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 6),

        // Lời kết
        pw.Center(
          child: pw.Text(
            'Hiếu Phương hy vọng sớm nhận được sự phản hồi từ Quý Khách hàng !',
            style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: primaryTeal),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTermItem(String text, pw.Font fontRegular) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1.2),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: fontRegular, fontSize: 7.2),
      ),
    );
  }
}
