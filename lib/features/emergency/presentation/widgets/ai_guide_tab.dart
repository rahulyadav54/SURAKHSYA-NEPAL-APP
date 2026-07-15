import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ai_assistant/presentation/controllers/ai_chat_controller.dart';
import '../../../ai_assistant/domain/entities/chat_message.dart';

class AiGuideTab extends ConsumerStatefulWidget {
  const AiGuideTab({super.key});

  @override
  ConsumerState<AiGuideTab> createState() => _AiGuideTabState();
}

class _AiGuideTabState extends ConsumerState<AiGuideTab> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  final List<String> _quickPrompts = [
    'भूकम्पको बेला के गर्ने? (Earthquake Guide)',
    'सर्पले टोक्दा के गर्ने? (Snake Bite First Aid)',
    'घाउबाट रगत बग्दा के गर्ने? (Stop Bleeding)',
    'आगलागीमा कसरी बच्ने? (Fire Safety)',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _submitQuery(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();
    await ref.read(aiChatControllerProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _showVoiceAssistant() {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const VoiceAssistantModal();
      },
    ).then((spokenQuery) {
      if (spokenQuery != null && spokenQuery is String && spokenQuery.isNotEmpty) {
        _submitQuery(spokenQuery);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatState = ref.watch(aiChatControllerProvider);

    ref.listen(aiChatControllerProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI RESCUE ASSISTANT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () {
              ref.read(aiChatControllerProvider.notifier).clearChat();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (chatState.messages.length <= 1) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Text(
                  'Suggested Emergency Queries:',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.outline),
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  itemCount: _quickPrompts.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(_quickPrompts[index]),
                        backgroundColor: theme.colorScheme.surfaceContainerLow,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onPressed: () => _submitQuery(_quickPrompts[index]),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Message Bubble list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20.0),
                itemCount: chatState.messages.length,
                itemBuilder: (context, index) {
                  final message = chatState.messages[index];
                  return _buildMessageBubble(context, message);
                },
              ),
            ),

            if (chatState.isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'AI typing guidance...',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),

            // Input Row
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mic_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.tertiaryContainer,
                      foregroundColor: theme.colorScheme.onTertiaryContainer,
                      padding: const EdgeInsets.all(12),
                    ),
                    onPressed: _showVoiceAssistant,
                  ),
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Ask AI emergency guidelines...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: _submitQuery,
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  IconButton(
                    icon: const Icon(Icons.send_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                    onPressed: () => _submitQuery(_textController.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser 
              ? theme.colorScheme.primaryContainer 
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          border: isUser 
              ? null 
              : Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
                color: isUser 
                    ? theme.colorScheme.onPrimaryContainer 
                    : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                _formatTime(message.timestamp),
                style: const TextStyle(fontSize: 8, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }
}

class VoiceAssistantModal extends StatefulWidget {
  const VoiceAssistantModal({super.key});

  @override
  State<VoiceAssistantModal> createState() => _VoiceAssistantModalState();
}

class _VoiceAssistantModalState extends State<VoiceAssistantModal> {
  String _listeningStatusNp = 'सुन्दैछु...';
  String _listeningStatusEn = 'Listening...';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startVoiceSimulation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startVoiceSimulation() {
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _listeningStatusNp = 'भूकम्पको बेला के गर्ने?';
          _listeningStatusEn = 'Transcribing query...';
        });
        
        Timer(const Duration(milliseconds: 1000), () {
          if (mounted) {
            Navigator.pop(context, 'भूकम्पको बेला के गर्ने? (Earthquake safety)');
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Voice Rescue Assistant',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.tertiaryContainer,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.4, 1.4), duration: 1000.ms),
              
              CircleAvatar(
                radius: 30,
                backgroundColor: theme.colorScheme.tertiary,
                child: const Icon(Icons.mic_rounded, color: Colors.white, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 28),

          Text(
            _listeningStatusNp,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.tertiary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _listeningStatusEn,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
