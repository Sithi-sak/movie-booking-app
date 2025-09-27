import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/movie_model.dart';
import '../booking_confirmation/booking_confirmation_screen.dart';
import '../../theme/app_theme.dart';
import '../../services/booking_service.dart';

class TicketBookingScreen extends StatefulWidget {
  final MovieModel movie;
  final String selectedShowtime;

  const TicketBookingScreen({
    super.key,
    required this.movie,
    required this.selectedShowtime,
  });

  @override
  State<TicketBookingScreen> createState() => _TicketBookingScreenState();
}

class _TicketBookingScreenState extends State<TicketBookingScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _seatAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  int currentStep = 0;
  String selectedShowtime = '';
  String selectedDate = '';
  List<String> selectedSeatNumbers = [];
  double totalPrice = 0.0;

  final PageController _pageController = PageController();

  final List<String> dates = [
    'Today',
    'Tomorrow',
    'Dec 18',
    'Dec 19',
    'Dec 20',
  ];

  final List<List<String>> seatLayout = [
    ['A1', 'A2', 'A3', 'A4', '', 'A5', 'A6', 'A7', 'A8'],
    ['B1', 'B2', 'B3', 'B4', '', 'B5', 'B6', 'B7', 'B8'],
    ['C1', 'C2', 'C3', 'C4', '', 'C5', 'C6', 'C7', 'C8'],
    ['', '', '', '', '', '', '', '', ''],
    ['D1', 'D2', 'D3', 'D4', '', 'D5', 'D6', 'D7', 'D8'],
    ['E1', 'E2', 'E3', 'E4', '', 'E5', 'E6', 'E7', 'E8'],
    ['F1', 'F2', 'F3', 'F4', '', 'F5', 'F6', 'F7', 'F8'],
  ];

  List<String> bookedSeats = [];

  final List<String> stepTitles = [
    'Date & Time',
    'Pick Seats',
    'Review & Pay'
  ];

  @override
  void initState() {
    super.initState();
    selectedShowtime = widget.selectedShowtime;
    selectedDate = dates.first;
    totalPrice = widget.movie.price;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _seatAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _seatAnimationController, curve: Curves.elasticOut),
    );

    _animationController.forward();

    // Load booked seats for the initially selected showtime
    _updateBookedSeats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _seatAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (currentStep < 2) {
      setState(() {
        currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      HapticFeedback.lightImpact();
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _selectSeat(String seatNumber) {
    if (seatNumber.isEmpty) return;

    if (bookedSeats.contains(seatNumber)) {
      // Show feedback that seat is already booked
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seat $seatNumber is already booked by another user'),
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      if (selectedSeatNumbers.contains(seatNumber)) {
        selectedSeatNumbers.remove(seatNumber);
      } else {
        selectedSeatNumbers.add(seatNumber);
      }
      totalPrice = widget.movie.price * selectedSeatNumbers.length;
    });

    _seatAnimationController.forward().then((_) {
      _seatAnimationController.reverse();
    });

    HapticFeedback.selectionClick();
  }

  void _updateBookedSeats() {
    if (selectedDate.isNotEmpty && selectedShowtime.isNotEmpty) {
      setState(() {
        bookedSeats = BookingService().getBookedSeatsForMovieAndShowtime(
          widget.movie.title,
          selectedDate,
          selectedShowtime,
        );
      });
    }
  }

  Color _getSeatColor(String seatNumber) {
    if (seatNumber.isEmpty) return Colors.transparent;
    if (bookedSeats.contains(seatNumber)) return Colors.red.shade300;
    if (selectedSeatNumbers.contains(seatNumber)) return AppTheme.primaryRed;
    return AppTheme.surfaceDark;
  }

  bool _canProceed() {
    switch (currentStep) {
      case 0: // Date & Time selection
        return selectedDate.isNotEmpty && selectedShowtime.isNotEmpty;
      case 1: // Seat selection
        return selectedSeatNumbers.isNotEmpty;
      case 2: // Review & Pay
        return selectedSeatNumbers.isNotEmpty;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundDark.withValues(alpha: 0.8),
              AppTheme.backgroundDark.withValues(alpha: 0.9),
              AppTheme.backgroundDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressIndicator(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      currentStep = index;
                    });
                  },
                  children: [
                    _buildDateTimeSelection(),
                    _buildSeatSelection(),
                    _buildReviewPage(),
                  ],
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Book Tickets',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  stepTitles[currentStep],
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(stepTitles.length, (index) {
          bool isActive = index <= currentStep;
          bool isCurrent = index == currentStep;

          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < stepTitles.length - 1 ? 8 : 0),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.primaryRed : AppTheme.borderDark,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      color: isCurrent ? AppTheme.primaryRed :
                             isActive ? AppTheme.textPrimary : AppTheme.textTertiary,
                      fontSize: 12,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                    child: Text(stepTitles[index]),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDateTimeSelection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMovieHeader(),
              const SizedBox(height: 32),
              Text(
                'When would you like to watch?',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select your preferred date and time',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Date Selection
              Text(
                'Choose Date',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: dates.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildEnhancedDateButton(dates[index]),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Time Selection (only show if date is selected)
              if (selectedDate.isNotEmpty) ...[
                Text(
                  'Choose Showtime',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Available showtimes for $selectedDate',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.8,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: widget.movie.showtimes.length,
                    itemBuilder: (context, index) {
                      return _buildEnhancedTimeButton(widget.movie.showtimes[index]);
                    },
                  ),
                ),
              ] else
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 64,
                          color: AppTheme.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select a date to see available showtimes',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
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

  Widget _buildSeatSelection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose your seats',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to select your preferred seats',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Screen indicator
          _buildScreenIndicator(),

          const SizedBox(height: 32),

          // Seat layout
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ...seatLayout.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: entry.value.map((seat) => _buildEnhancedSeat(seat)).toList(),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),
                  _buildSeatLegend(),

                  const SizedBox(height: 24),
                  if (selectedSeatNumbers.isNotEmpty)
                    _buildSeatSummary(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewPage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review your booking',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Double-check everything looks good',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildBookingSummaryCard(),
                  const SizedBox(height: 20),
                  _buildPricingBreakdown(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceDark.withValues(alpha: 0.8),
            AppTheme.surfaceDark.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderDark.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.movie.posterUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.surfaceDark,
                    child: Icon(
                      Icons.movie_creation_outlined,
                      color: AppTheme.textSecondary,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.movie.title,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.movie.genre.split(',').first,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      widget.movie.rating.toString(),
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedDateButton(String date) {
    bool isSelected = selectedDate == date;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDate = date;
          // Clear selected showtime when date changes
          selectedShowtime = '';
          selectedSeatNumbers.clear();
          totalPrice = 0.0;
        });
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 120,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(
            colors: [AppTheme.primaryRed, AppTheme.primaryRed.withValues(alpha: 0.8)],
          ) : null,
          color: !isSelected ? AppTheme.surfaceDark.withValues(alpha: 0.6) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryRed : AppTheme.borderDark,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppTheme.primaryRed.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Center(
          child: Text(
            date,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedTimeButton(String time) {
    bool isSelected = selectedShowtime == time;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedShowtime = time;
          selectedSeatNumbers.clear();
          totalPrice = 0.0;
        });
        _updateBookedSeats();
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(
            colors: [AppTheme.primaryRed, AppTheme.primaryRed.withValues(alpha: 0.8)],
          ) : null,
          color: !isSelected ? AppTheme.surfaceDark.withValues(alpha: 0.6) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryRed : AppTheme.borderDark,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            time,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScreenIndicator() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppTheme.primaryRed.withValues(alpha: 0.6),
                Colors.transparent,
              ],
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'SCREEN',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedSeat(String seatNumber) {
    if (seatNumber.isEmpty) {
      return const SizedBox(width: 35, height: 35);
    }

    bool isSelected = selectedSeatNumbers.contains(seatNumber);
    bool isBooked = bookedSeats.contains(seatNumber);

    return GestureDetector(
      onTap: () => _selectSeat(seatNumber),
      child: ScaleTransition(
        scale: isSelected ? _scaleAnimation :
               const AlwaysStoppedAnimation(1.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 35,
          height: 35,
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: _getSeatColor(seatNumber),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppTheme.primaryRed :
                     isBooked ? Colors.red.shade400 : AppTheme.borderDark,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: AppTheme.primaryRed.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ] : isBooked ? [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Center(
            child: isBooked ?
              Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ) :
              Text(
                seatNumber,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeatLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem('Available', AppTheme.surfaceDark),
          _buildLegendItem('Selected', AppTheme.primaryRed),
          _buildLegendItem('Booked', Colors.red.shade300),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSeatSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryRed.withValues(alpha: 0.1),
            AppTheme.primaryRed.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryRed.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selected Seats',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                selectedSeatNumbers.join(', '),
                style: TextStyle(
                  color: AppTheme.primaryRed,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                '\$${totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppTheme.primaryRed,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceDark.withValues(alpha: 0.8),
            AppTheme.surfaceDark.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderDark.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Summary',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Movie', widget.movie.title),
          _buildSummaryRow('Date', selectedDate),
          _buildSummaryRow('Time', selectedShowtime),
          _buildSummaryRow('Seats', selectedSeatNumbers.join(', ')),
          _buildSummaryRow('Cinema', 'AMC Theater'), // You can make this dynamic
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingBreakdown() {
    double fees = totalPrice * 0.1; // 10% service fee
    double tax = (totalPrice + fees) * 0.08; // 8% tax
    double finalTotal = totalPrice + fees + tax;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryRed.withValues(alpha: 0.1),
            AppTheme.primaryRed.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryRed.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Breakdown',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPriceRow('Tickets (${selectedSeatNumbers.length}x)', '\$${totalPrice.toStringAsFixed(2)}'),
          _buildPriceRow('Service Fee', '\$${fees.toStringAsFixed(2)}'),
          _buildPriceRow('Tax', '\$${tax.toStringAsFixed(2)}'),
          const Divider(color: Colors.white24, height: 20),
          _buildPriceRow('Total Amount', '\$${finalTotal.toStringAsFixed(2)}', isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: isTotal ? AppTheme.primaryRed : AppTheme.textPrimary,
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        border: Border(
          top: BorderSide(
            color: AppTheme.borderDark.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.borderDark),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Back',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _canProceed() ? () {
                if (currentStep == 2) {
                  // Navigate to confirmation
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingConfirmationScreen(
                        movie: widget.movie,
                        selectedDate: selectedDate,
                        selectedShowtime: selectedShowtime,
                        selectedSeats: selectedSeatNumbers,
                        totalPrice: totalPrice + (totalPrice * 0.18), // Including fees and tax
                      ),
                    ),
                  );
                } else {
                  _nextStep();
                }
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canProceed() ? AppTheme.primaryRed : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: _canProceed() ? 8 : 0,
              ),
              child: Text(
                currentStep == 2 ? 'Confirm Booking' : 'Next',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}