import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'models/quotation_info.dart';
import 'models/quotation_item.dart';
import 'services/pdf_invoice_service.dart';
import 'utils/vietnamese_number_to_words.dart';

void main() {
  runApp(const HieuPhuongApp());
}

class HieuPhuongApp extends StatelessWidget {
  const HieuPhuongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hiếu Phương Technology',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF005C53),
          primary: const Color(0xFF005C53),
          secondary: const Color(0xFF00897B),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const QuotationScreen(),
    );
  }
}

class QuotationScreen extends StatefulWidget {
  const QuotationScreen({super.key});

  @override
  State<QuotationScreen> createState() => _QuotationScreenState();
}

class _QuotationScreenState extends State<QuotationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Thông tin báo giá
  late final QuotationInfo _info;

  // Controllers thông tin khách hàng
  late final TextEditingController _kinhGuiController;
  late final TextEditingController _sdtController;
  late final TextEditingController _mstController;
  late final TextEditingController _diaChiController;
  late final TextEditingController _soBGController;
  late final TextEditingController _ngayBGController;

  // Controllers cho form nhập vật phẩm hiện tại
  final _quyCachController = TextEditingController();
  final _nhanHieuController = TextEditingController();
  final _dvtController = TextEditingController(text: 'Cái');
  final _soLuongController = TextEditingController(text: '1');
  final _donGiaController = TextEditingController();
  final _ghiChuController = TextEditingController();

  double _vatPercent = 8.0; // Mặc định 8%
  double _thanhTienLive = 0.0;

  final NumberFormat _currencyFormatter = NumberFormat('#,###', 'vi_VN');

  @override
  void initState() {
    super.initState();
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final bgCode = 'HP-BG-${DateFormat('yyMMdd').format(DateTime.now())}';

    _info = QuotationInfo(
      soBG: bgCode,
      ngayBG: today,
      kinhGui: 'Quý Khách Hàng',
    );

    _kinhGuiController = TextEditingController(text: _info.kinhGui);
    _sdtController = TextEditingController(text: _info.sdt);
    _mstController = TextEditingController(text: _info.maSoThue);
    _diaChiController = TextEditingController(text: _info.diaChi);
    _soBGController = TextEditingController(text: _info.soBG);
    _ngayBGController = TextEditingController(text: _info.ngayBG);

    // Lắng nghe thay đổi số lượng và đơn giá để tính thành tiền realtime
    _soLuongController.addListener(_updateThanhTien);
    _donGiaController.addListener(_updateThanhTien);
  }

  void _updateThanhTien() {
    final sl = double.tryParse(_soLuongController.text.replaceAll(',', '.')) ?? 0;
    final dg = double.tryParse(_donGiaController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    setState(() {
      _thanhTienLive = sl * dg;
    });
  }

  @override
  void dispose() {
    _kinhGuiController.dispose();
    _sdtController.dispose();
    _mstController.dispose();
    _diaChiController.dispose();
    _soBGController.dispose();
    _ngayBGController.dispose();

    _quyCachController.dispose();
    _nhanHieuController.dispose();
    _dvtController.dispose();
    _soLuongController.dispose();
    _donGiaController.dispose();
    _ghiChuController.dispose();
    super.dispose();
  }

  // Cập nhật thông tin khách hàng vào model
  void _syncCustomerInfo() {
    _info.kinhGui = _kinhGuiController.text.trim();
    _info.sdt = _sdtController.text.trim();
    _info.maSoThue = _mstController.text.trim();
    _info.diaChi = _diaChiController.text.trim();
    _info.soBG = _soBGController.text.trim();
    _info.ngayBG = _ngayBGController.text.trim();
  }

  // Thêm vật tư mới vào danh sách
  void _addNewItem() {
    if (_formKey.currentState?.validate() ?? false) {
      final quyCach = _quyCachController.text.trim();
      final nhanHieu = _nhanHieuController.text.trim();
      final dvt = _dvtController.text.trim().isEmpty ? 'Cái' : _dvtController.text.trim();
      final sl = double.tryParse(_soLuongController.text.replaceAll(',', '.')) ?? 1.0;
      final dg = double.tryParse(_donGiaController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      final ghiChu = _ghiChuController.text.trim();

      final newItem = QuotationItem(
        stt: _info.items.length + 1,
        quyCach: quyCach,
        nhanHieu: nhanHieu,
        dvt: dvt,
        soLuong: sl,
        donGia: dg,
        vat: _vatPercent,
        ghiChu: ghiChu,
      );

      setState(() {
        _info.items.add(newItem);

        // Reset form để nhập vật phẩm tiếp theo
        _quyCachController.clear();
        _nhanHieuController.clear();
        _donGiaController.clear();
        _ghiChuController.clear();
        _soLuongController.text = '1';
        _thanhTienLive = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm vật phẩm #${newItem.stt} vào bảng!'),
          duration: const Duration(milliseconds: 1200),
          backgroundColor: const Color(0xFF005C53),
        ),
      );
    }
  }

  // Xóa một vật tư khỏi danh sách
  void _deleteItem(int index) {
    setState(() {
      _info.items.removeAt(index);
      // Đánh số lại STT
      for (int i = 0; i < _info.items.length; i++) {
        _info.items[i] = _info.items[i].copyWith(stt: i + 1);
      }
    });
  }

  // Xuất và xem trước file PDF
  Future<void> _exportPdf() async {
    _syncCustomerInfo();

    if (_info.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thêm ít nhất 1 vật tư trước khi xuất file PDF!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await Printing.layoutPdf(
        name: 'BangBaoGia_${_info.soBG}.pdf',
        onLayout: (format) async => await PdfInvoiceService.generatePdf(_info),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xuất PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF005C53),
        elevation: 2,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HIẾU PHƯƠNG TECHNOLOGY',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Tạo Bảng Báo Giá',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          // NÚT DONE / CHỮ V XUẤT FILE PDF THEO YÊU CẦU
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: 'Xuất file PDF (Done)',
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 24),
              ),
              onPressed: _exportPdf,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. CARD THÔNG TIN KHÁCH HÀNG & BÁO GIÁ
                  _buildCustomerCard(),
                  const SizedBox(height: 12),

                  // 2. CARD NHẬP LIỆU VẬT TƯ (FORM NHẬP CHÍNH)
                  _buildItemInputCard(),
                  const SizedBox(height: 16),

                  // 3. DANH SÁCH CÁC VẬT PHẨM ĐÃ NHẬP
                  _buildItemListCard(),
                  const SizedBox(height: 80), // Chừa khoảng trống cho thanh tổng kết
                ],
              ),
            ),
          ),

          // 4. THANH TỔNG KẾT & NÚT XUẤT PDF CỐ ĐỊNH Ở DƯỚI
          _buildBottomSummaryBar(),
        ],
      ),
    );
  }

  // Widget 1: Card thông tin khách hàng
  Widget _buildCustomerCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.white,
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: const Icon(Icons.business_center, color: Color(0xFF005C53)),
        title: Text(
          'Thông tin khách hàng & Báo giá',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF005C53),
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          'Kính gửi: ${_kinhGuiController.text} | Số: ${_soBGController.text}',
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _soBGController,
                  label: 'Số Báo Giá',
                  prefixIcon: Icons.tag,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  controller: _ngayBGController,
                  label: 'Ngày Báo Giá',
                  prefixIcon: Icons.calendar_today,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _kinhGuiController,
            label: 'Kính gửi (Tên khách hàng)',
            prefixIcon: Icons.person,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _sdtController,
                  label: 'Số điện thoại',
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  controller: _mstController,
                  label: 'Mã số thuế',
                  prefixIcon: Icons.receipt,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _diaChiController,
            label: 'Địa chỉ nhận hàng',
            prefixIcon: Icons.location_on,
          ),
        ],
      ),
    );
  }

  // Widget 2: Form nhập vật phẩm mới
  Widget _buildItemInputCard() {
    final nextItemNumber = _info.items.length + 1;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF005C53),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Vật phẩm #$nextItemNumber',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Nhập thông tin vật tư',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 1. Quy cách vật tư
              TextFormField(
                controller: _quyCachController,
                decoration: const InputDecoration(
                  labelText: 'Quy cách vật tư *',
                  hintText: 'Ví dụ: Ống thép mạ kẽm D50, Máy in nhiệt...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.build_circle_outlined, color: Color(0xFF005C53)),
                  isDense: true,
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Vui lòng nhập quy cách vật tư' : null,
              ),
              const SizedBox(height: 10),

              // 2. Nhãn hiệu & ĐVT
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _nhanHieuController,
                      decoration: const InputDecoration(
                        labelText: 'Nhãn hiệu',
                        hintText: 'Hòa Phát, Sino...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.branding_watermark_outlined),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _dvtController,
                      decoration: const InputDecoration(
                        labelText: 'ĐVT',
                        hintText: 'Cái/Bộ/M',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 3. Số lượng & Đơn giá
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _soLuongController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'SL *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Nhập SL';
                        final n = double.tryParse(val);
                        if (n == null || n <= 0) return 'SL > 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      controller: _donGiaController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Đơn giá (VNĐ) *',
                        hintText: 'Ví dụ: 1500000',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                        isDense: true,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Nhập Đơn giá';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 4. VAT & Ghi chú
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<double>(
                      initialValue: _vatPercent,
                      decoration: const InputDecoration(
                        labelText: 'VAT',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 0.0, child: Text('0%')),
                        DropdownMenuItem(value: 8.0, child: Text('8%')),
                        DropdownMenuItem(value: 10.0, child: Text('10%')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _vatPercent = val;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      controller: _ghiChuController,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú',
                        hintText: 'Hàng có sẵn, bảo hành 12T...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Thành tiền hiển thị Realtime
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Thành tiền (tạm tính):',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${_currencyFormatter.format(_thanhTienLive)} đ',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF005C53),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // NÚT DẤU CỘNG ĐỂ NHẬP TIẾP VẬT PHẨM THEO YÊU CẦU
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005C53),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.add_circle, size: 22),
                  label: Text(
                    'Thêm vật tư (Bấm + để nhập tiếp vật phẩm thứ ${nextItemNumber + 1})',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _addNewItem,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget 3: Danh sách các vật phẩm đã thêm
  Widget _buildItemListCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Danh sách vật phẩm (${_info.items.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF005C53),
                  ),
                ),
                if (_info.items.isNotEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: EdgeInsets.zero,
                    ),
                    icon: const Icon(Icons.delete_sweep, size: 18),
                    label: const Text('Xóa hết', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      setState(() {
                        _info.items.clear();
                      });
                    },
                  ),
              ],
            ),
            const Divider(),
            if (_info.items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.post_add, size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 6),
                      Text(
                        'Chưa có vật phẩm nào được thêm.\nHãy nhập thông tin ở trên và bấm nút + để thêm!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _info.items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _info.items[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFF005C53),
                      child: Text(
                        '${item.stt}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      item.quyCach,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.nhanHieu.isNotEmpty ? '${item.nhanHieu} | ' : ''}${item.soLuong % 1 == 0 ? item.soLuong.toInt() : item.soLuong} ${item.dvt} x ${_currencyFormatter.format(item.donGia)} đ',
                          style: const TextStyle(fontSize: 11, color: Colors.black87),
                        ),
                        if (item.ghiChu.isNotEmpty)
                          Text(
                            'Ghi chú: ${item.ghiChu}',
                            style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: Colors.grey.shade700),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_currencyFormatter.format(item.thanhTien)} đ',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF005C53),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () => _deleteItem(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // Widget 4: Thanh tổng kết và nút xuất PDF ở đáy màn hình
  Widget _buildBottomSummaryBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng trước thuế:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                Text(
                  '${_currencyFormatter.format(_info.tongTruocThue)} đ',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Thuế VAT:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                Text(
                  '${_currencyFormatter.format(_info.tongTienVat)} đ',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const Divider(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TỔNG SAU THUẾ:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF005C53)),
                ),
                Text(
                  '${_currencyFormatter.format(_info.tongSauThue)} đ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF005C53),
                  ),
                ),
              ],
            ),
            if (_info.items.isNotEmpty && _info.tongSauThue > 0) ...[
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Bằng chữ: ${VietnameseNumberToWords.convert(_info.tongSauThue)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: Colors.black87),
                ),
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005C53),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.picture_as_pdf, size: 20),
                label: const Text(
                  'XUẤT FILE BÁO GIÁ PDF (✓)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: _exportPdf,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? prefixIcon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18) : null,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }
}
