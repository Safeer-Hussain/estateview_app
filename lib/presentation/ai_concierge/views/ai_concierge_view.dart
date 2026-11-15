import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/ai_message_model.dart';
import '../bloc/ai_concierge_cubit.dart';

class AiConciergeView extends StatefulWidget {
  const AiConciergeView({super.key});

  @override
  State<AiConciergeView> createState() => _AiConciergeViewState();
}

class _AiConciergeViewState extends State<AiConciergeView> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
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

  void _submitMessage(String text) {
    if (text.trim().isEmpty) return;
    _inputController.clear();
    context.read<AiConciergeCubit>().sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return BlocConsumer<AiConciergeCubit, AiConciergeState>(
      listener: (context, state) {
        _scrollToBottom();
      },
      builder: (context, state) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          floatingActionButton: state.messages.length > 2
              ? FloatingActionButton.small(
                  heroTag: AppConstants.fabAiConciergeClear,
                  backgroundColor: colors.surfaceContainer,
                  foregroundColor: colors.onSurfaceVariant,
                  tooltip: 'Clear Chat History',
                  onPressed: () {
                    context.read<AiConciergeCubit>().clearChat();
                  },
                  child: const Icon(Icons.delete_sweep_outlined, size: 18),
                )
              : null,
          body: Column(
            children: [
              // Prompt Shortcuts Chips Row
              Container(
                color: colors.surface,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: state.promptShortcuts.map((shortcut) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          avatar: Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: colors.secondary,
                          ),
                          label: Text(shortcut),
                          backgroundColor: colors.surfaceContainer,
                          side: BorderSide(color: colors.outlineVariant),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                          onPressed: state.isStreaming
                              ? null
                              : () => _submitMessage(shortcut),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const Divider(height: 1),

              // Chat Messages Stream List
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final msg = state.messages[index];
                    return _buildMessageBubble(context, colors, msg);
                  },
                ),
              ),

              // Transient Streaming Status Indicator
              if (state.isStreaming && state.statusIndicator.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  color: colors.primaryContainer.withOpacity(0.35),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.statusIndicator,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Bottom Input Bar (docked flush against keyboard with SafeArea(top: false))
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer,
                    border: Border(
                      top: BorderSide(color: colors.outlineVariant),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (val) => _submitMessage(val),
                          enabled: !state.isStreaming,
                          decoration: InputDecoration(
                            hintText:
                                'Ask regarding cap rates, ROI, tours, scans...',
                            hintStyle: TextStyle(
                              color: colors.onSurfaceVariant.withOpacity(0.7),
                              fontSize: 13,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: colors.outlineVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: state.isStreaming
                            ? null
                            : () => _submitMessage(_inputController.text),
                        style: IconButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                        ),
                        icon: const Icon(Icons.arrow_upward, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    ColorScheme colors,
    AiMessageModel msg,
  ) {
    final isUser = msg.sender == 'user';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: colors.primaryContainer,
              child: Icon(
                Icons.auto_awesome,
                size: 16,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? colors.primary : colors.surfaceContainer,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser ? Colors.transparent : colors.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.content,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: isUser ? colors.onPrimary : colors.onSurface,
                    ),
                  ),
                  if (msg.isStreaming) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isUser ? colors.onPrimary : colors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
