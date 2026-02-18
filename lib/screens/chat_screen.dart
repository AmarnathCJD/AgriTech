import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/chat_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'home_screen.dart';
import 'market_intelligence_screen.dart';
import 'crop_planning_screen.dart';
import 'harvest/harvest_timing_screen.dart';
import 'feature_screens.dart';
import 'additional_features_screen.dart';
import 'profile_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSubmitted(String text) async {
    _controller.clear();
    final provider = Provider.of<ChatProvider>(context, listen: false);
    await provider.sendMessage(text);
    _scrollToBottom();
  }

  void _handleNavigation(String targetPage) {
    Widget? screen;

    switch (targetPage) {
      case 'MARKET_INTELLIGENCE':
        screen = const MarketIntelligenceScreen();
        break;
      case 'CROP_PLANNING':
        screen = const CropPlanningScreen();
        break;
      case 'HARVEST_TIMING':
        screen = const HarvestTimingScreen();
        break;
      case 'INSURANCE':
        screen = const RiskCalculatorScreen();
        break;
      case 'EQUIPMENT_RENTAL':
        screen = const EquipmentScreen();
        break;
      case 'STORAGE':
      case 'GOVT_SCHEMES':
        screen = const AdditionalFeaturesScreen();
        break;
      case 'WEATHER':
        screen = const HomeScreen();
        break;
      case 'PROFILE':
        screen = const ProfileScreen();
        break;
      case 'HELP':
      default:
        break;
    }

    if (screen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen!),
      );
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: Text("Farmora Assistant",
            style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history), // History / New Chat
            tooltip: 'History',
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        child: Consumer<ChatProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                  ),
                  child: Center(
                    child: Text(
                      'Chat History',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.add, color: Colors.green),
                  title: Text('New Chat',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
                  onTap: () {
                    provider.startNewChat();
                    Navigator.pop(context); // Close drawer
                  },
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.sessions.length,
                    itemBuilder: (context, index) {
                      final session = provider.sessions[index];
                      final isCurrent = session.id == provider.currentSessionId;
                      // Get first message as preview
                      String preview = "New Conversation";
                      if (session.messages.isNotEmpty) {
                        preview = session.messages.first.text;
                        if (preview.length > 30) {
                          preview = "${preview.substring(0, 30)}...";
                        }
                      }

                      return Container(
                        color: isCurrent ? Colors.green.withOpacity(0.1) : null,
                        child: ListTile(
                          title: Text(
                            preview,
                            style: GoogleFonts.dmSans(
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal),
                          ),
                          subtitle: Text(
                            _formatDate(session.lastActive),
                            style: GoogleFonts.dmSans(fontSize: 12),
                          ),
                          onTap: () {
                            provider.switchSession(session.id);
                            Navigator.pop(context);
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 20, color: Colors.grey),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text("Delete Chat?",
                                      style: GoogleFonts.dmSans(
                                          fontWeight: FontWeight.bold)),
                                  content: Text(
                                      "Are you sure you want to delete this conversation?",
                                      style: GoogleFonts.dmSans()),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text("Cancel",
                                          style: GoogleFonts.dmSans(
                                              color: Colors.grey)),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        provider.deleteSession(session.id);
                                        Navigator.pop(ctx);
                                      },
                                      child: Text("Delete",
                                          style: GoogleFonts.dmSans(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                if (chatProvider.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text("Ask me anything about farming!",
                            style: GoogleFonts.dmSans(color: Colors.grey[500])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chatProvider.messages.length +
                      (chatProvider.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == chatProvider.messages.length) {
                      return const ChatBubble(
                        text: "typing...",
                        isUser: false,
                        isLoading: true,
                      );
                    }
                    final msg = chatProvider.messages[index];
                    return ChatBubble(
                      text: msg.text,
                      isUser: msg.isUser,
                      targetPage: msg.targetPage,
                      onNavigate: msg.targetPage != null
                          ? () => _handleNavigation(msg.targetPage!)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Type your query...",
                        hintStyle: GoogleFonts.dmSans(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                      ),
                      onSubmitted: _handleSubmitted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    mini: true,
                    onPressed: () => _handleSubmitted(_controller.text),
                    backgroundColor: Colors.green[700],
                    child: const Icon(Icons.send, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isLoading;
  final String? targetPage;
  final VoidCallback? onNavigate;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.isLoading = false,
    this.targetPage,
    this.onNavigate,
  });

  String _getActionLabel(String target) {
    switch (target) {
      case 'MARKET_INTELLIGENCE':
        return 'View Market Prices';
      case 'CROP_PLANNING':
        return 'Plan Crops';
      case 'HARVEST_TIMING':
        return 'Check Harvest Time';
      case 'INSURANCE':
        return 'View Insurance';
      case 'EQUIPMENT_RENTAL':
        return 'Rent Equipment';
      case 'STORAGE':
        return 'Find Storage';
      case 'GOVT_SCHEMES':
        return 'View Schemes';
      case 'WEATHER':
        return 'Check Weather';
      case 'PROFILE':
        return 'Go to Profile';
      default:
        return 'Open Page';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isUser ? Colors.green[700] : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isUser
                    ? const Radius.circular(16)
                    : const Radius.circular(0),
                bottomRight: isUser
                    ? const Radius.circular(0)
                    : const Radius.circular(16),
              ),
              boxShadow: [
                if (!isUser)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: isLoading
                ? SizedBox(
                    width: 40,
                    child: Row(
                      children: [
                        _dot(0),
                        const SizedBox(width: 4),
                        _dot(100),
                        const SizedBox(width: 4),
                        _dot(200),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: GoogleFonts.dmSans(
                          color: isUser ? Colors.white : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                      if (targetPage != null && onNavigate != null) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: onNavigate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_forward,
                                    size: 16, color: Colors.green[800]),
                                const SizedBox(width: 8),
                                Text(
                                  _getActionLabel(targetPage!),
                                  style: GoogleFonts.dmSans(
                                    color: Colors.green[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    ).animate().fade().slideY(begin: 0.1, end: 0, duration: 200.ms);
  }

  Widget _dot(int delay) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        shape: BoxShape.circle,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.2, 1.2),
            duration: 600.ms,
            delay: delay.ms)
        .then()
        .scale(
            begin: const Offset(1.2, 1.2),
            end: const Offset(0.8, 0.8),
            duration: 600.ms);
  }
}

// Helper for navigation to avoid circular imports or messy file
class NavigationHelper {
  static void navigateTo(BuildContext context, String targetPage) {
    // We will implement simpler handling by checking specific strings
    // and pushing relevant routes.
    // Ideally this lives in a separate file or we import everything here.
    // For now, let's assume we can import the necessary screens or use a switch.

    // NOTE: This requires importing all screens.
    // If screens are in different files, we need imports.
  }
}
