import 'dart:async';
import 'package:flutter/material.dart';
import 'package:movie_booking_app/data/movie_data.dart';
import 'package:movie_booking_app/models/movie_model.dart';
import 'package:movie_booking_app/views/home/widgets/movie_carousel.dart';
import 'package:movie_booking_app/views/movie_detail/movie_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedFilter = "Streaming Now";
  List<MovieModel> _carouselMovies = [];
  List<MovieModel> _filteredMovies = [];
  List<MovieModel> _searchResults = [];
  Timer? _debounceTimer;
  TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _carouselMovies = MovieData.sampleMovies.take(5).toList();
    _updateFilteredMovies();
  }

  void _updateFilteredMovies() {
    setState(() {
      if (selectedFilter == "Streaming Now") {
        _filteredMovies = MovieData.sampleMovies
            .where((movie) => movie.status == MovieStatus.streamingNow)
            .toList();
      } else if (selectedFilter == "Coming Soon") {
        _filteredMovies = MovieData.sampleMovies
            .where((movie) => movie.status == MovieStatus.comingSoon)
            .toList();
      } else {
        _filteredMovies = MovieData.sampleMovies;
      }
    });
  }

  void _searchMovies(String query) {
    // Cancel any pending debounce timer
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    _debounceTimer = Timer(Duration(milliseconds: 300), () {
      setState(() {
        _isSearching = true;
        _searchResults = MovieData.sampleMovies
            .where((movie) =>
                movie.title.toLowerCase().contains(query.toLowerCase()) ||
                movie.genre.toLowerCase().contains(query.toLowerCase()) ||
                movie.director.toLowerCase().contains(query.toLowerCase()) ||
                movie.cast.any((actor) =>
                    actor.toLowerCase().contains(query.toLowerCase())))
            .toList();
      });
    });
  }


  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF212121).withValues(alpha: 0.8),
              const Color(0xFF212121).withValues(alpha: 0.9),
              const Color(0xFF212121),
            ],
          ),
        ),
        child: SingleChildScrollView(
          physics: ClampingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: 130),
              // Search bar
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: _searchMovies,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search movies...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                    prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.6)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.white.withValues(alpha: 0.6)),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _isSearching = false;
                                _searchResults = [];
                              });
                              FocusScope.of(context).unfocus();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Show carousel only when not searching
              if (!_isSearching) ...[
                MovieCarousel(movies: _carouselMovies),
                SizedBox(height: 30),
              ],
              // Show different content based on search state
              if (_isSearching) ...[
                // Search Results
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search Results (${_searchResults.length})',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                      SizedBox(height: 16),
                      if (_searchResults.isEmpty)
                        Container(
                          height: 200,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No movies found',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.68,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            return _buildMovieGridItem(_searchResults[index]);
                          },
                        ),
                    ],
                  ),
                ),
              ] else ...[
                // Filter buttons and filtered results
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(child: _buildFilterButton("Streaming Now")),
                      SizedBox(width: 12),
                      Expanded(child: _buildFilterButton("Coming Soon")),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedFilter,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.only(top: 30),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _filteredMovies.length,
                        itemBuilder: (context, index) {
                          return _buildMovieGridItem(_filteredMovies[index]);
                        },
                      ),
                      SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String filter) {
    bool isSelected = selectedFilter == filter;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = filter;
        });
        _updateFilteredMovies();
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [Color(0xFFE50914), Color(0xFFFF1744)])
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            filter,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildMovieGridItem(MovieModel movie) {
    return GestureDetector(
      onTap: () {
        // Navigate to movie detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MovieDetailScreen(movie: movie),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Movie poster
              Image.network(
                movie.posterUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
                      ),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE50914),
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.movie,
                          size: 40,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        SizedBox(height: 8),
                        Text(
                          movie.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
              // Status badge
              if (movie.status == MovieStatus.streamingNow)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'STREAMING',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (movie.status == MovieStatus.comingSoon)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'SOON',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              // Movie info overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        movie.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 14),
                          SizedBox(width: 4),
                          Text(
                            movie.rating.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Spacer(),
                          Text(
                            '\$${movie.price}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
