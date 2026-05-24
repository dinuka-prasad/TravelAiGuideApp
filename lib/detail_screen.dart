import 'package:flutter/material.dart';
import 'ai_tips_screen.dart';
import 'trip_planner_screen.dart';
import 'planner_screen.dart';
import 'app_theme.dart';

// සටහන: WishlistManager ක්ලාස් එක වෙනත් ෆයිල් එකක ඇති බව උපකල්පනය කෙරේ.
// (ඔයා දැනටමත් වෙනත් තැනක ලියා ඇති නිසා මෙහි වෙනසක් කර නැත)

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> location;
  const DetailScreen({super.key, required this.location});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isSaved = false;
  bool _checkingStatus = true;

  @override
  void initState() {
    super.initState();
    _checkSavedStatus();
  }

  Future<void> _checkSavedStatus() async {
    // WishlistManager එකෙන් ස්ටේටස් එක චෙක් කිරීම
    final saved =
        await WishlistManager.isSaved(widget.location['name'] as String);
    if (mounted) {
      setState(() {
        _isSaved = saved;
        _checkingStatus = false;
      });
    }
  }

  Future<void> _toggleWishlist() async {
    final name = widget.location['name'] as String;
    if (_isSaved) {
      await WishlistManager.remove(name);
      if (mounted) {
        setState(() => _isSaved = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name removed from Planner.'),
            backgroundColor: AppColors.textSecondary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } else {
      // සේව් කිරීමට පෙර කලර් එක int එකකට සීරියලයිස් කිරීම
      final data = Map<String, dynamic>.from(widget.location);
      final color = data['tagColor'] as Color?;
      data['tagColorValue'] = color?.toARGB32();
      data.remove('tagColor');

      await WishlistManager.add(data);
      if (mounted) {
        setState(() => _isSaved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name added to Planner! ✈️'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.location['name'],
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              background: Stack(fit: StackFit.expand, children: [
                Image.network(
                  widget.location['img'],
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Container(color: AppColors.primaryDark),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC1A006A)],
                    ),
                  ),
                ),
              ]),
            ),
            actions: [
              // விஷ்லிஸ்ட் ටොගල් බටන් එක
              if (_checkingStatus)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  icon: Icon(
                    _isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: _isSaved ? AppColors.accentLight : Colors.white,
                  ),
                  onPressed: _toggleWishlist,
                  tooltip: _isSaved ? 'Remove from Planner' : 'Save to Planner',
                ),
              IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {}),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ටැග් සහ රේටින්ග් පේළිය
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color:
                                widget.location['tagColor'] ?? AppColors.primary,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(widget.location['tag'],
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      Text(' ${widget.location['rating']} / 5.0',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const Spacer(),
                      // වියදම් විස්තරය (Cost Chip)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFA5D6A7)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.attach_money,
                                color: Color(0xFF2E7D32), size: 14),
                            Text(widget.location['cost'],
                                style: const TextStyle(
                                    color: Color(0xFF2E7D32),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // විස්තර ප pill පේළිය
                    Row(
                      children: [
                        _infoPill(Icons.location_on_outlined,
                            AppColors.primary, widget.location['country']),
                        const SizedBox(width: 10),
                        _infoPill(Icons.calendar_month_outlined,
                            AppColors.accentDark, widget.location['bestTime']),
                        const SizedBox(width: 10),
                        _infoPill(Icons.access_time,
                            AppColors.primaryLight, widget.location['duration']),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ස්ථානය පිළිබඳ විස්තරය (About)
                    const Text('About',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Text(widget.location['description'],
                        style: const TextStyle(
                            fontSize: 15,
                            height: 1.7,
                            color: Colors.black87)),
                    const SizedBox(height: 24),

                    // විශේෂතා (Highlights)
                    const Text('Highlights',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          (widget.location['highlights'] as List<dynamic>)
                              .map((h) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.primary
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle,
                                  color: AppColors.primary, size: 14),
                              const SizedBox(width: 6),
                              Text(h.toString(),
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // AI Tips බටන් එක
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  AiTipsScreen(location: widget.location)),
                        ),
                        icon: const Icon(Icons.auto_awesome, size: 20),
                        label: const Text('Ask AI for Travel Tips',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentDark,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 17),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 3,
                          shadowColor:
                              AppColors.accentDark.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Plan Trip බටන් එක (මෙතැනදී location parameter එක නිවැරදි කර ඇත)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AiTripPlannerScreen(
                                  location: widget.location)), // නිවැරදි කරන ලදී
                        ),
                        icon: const Icon(Icons.map_outlined,
                            size: 20, color: AppColors.primary),
                        label: const Text('Plan My Trip with AI',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppColors.primary, width: 2),
                          padding:
                              const EdgeInsets.symmetric(vertical: 17),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoPill(IconData icon, Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}