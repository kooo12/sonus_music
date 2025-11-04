import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/app/controllers/home_controller.dart';
import 'package:music_player/app/controllers/language_controller.dart';
import 'package:music_player/app/controllers/theme_controller.dart';
import 'package:music_player/app/data/models/song_model.dart';
import 'package:music_player/app/ui/theme/app_colors.dart';
import 'package:music_player/app/ui/theme/sizes.dart';

class SmartRecommendationsWidget extends StatelessWidget {
  final bool isCompact;

  const SmartRecommendationsWidget({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final languageCtrl = Get.find<LanguageController>();

    return Obx(() {
      final recommendations =
          _generateRecommendations(languageCtrl, controller);

      if (isCompact) {
        return _buildCompactRecommendations(recommendations, controller);
      }

      return _buildFullRecommendations(recommendations, controller);
    });
  }

  Widget _buildCompactRecommendations(
      List<Map<String, dynamic>> recommendations, HomeController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4A4AFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Smart Picks',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recommendations
              .take(3)
              .map((rec) => _buildCompactRecommendationItem(rec, controller)),
        ],
      ),
    );
  }

  Widget _buildFullRecommendations(
      List<Map<String, dynamic>> recommendations, HomeController controller) {
    final themeCtrl = Get.find<ThemeController>();

    return Container(
      margin: const EdgeInsets.only(right: TpsSizes.defaultSpace),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: themeCtrl.isDarkMode
              ? TpsColors.darkGradientColors
              : [
                  const Color(0xFF6C63FF).withOpacity(0.6),
                  const Color(0xFF4A4AFF)
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: themeCtrl.isDarkMode
                ? TpsColors.darkerGrey
                : const Color(0xFF6C63FF).withOpacity(0.7),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Smart Recommendations'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Based on your listening habits'.tr,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          ...recommendations
              .map((rec) => _buildFullRecommendationItem(rec, controller)),
        ],
      ),
    );
  }

  Widget _buildCompactRecommendationItem(
      Map<String, dynamic> rec, HomeController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _handleRecommendationTap(rec, controller),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                rec['emoji'],
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rec['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      rec['subtitle'],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.play_arrow,
                color: Colors.white.withOpacity(0.7),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullRecommendationItem(
      Map<String, dynamic> rec, HomeController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _handleRecommendationTap(rec, controller),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: rec['color'].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rec['emoji'],
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rec['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rec['subtitle'],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    if (rec['description'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        rec['description'],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.play_arrow,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _generateRecommendations(
      LanguageController languageCtrl, HomeController controller) {
    final allSongs = controller.allSongs;
    if (allSongs.isEmpty) return [];

    final recommendations = <Map<String, dynamic>>[];

    // Analyze user's music library
    final genres = <String, int>{};
    final artists = <String, int>{};
    final recentSongs = controller.recentlyPlayed.take(5).toList();

    for (var song in allSongs) {
      final genre = song.genre ?? 'Unknown';
      final artist = song.artist;
      genres[genre] = (genres[genre] ?? 0) + 1;
      artists[artist] = (artists[artist] ?? 0) + 1;
    }

    final topGenres = genres.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topArtists = artists.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 1. Genre-based recommendation
    if (topGenres.isNotEmpty) {
      final topGenre = topGenres.first.key;
      final genreSongs = allSongs.where((s) => s.genre == topGenre).toList();
      if (genreSongs.isNotEmpty) {
        recommendations.add({
          'type': 'genre',
          'title': languageCtrl.currentLocale.languageCode == 'my'
              ? "$topGenre သီချင်းများ"
              : 'More $topGenre',
          'subtitle': languageCtrl.currentLocale.languageCode == 'my'
              ? "သီချင်းစာရင်းမှ သီချင်းများ ${genreSongs.length} ခု"
              : '${genreSongs.length} songs in your library',
          'description': languageCtrl.currentLocale.languageCode == 'my'
              ? "သင်ကြိုက်နိုင်သော ${topGenre.toLowerCase()} ဂီတများကို ရှာဖွေကြည့်ပါ"
              : 'Discover more ${topGenre.toLowerCase()} music you might like',
          'emoji': _getGenreEmoji(topGenre),
          'color': _getGenreColor(topGenre),
          'songs': genreSongs,
        });
      }
    }

// 2. Artist-based recommendation
    if (topArtists.isNotEmpty) {
      final topArtist = topArtists.first.key;
      final artistSongs = allSongs.where((s) => s.artist == topArtist).toList();
      if (artistSongs.length > 1) {
        recommendations.add({
          'type': 'artist',
          'title': languageCtrl.currentLocale.languageCode == 'my'
              ? "$topArtist ၏ အပြည့်စုံ စုစည်းမှု"
              : 'Complete $topArtist Collection',
          'subtitle': languageCtrl.currentLocale.languageCode == 'my'
              ? "သီချင်း ${artistSongs.length} ပုဒ် ရှိပါသည်"
              : '${artistSongs.length} songs available',
          'description': languageCtrl.currentLocale.languageCode == 'my'
              ? "သင်နှစ်သက်သော အနုပညာရှင်၏ သီချင်းအားလုံးကို နားထောင်ပါ"
              : 'Listen to all songs by your favorite artist',
          'emoji': '🎤',
          'color': const Color(0xFFFF6B6B),
          'songs': artistSongs,
        });
      }
    }

// 3. Recently played continuation
    if (recentSongs.isNotEmpty) {
      final recentGenre = recentSongs.first.genre;
      final similarSongs = allSongs
          .where((s) => s.genre == recentGenre && !recentSongs.contains(s))
          .toList();

      if (similarSongs.isNotEmpty) {
        recommendations.add({
          'type': 'similar',
          'title': languageCtrl.currentLocale.languageCode == 'my'
              ? "နားထောင်ခဲ့သည့်ခံစားမှု ဆက်လက်ခံစားပါ"
              : 'Continue the Vibe',
          'subtitle': languageCtrl.currentLocale.languageCode == 'my'
              ? "မကြာသေးမီတွင် နားထောင်ခဲ့သည့်သီချင်းနှင့် ဆင်တူသည်"
              : 'Similar to recent plays',
          'description': languageCtrl.currentLocale.languageCode == 'my'
              ? "သင်နားထောင်ခဲ့သည့် ${recentGenre?.toLowerCase() ?? 'ဂီတ'} နှင့် ဆင်တူသည့် သီချင်းများပိုမို ရှာဖွေပါ"
              : 'More ${recentGenre?.toLowerCase() ?? 'music'} like what you just heard',
          'emoji': '🔄',
          'color': const Color(0xFF4ECDC4),
          'songs': similarSongs.take(20).toList(),
        });
      }
    }

// 4. Discovery recommendation
    final undiscoveredArtists = allSongs
        .where((s) => !topArtists.take(5).any((a) => a.key == s.artist))
        .toList();

    if (undiscoveredArtists.isNotEmpty) {
      recommendations.add({
        'type': 'discovery',
        'title': languageCtrl.currentLocale.languageCode == 'my'
            ? "အနုပညာရှင်အသစ်များ ရှာဖွေပါ"
            : 'Discover New Artists',
        'subtitle': languageCtrl.currentLocale.languageCode == 'my'
            ? "နားမထောင်ရသေးသော အနုပညာရှင်အသစ် ${undiscoveredArtists.length} ဦး"
            : '${undiscoveredArtists.length} hidden gems',
        'description': languageCtrl.currentLocale.languageCode == 'my'
            ? "သင် နားမထောင်ဖူးသေးသော အနုပညာရှင်များကို စူးစမ်းပါ"
            : 'Explore artists you haven\'t listened to much',
        'emoji': '🔍',
        'color': const Color(0xFF9B59B6),
        'songs': undiscoveredArtists.take(15).toList(),
      });
    }

// 5. Random mix recommendation
    if (allSongs.length > 10) {
      final randomSongs = List<SongModel>.from(allSongs)..shuffle();
      recommendations.add({
        'type': 'random',
        'title': languageCtrl.currentLocale.languageCode == 'my'
            ? "အံ့သြစရာများ"
            : 'Surprise Me',
        'subtitle': languageCtrl.currentLocale.languageCode == 'my'
            ? "သင့်သီချင်းစာရင်းမှ ကျပန်းကို ရွေးပေးပါမည်"
            : 'Random mix from your library',
        'description': languageCtrl.currentLocale.languageCode == 'my'
            ? "သင့်အတွက် မမျှော်လင့်ထားသော သီချင်းတစ်ခုကို ရွေးပေးပါမည်"
            : 'Let us pick something unexpected for you',
        'emoji': '🎲',
        'color': const Color(0xFFFF9F43),
        'songs': randomSongs.take(25).toList(),
      });
    }

    return recommendations.take(4).toList();
  }

  void _handleRecommendationTap(
      Map<String, dynamic> rec, HomeController controller) {
    final songs = rec['songs'] as List<SongModel>;
    if (songs.isNotEmpty) {
      controller.playSong(songs, songs.first);
    }
  }

  String _getGenreEmoji(String genre) {
    final genreLower = genre.toLowerCase();
    if (genreLower.contains('rock')) return '🤘';
    if (genreLower.contains('pop')) return '💃';
    if (genreLower.contains('jazz')) return '🎷';
    if (genreLower.contains('classical')) return '🎼';
    if (genreLower.contains('electronic')) return '🎛️';
    if (genreLower.contains('hip hop') || genreLower.contains('rap')) {
      return '🎤';
    }
    if (genreLower.contains('country')) return '🤠';
    if (genreLower.contains('blues')) return '🎸';
    if (genreLower.contains('reggae')) return '🌴';
    if (genreLower.contains('folk')) return '🪕';
    return '🎵';
  }

  Color _getGenreColor(String genre) {
    final genreLower = genre.toLowerCase();
    if (genreLower.contains('rock')) return const Color(0xFFFF6B6B);
    if (genreLower.contains('pop')) return const Color(0xFFFF9F43);
    if (genreLower.contains('jazz')) return const Color(0xFF4ECDC4);
    if (genreLower.contains('classical')) return const Color(0xFF9B59B6);
    if (genreLower.contains('electronic')) return const Color(0xFF6C63FF);
    if (genreLower.contains('hip hop') || genreLower.contains('rap')) {
      return const Color(0xFF2C3E50);
    }
    if (genreLower.contains('country')) return const Color(0xFF27AE60);
    if (genreLower.contains('blues')) return const Color(0xFF3498DB);
    if (genreLower.contains('reggae')) return const Color(0xFFE67E22);
    if (genreLower.contains('folk')) return const Color(0xFF8E44AD);
    return const Color(0xFF6C63FF);
  }
}
