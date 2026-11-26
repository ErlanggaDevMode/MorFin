import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../core/theme/morfin_theme.dart';
import '../models/morfin_models.dart';
import '../state/morfin_controller.dart';
import 'add_sheets.dart';
import 'morfin_status_notify.dart';

class _ChatBubbleItem {
  final String id;
  final bool isUser;
  final String text;
  final Uint8List? imageBytes;
  final List<MorfinChatDraft> drafts;
  final Set<int> savedDraftIndices;
  final DateTime timestamp;

  _ChatBubbleItem({
    required this.id,
    required this.isUser,
    required this.text,
    this.imageBytes,
    this.drafts = const [],
    Set<int>? savedDraftIndices,
    DateTime? timestamp,
  })  : savedDraftIndices = savedDraftIndices ?? <int>{},
        timestamp = timestamp ?? DateTime.now();
}

/// Interactive MorFin Chat Bot section for logging transactions via:
/// - Natural Indonesian chat text
/// - Live Voice Recording (Speech-to-Text id_ID)
/// - Photo Scanner for shopping receipts / nota belanja (OCR)
class TxChatbotView extends StatefulWidget {
  final MorfinController controller;
  const TxChatbotView({super.key, required this.controller});

  @override
  State<TxChatbotView> createState() => _TxChatbotViewState();
}

class _TxChatbotViewState extends State<TxChatbotView> with SingleTickerProviderStateMixin {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final SpeechToText _speech = SpeechToText();

  late final AnimationController _pulseCtrl;
  final List<_ChatBubbleItem> _messages = [];

  bool _sending = false;
  bool _scanning = false;
  bool _isListening = false;
  bool _speechReady = false;
  String _liveTranscript = '';

  static const _quickPrompts = [
    'Beli kopi 28rb qris',
    'Makan siang 35rb cash',
    'Gaji masuk 5jt transfer',
    'Cek saldo saya',
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _messages.add(
      _ChatBubbleItem(
        id: 'welcome',
        isUser: false,
        text:
            'Halo! Aku asisten pencatat MorFin. Kamu bisa langsung:\n'
            '• Ketik transaksi biasa (contoh: "Beli kopi 28rb qris")\n'
            '• Tekan ikon Mic untuk rekam suara\n'
            '• Tekan ikon Kamera untuk scan foto struk / nota belanja',
      ),
    );
  }

  @override
  void dispose() {
    if (_isListening) {
      _speech.stop();
    }
    _pulseCtrl.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _sendText([String? overrideText]) async {
    final text = (overrideText ?? _inputCtrl.text).trim();
    if (text.isEmpty || _sending || _scanning) return;

    if (overrideText == null) {
      _inputCtrl.clear();
    }
    setState(() {
      _sending = true;
      _messages.add(
        _ChatBubbleItem(
          id: 'u_${DateTime.now().microsecondsSinceEpoch}',
          isUser: true,
          text: text,
        ),
      );
    });
    _scrollToBottom();

    try {
      final result = await widget.controller.api.parseChatText(text);
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatBubbleItem(
            id: 'b_${DateTime.now().microsecondsSinceEpoch}',
            isUser: false,
            text: result.reply,
            drafts: result.items,
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      final clean = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      setState(() {
        _messages.add(
          _ChatBubbleItem(
            id: 'err_${DateTime.now().microsecondsSinceEpoch}',
            isUser: false,
            text: 'Maaf, gagal memproses pesan: $clean',
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _toggleVoiceRecording() async {
    if (_isListening) {
      await _speech.stop();
      _pulseCtrl.stop();
      final captured = _liveTranscript.trim();
      setState(() {
        _isListening = false;
        _liveTranscript = '';
      });
      if (captured.isNotEmpty) {
        _inputCtrl.text = captured;
        await _sendText(captured);
      }
      return;
    }

    try {
      if (!_speechReady) {
        _speechReady = await _speech.initialize(
          onError: (err) {
            if (!mounted) return;
            _pulseCtrl.stop();
            setState(() => _isListening = false);
            showMorfinToast(context, 'Suara tidak terdeteksi (${err.errorMsg})', isError: true);
          },
          onStatus: (status) {
            if (!mounted) return;
            if ((status == 'done' || status == 'notListening') && _isListening) {
              _pulseCtrl.stop();
              final captured = _liveTranscript.trim();
              setState(() {
                _isListening = false;
                _liveTranscript = '';
              });
              if (captured.isNotEmpty) {
                _inputCtrl.text = captured;
                _sendText(captured);
              }
            }
          },
        );
      }

      if (!_speechReady) {
        if (mounted) {
          showMorfinToast(
            context,
            'Izin mikrofon atau Speech Recognition tidak tersedia di perangkat ini.',
            isError: true,
          );
        }
        return;
      }

      setState(() {
        _isListening = true;
        _liveTranscript = '';
      });
      _pulseCtrl.repeat(reverse: true);

      await _speech.listen(
        localeId: 'id_ID',
        listenFor: const Duration(seconds: 25),
        pauseFor: const Duration(seconds: 3),
        onResult: (res) {
          if (!mounted) return;
          setState(() {
            _liveTranscript = res.recognizedWords;
            _inputCtrl.text = res.recognizedWords;
          });
          if (res.finalResult && res.recognizedWords.trim().isNotEmpty) {
            final finalText = res.recognizedWords.trim();
            _speech.stop();
            _pulseCtrl.stop();
            setState(() {
              _isListening = false;
              _liveTranscript = '';
            });
            _inputCtrl.clear();
            _sendText(finalText);
          }
        },
      );
    } catch (e) {
      _pulseCtrl.stop();
      if (mounted) {
        setState(() => _isListening = false);
        showMorfinToast(context, 'Gagal memulai rekaman suara: $e', isError: true);
      }
    }
  }

  Future<void> _openReceiptScanner() async {
    if (_scanning || _sending) return;

    ImageSource? source;
    if (kIsWeb) {
      source = ImageSource.gallery;
    } else {
      source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: MorfinColors.pistachio,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: MorfinColors.ink.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Scan Struk / Nota Belanja', style: MorfinTheme.display(17)),
                const SizedBox(height: 4),
                Text(
                  'Pilih foto struk agar nominal, toko, dan kategori terbaca otomatis.',
                  style: MorfinTheme.body(12, color: MorfinColors.muted),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MorfinColors.carbon,
                    foregroundColor: MorfinColors.lime,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(ctx, ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_rounded),
                  label: Text('Foto Langsung (Kamera)', style: MorfinTheme.display(14, color: MorfinColors.lime)),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MorfinColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_rounded),
                  label: Text('Pilih dari Galeri', style: MorfinTheme.display(14)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (source == null) return;

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 2400,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      setState(() {
        _scanning = true;
        _messages.add(
          _ChatBubbleItem(
            id: 'img_${DateTime.now().microsecondsSinceEpoch}',
            isUser: true,
            text: 'Memindai struk belanja...',
            imageBytes: bytes,
          ),
        );
      });
      _scrollToBottom();

      final b64 = base64Encode(bytes);
      final result = await widget.controller.api.scanReceiptImage(
        imageBase64: b64,
        fileName: file.name,
      );

      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatBubbleItem(
            id: 'ocr_${DateTime.now().microsecondsSinceEpoch}',
            isUser: false,
            text: result.reply,
            drafts: result.items,
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      final clean = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      setState(() {
        _messages.add(
          _ChatBubbleItem(
            id: 'ocrerr_${DateTime.now().microsecondsSinceEpoch}',
            isUser: false,
            text: 'Gagal memindai struk: $clean',
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _scanning = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _saveDraft(_ChatBubbleItem bubble, int draftIdx, MorfinChatDraft draft) async {
    if (bubble.savedDraftIndices.contains(draftIdx)) return;
    try {
      await widget.controller.addTransaction(
        title: draft.title,
        category: draft.category,
        type: draft.type,
        amount: draft.amount,
        paymentMethod: draft.paymentMethod,
        occurredAt: draft.occurredAt,
      );
      if (!mounted) return;
      setState(() {
        bubble.savedDraftIndices.add(draftIdx);
      });
      showMorfinStatusNotify(
        context,
        isSuccess: true,
        title: 'Tersimpan!',
        message:
            '${draft.isIncome ? "Pemasukan" : "Pengeluaran"} "${draft.title}" (${formatIdr(draft.amount)}) berhasil dicatat.',
      );
    } catch (e) {
      if (!mounted) return;
      showMorfinStatusNotify(
        context,
        isSuccess: false,
        title: 'Gagal Menyimpan!',
        message: e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
      );
    }
  }

  Future<void> _editDraft(_ChatBubbleItem bubble, int draftIdx, MorfinChatDraft draft) async {
    final saved = await showAddTransactionSheet(
      context,
      widget.controller,
      prefill: draft,
    );
    if (saved == true && mounted) {
      setState(() {
        bubble.savedDraftIndices.add(draftIdx);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Quick suggestion chips
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _quickPrompts.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _sendText(_quickPrompts[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: MorfinColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: MorfinColors.ink.withValues(alpha: 0.08)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 13, color: MorfinColors.limeDeep),
                    const SizedBox(width: 5),
                    Text(_quickPrompts[i], style: MorfinTheme.body(11.5, weight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Chat Messages Stream
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.only(bottom: 12, top: 4),
            itemCount: _messages.length + ((_sending || _scanning) ? 1 : 0),
            itemBuilder: (context, idx) {
              if (idx == _messages.length) {
                return _buildTypingBubble(_scanning ? 'Memindai teks struk...' : 'Menganalisis catatan...');
              }
              return _buildBubble(_messages[idx]);
            },
          ),
        ),

        // Live Voice Recording Indicator Strip
        if (_isListening)
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, _) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: MorfinColors.coral.withValues(alpha: 0.12 + _pulseCtrl.value * 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: MorfinColors.coral.withValues(alpha: 0.45)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: MorfinColors.coral,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _liveTranscript.isEmpty
                          ? 'Mendengarkan... sebutkan transaksi (misal: beli kopi 25 ribu)'
                          : '"$_liveTranscript"',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: MorfinTheme.body(12, color: MorfinColors.coral, weight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _toggleVoiceRecording,
                    child: Text(
                      'Selesai',
                      style: MorfinTheme.display(12, color: MorfinColors.coral),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Floating Chat Input Bar with Photo Receipt Scanner + Voice Recorder + Send
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: MorfinColors.surfaceWhite,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: MorfinColors.ink.withValues(alpha: 0.07),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Photo Receipt / Nota Scanner Button
                Tooltip(
                  message: 'Scan Struk / Nota Belanja',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(99),
                    onTap: _openReceiptScanner,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: MorfinColors.surfaceAlt,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.document_scanner_rounded, size: 19, color: MorfinColors.ink),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Text Input
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendText(),
                    style: MorfinTheme.body(13),
                    decoration: InputDecoration(
                      hintText: 'Ketik: kopi 25rb qris...',
                      hintStyle: MorfinTheme.body(12.5, color: MorfinColors.mutedLight),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                    ),
                  ),
                ),

                // Voice Recording Mic Button
                Tooltip(
                  message: _isListening ? 'Hentikan Rekaman' : 'Rekam Suara Transaksi',
                  child: GestureDetector(
                    onTap: _toggleVoiceRecording,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _isListening ? MorfinColors.coral : MorfinColors.surfaceAlt,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                        size: 20,
                        color: _isListening ? Colors.white : MorfinColors.ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Send Button
                InkWell(
                  borderRadius: BorderRadius.circular(99),
                  onTap: () => _sendText(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: MorfinColors.carbon,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_upward_rounded, size: 20, color: MorfinColors.lime),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypingBubble(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, right: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: MorfinColors.surfaceWhite,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: MorfinColors.carbon),
            ),
            const SizedBox(width: 10),
            Text(label, style: MorfinTheme.body(12, color: MorfinColors.muted, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(_ChatBubbleItem item) {
    final isUser = item.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          margin: EdgeInsets.only(
            bottom: 10,
            left: isUser ? 42 : 0,
            right: isUser ? 0 : 28,
          ),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: isUser ? MorfinColors.carbon : MorfinColors.surfaceWhite,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 6),
              bottomRight: Radius.circular(isUser ? 6 : 18),
            ),
            boxShadow: [
              if (!isUser)
                BoxShadow(
                  color: MorfinColors.ink.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: MorfinColors.lime,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.auto_awesome_rounded, size: 11, color: MorfinColors.onLime),
                      ),
                      const SizedBox(width: 6),
                      Text('MorFin AI', style: MorfinTheme.display(11.5, color: MorfinColors.ink)),
                    ],
                  ),
                ),

              if (item.imageBytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    item.imageBytes!,
                    height: 150,
                    width: 210,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              Text(
                item.text,
                style: MorfinTheme.body(
                  12.5,
                  color: isUser ? Colors.white : MorfinColors.ink,
                  weight: FontWeight.w500,
                ).copyWith(height: 1.42),
              ),

              if (item.drafts.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...List.generate(item.drafts.length, (i) {
                  final d = item.drafts[i];
                  final isSaved = item.savedDraftIndices.contains(i);
                  return Container(
                    margin: EdgeInsets.only(top: i == 0 ? 0 : 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: MorfinColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSaved
                            ? MorfinColors.limeDeep.withValues(alpha: 0.4)
                            : MorfinColors.ink.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                d.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: MorfinTheme.display(13.5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${d.isIncome ? "+" : "-"}${formatIdr(d.amount)}',
                              style: MorfinTheme.display(
                                13.5,
                                color: d.isIncome ? MorfinColors.limeDeep : MorfinColors.coral,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${d.category} · ${d.paymentMethod} · ${DateFormat("dd MMM yyyy").format(d.occurredAt)}',
                          style: MorfinTheme.body(10.5, color: MorfinColors.muted, weight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        if (isSaved)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: MorfinColors.lime.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 15, color: MorfinColors.limeDeep),
                                const SizedBox(width: 5),
                                Text('Sudah tersimpan', style: MorfinTheme.body(11.5, color: MorfinColors.ink, weight: FontWeight.w800)),
                              ],
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: MorfinColors.carbon,
                                    foregroundColor: MorfinColors.lime,
                                    padding: const EdgeInsets.symmetric(vertical: 9),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                                  ),
                                  onPressed: () => _saveDraft(item, i, d),
                                  icon: const Icon(Icons.check_rounded, size: 16),
                                  label: Text('Simpan', style: MorfinTheme.display(12, color: MorfinColors.lime)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: MorfinColors.ink,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                                ),
                                onPressed: () => _editDraft(item, i, d),
                                child: Text('Edit', style: MorfinTheme.body(12, weight: FontWeight.w700)),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
