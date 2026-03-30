import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/chatbot_controller.dart';
import 'chat_widgets.dart';

class ChatbotScreen extends StatefulWidget {
  final bool isEmbedded;
  const ChatbotScreen({super.key, this.isEmbedded = false});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final ChatbotController _ctrl = Get.put(ChatbotController());
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    _ctrl.handleUserInput(text);
  }

  bool get _isInputEnabled {
    final step = _ctrl.currentStep.value;
    return step == ChatStep.selectArea ||
        (step == ChatStep.confirmPhone && _ctrl.contactPhone.value.isEmpty);
  }

  String get _inputHint {
    switch (_ctrl.currentStep.value) {
      case ChatStep.selectArea:
        return 'Nhập khu vực (VD: Thủ Đức, Gò Vấp...)';
      case ChatStep.confirmPhone:
        return 'Nhập số điện thoại (0909...)';
      default:
        return 'Nhập tin nhắn...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E56D9), Color(0xFF42A5F5)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E56D9).withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                if (!widget.isEmbedded)
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  ),
                if (widget.isEmbedded) const SizedBox(width: 12),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(child: Text('🏸', style: TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trợ lý đặt sân',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Online',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Restart button
                IconButton(
                  onPressed: () {
                    Get.dialog(
                      AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Text('Bắt đầu lại?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        content: Text(
                          'Tất cả thông tin hội thoại hiện tại sẽ bị xoá.',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: Text('Huỷ', style: GoogleFonts.poppins(color: Colors.grey)),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Get.back();
                              _ctrl.resetConversation();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E56D9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text('Bắt đầu lại', style: GoogleFonts.poppins(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return Obx(() {
      final msgs = _ctrl.messages.toList();
      _scrollToBottom();

      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: msgs.length + (_ctrl.isTyping.value ? 1 : 0),
        itemBuilder: (context, index) {
          // Typing indicator at the end
          if (index == msgs.length && _ctrl.isTyping.value) {
            return const TypingIndicator();
          }

          final msg = msgs[index];
          return _buildMessageWidget(msg);
        },
      );
    });
  }

  Widget _buildMessageWidget(ChatMessage msg) {
    switch (msg.type) {
      case MessageType.bot:
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 10 * (1 - value)),
              child: child,
            ),
          ),
          child: BotMessageBubble(text: msg.text ?? ''),
        );

      case MessageType.user:
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 8 * (1 - value)),
              child: child,
            ),
          ),
          child: UserMessageBubble(text: msg.text ?? ''),
        );

      case MessageType.courtList:
        return CourtListMessage(
          courts: msg.data as List<dynamic>,
          onSelect: (court) {
            // Bắt login khi chọn sân trong chatbot
            if (!AuthController.requireLogin(context, message: 'Đăng nhập để đặt sân qua trợ lý')) {
              return;
            }
            _ctrl.selectCourt(court);
          },
        );

      case MessageType.timeSlotGrid:
        final data = msg.data as Map<String, dynamic>;
        return TimeSlotGridMessage(
          slots: data['slots'] as List<dynamic>,
          subCourts: data['subCourts'] as List<dynamic>,
          onConfirm: (selected, subCourt) => _ctrl.confirmSelectedSlots(selected, subCourt),
        );

      case MessageType.bookingSummary:
        return BookingSummaryCard(summary: msg.data as Map<String, dynamic>);

      case MessageType.quickReply:
        return QuickReplyButtons(
          actions: msg.data as List<dynamic>,
          onTap: (action) => _ctrl.handleAction(action),
        );

      case MessageType.typing:
        return const TypingIndicator();
    }
  }

  Widget _buildInputBar() {
    return Obx(() {
      final enabled = _isInputEnabled;
      final step = _ctrl.currentStep.value;

      // Show date picker when step is selectDate
      if (step == ChatStep.selectDate) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: DatePickerCard(
              onDateSelected: (date) => _ctrl.selectDate(date),
            ),
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: enabled ? const Color(0xFFF4F6FB) : const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      enabled: enabled,
                      onSubmitted: (_) => _onSend(),
                      textInputAction: TextInputAction.send,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: _inputHint,
                        hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: enabled ? _onSend : null,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: enabled
                          ? const LinearGradient(colors: [Color(0xFF1E56D9), Color(0xFF42A5F5)])
                          : null,
                      color: enabled ? null : Colors.grey[300],
                      shape: BoxShape.circle,
                      boxShadow: enabled
                          ? [
                              BoxShadow(
                                color: const Color(0xFF1E56D9).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      color: enabled ? Colors.white : Colors.grey[500],
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
