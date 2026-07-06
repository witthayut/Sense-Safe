import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../services/assistant_controller.dart';

/// Wraps any screen with a floating AI assistant button (bottom-right).
/// Pressing it opens a compact chat popup. Pressing again closes it.
///
/// Usage: wrap your Scaffold body with this widget, or place it in
/// HomeShell so it appears on every tab automatically.
///
/// Example in HomeShell:
/// ```dart
/// body: Stack(
///   children: [
///     IndexedStack(index: _index, children: _tabs),
///     const AiAssistantOverlay(),
///   ],
/// ),
/// ```
class AiAssistantOverlay extends ConsumerWidget {
  const AiAssistantOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assistantControllerProvider);
    final notifier = ref.read(assistantControllerProvider.notifier);

    return Stack(
      children: [
        // ── Chat popup ──────────────────────────────────────────────
        if (state.isOpen)
          Positioned(
            bottom: 90,
            right: 16,
            child: _ChatPopup(
              state: state,
              onClose: notifier.close,
              onSend: notifier.send,
              onClear: notifier.clearHistory,
            ),
          ),

        // ── Floating button ────────────────────────────────────────
        Positioned(
          bottom: 24,
          right: 16,
          child: _FloatingAiButton(
            isOpen: state.isOpen,
            onTap: notifier.toggleOpen,
          ),
        ),
      ],
    );
  }
}

// ─── Floating button ──────────────────────────────────────────────────────────

class _FloatingAiButton extends StatelessWidget {
  const _FloatingAiButton({required this.isOpen, required this.onTap});

  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isOpen ? AppColors.sageDark : AppColors.sage,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.sageDark.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isOpen ? Icons.close : Icons.auto_awesome,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

// ─── Chat popup ───────────────────────────────────────────────────────────────

class _ChatPopup extends StatefulWidget {
  const _ChatPopup({
    required this.state,
    required this.onClose,
    required this.onSend,
    required this.onClear,
  });

  final AssistantState state;
  final VoidCallback onClose;
  final Future<void> Function(String) onSend;
  final VoidCallback onClear;

  @override
  State<_ChatPopup> createState() => _ChatPopupState();
}

class _ChatPopupState extends State<_ChatPopup> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(_ChatPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll to bottom whenever a new message arrives.
    if (widget.state.messages.length != oldWidget.state.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(20),
      color: Colors.white,
      child: SizedBox(
        width: 300,
        height: 380,
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.sageDark,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Sense&Safe Assistant',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onClear,
                    child: const Icon(Icons.refresh,
                        color: Colors.white70, size: 18),
                  ),
                ],
              ),
            ),

            // ── Messages ────────────────────────────────────────────
            Expanded(
              child: widget.state.messages.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: widget.state.messages.length +
                          (widget.state.isLoading ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i == widget.state.messages.length) {
                          return const _TypingIndicator();
                        }
                        return _MessageBubble(
                            message: widget.state.messages[i]);
                      },
                    ),
            ),

            // ── Input ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(
                  top: BorderSide(color: AppColors.line),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _submit(),
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Ask about the app or LD...',
                        hintStyle: const TextStyle(
                            color: AppColors.inkSoft, fontSize: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _submit,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.sageDark,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 220),
        decoration: BoxDecoration(
          color: isUser ? AppColors.sageDark : AppColors.sageSoft,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 14),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 13,
            color: isUser ? Colors.white : AppColors.ink,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

// ─── Typing indicator ─────────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.sageSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(delay: 0),
            _Dot(delay: 150),
            _Dot(delay: 300),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.delay});
  final int delay;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 6,
        height: 6 + _anim.value * 4,
        decoration: BoxDecoration(
          color: AppColors.sageDark.withValues(alpha: 0.6 + _anim.value * 0.4),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome,
                color: AppColors.sage, size: 32),
            SizedBox(height: 10),
            Text(
              'Ask me anything about\nSense&Safe or Learning Disabilities',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.inkSoft,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}