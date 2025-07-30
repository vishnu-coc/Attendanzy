import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting timestamps
import 'dart:async'; // For periodic animations
import 'package:math_expressions/math_expressions.dart'; // For math expression parsing

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = []; // Includes timestamp
  bool _isTyping = false; // Indicates if the bot is typing
  int _typingDotCount = 0; // For WhatsApp-like typing animation
  Timer? _typingTimer; // Timer for animating dots
  final String _botName = "Alice"; // Bot name

  @override
  void initState() {
    super.initState();

    // Add a welcome message from the AI bot when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _messages.add({
          'sender': 'bot',
          'message':
              'Hello! I am $_botName, your AI assistant. How can I help you today?',
          'timestamp': DateTime.now(),
        });
      });
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final String userMessage = _controller.text.trim();
    if (userMessage.isNotEmpty) {
      setState(() {
        _messages.add({
          'sender': 'user',
          'message': userMessage,
          'timestamp': DateTime.now(),
        });
        _isTyping = true; // Show typing indicator
        _startTypingAnimation(); // Start typing animation
      });

      await Future.delayed(const Duration(seconds: 1)); // Simulate typing delay

      final botResponse = _getBotResponse(userMessage.toLowerCase());
      setState(() {
        _messages.add({
          'sender': 'bot',
          'message': botResponse,
          'timestamp': DateTime.now(),
        });
        _isTyping = false; // Hide typing indicator
        _typingTimer?.cancel(); // Stop typing animation
      });

      _controller.clear();
    }
  }

  void _startTypingAnimation() {
    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _typingDotCount = (_typingDotCount + 1) % 4; // Cycle through 0, 1, 2, 3
      });
    });
  }

  String _getBotResponse(String userMessage) {
    final normalizedMessage = userMessage.replaceAll(RegExp(r'[?.]$'), '');

    // Handle basic math expressions like "5+3"
    try {
      final Parser parser = Parser();
      final Expression exp = parser.parse(normalizedMessage);
      final ContextModel cm = ContextModel();
      final double result = exp.evaluate(EvaluationType.REAL, cm);
      return "The result is $result.";
    } catch (e) {
      // If parsing fails, continue with other responses
    }

    // Default responses
    if (normalizedMessage.contains("hi") ||
        normalizedMessage.contains("hello")) {
      return "Hi there! How can I assist you today?";
    } else if (normalizedMessage.contains("bye") ||
        normalizedMessage.contains("goodbye")) {
      return "Goodbye! Have a great day!";
    } else {
      return "I'm sorry, I didn't understand that. Could you please rephrase?";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat with $_botName"),
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous page
          },
        ),
      ),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                reverse: true,
                itemBuilder: (context, index) {
                  if (_isTyping && index == 0) {
                    // Typing indicator
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(3, (dotIndex) {
                            return AnimatedOpacity(
                              opacity: _typingDotCount > dotIndex ? 1.0 : 0.3,
                              duration: const Duration(milliseconds: 300),
                              child: const Text(
                                '.',
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.black87,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    );
                  }

                  final message =
                      _messages[_messages.length -
                          1 -
                          (_isTyping ? index - 1 : index)];
                  final isUser = message['sender'] == 'user';
                  final timestamp = DateFormat(
                    'hh:mm a',
                  ).format(message['timestamp']);
                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.blueAccent : Colors.blue[100],
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft:
                              isUser ? const Radius.circular(12) : Radius.zero,
                          bottomRight:
                              isUser ? Radius.zero : const Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isUser)
                            Text(
                              _botName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          Text(
                            message['message']!,
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            timestamp,
                            style: TextStyle(
                              color: isUser ? Colors.white70 : Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                // Text input field
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[300],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Send button
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: Colors.blueAccent,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
