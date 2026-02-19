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
        title: Row(
          children: [
            Text(
              "Farmora AI",
              style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
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
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history_edu,
                            color: Colors.white, size: 40),
                        const SizedBox(height: 10),
                        Text(
                          'Conversation History',
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.add_circle_outline,
                      color: Theme.of(context).colorScheme.primary),
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
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.08)
                              : null,
                          border: isCurrent
                              ? Border(
                                  left: BorderSide(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      width: 4))
                              : null,
                        ),
                        child: ListTile(
                          title: Text(
                            preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isCurrent
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.black87),
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
                                      style: GoogleFonts.playfairDisplay(
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
      body: Stack(
        children: [
          // Background Gradient decoration
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFF8F5F2),
                    Colors.white.withOpacity(0.5),
                  ],
                ),
              ),
            ),
          ),

          Column(
            children: [
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    if (chatProvider.messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.auto_awesome,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.primary),
                            ),
                            const SizedBox(height: 24),
                            Text("How can I help your farm deeply?",
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                )),
                            const SizedBox(height: 8),
                            Text("Ask about crops, prices, or weather...",
                                style: GoogleFonts.dmSans(
                                    color: Colors.grey[600], fontSize: 16)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: chatProvider.messages.length +
                          (chatProvider.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == chatProvider.messages.length) {
                          return const ChatBubble(
                            text: "Analyzing farm data...",
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
            ],
          ),

          // Floating Input Area
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(12, 0, 6, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Ask Farmora AI...",
                        hintStyle: GoogleFonts.dmSans(color: Colors.grey[400]),
                        border: InputBorder.none,
                        isDense: true,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      style: GoogleFonts.dmSans(fontSize: 16),
                      onSubmitted: _handleSubmitted,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          const Color(0xFF2E7D32), // Lighter green
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      iconSize: 20,
                      onPressed: () => _handleSubmitted(_controller.text),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().slideY(
              begin: 1.0, end: 0, duration: 400.ms, curve: Curves.easeOutBack),
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
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8),
            decoration: BoxDecoration(
              gradient: isUser
                  ? LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.85),
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    )
                  : null,
              color: isUser ? null : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: isUser
                    ? const Radius.circular(20)
                    : const Radius.circular(4),
                bottomRight: isUser
                    ? const Radius.circular(4)
                    : const Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: isLoading
                ? SizedBox(
                    width: 60,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _dot(0),
                        _dot(200),
                        _dot(400),
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
                          height: 1.5,
                        ),
                      ),
                      if (targetPage != null && onNavigate != null) ...[
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: onNavigate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.green.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bolt,
                                    size: 18, color: Colors.green),
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
    )
        .animate()
        .fade()
        .slideY(begin: 0.2, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }

  Widget _dot(int delay) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        shape: BoxShape.circle,
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(
        begin: const Offset(0.7, 0.7),
        end: const Offset(1.3, 1.3),
        duration: 600.ms,
        delay: delay.ms);
  }
}

// Helper for navigation to avoid circular imports or messy file
class NavigationHelper {
  static void navigateTo(BuildContext context, String targetPage) {
    // Implementation remaining as before
  }
}
