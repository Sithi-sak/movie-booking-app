
import 'package:movie_booking_app/data/models/movie_model.dart';
import 'package:movie_booking_app/data/models/ticket_model.dart';

class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  final List<TicketModel> _bookedTickets = [];


  List<TicketModel> get bookedTickets => List.unmodifiable(_bookedTickets);

  String addBooking({
    required MovieModel movie,
    required String selectedDate,
    required String selectedShowtime,
    required List<String> selectedSeats,
    required double totalPrice,
    String cinema = 'Cinema Hall 1',
  }) {
    // Check if any of the selected seats are already booked
    final bookedSeats = getBookedSeatsForMovieAndShowtime(
      movie.title,
      selectedDate,
      selectedShowtime,
    );

    final conflictingSeats = selectedSeats.where((seat) => bookedSeats.contains(seat)).toList();

    if (conflictingSeats.isNotEmpty) {
      throw Exception('Seats already booked: ${conflictingSeats.join(', ')}');
    }

    final ticketId = 'TKT${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    final newTicket = TicketModel(
      id: ticketId,
      movieTitle: movie.title,
      moviePoster: movie.posterUrl ?? '',
      date: selectedDate,
      showtime: selectedShowtime,
      seats: selectedSeats,
      totalPrice: totalPrice,
      cinema: cinema,
      bookingDate: DateTime.now(),
      status: 'confirmed',
    );

    _bookedTickets.insert(0, newTicket);
    return ticketId;
  }

  TicketModel? getTicketById(String ticketId) {
    try {
      return _bookedTickets.firstWhere((ticket) => ticket.id == ticketId);
    } catch (e) {
      return null;
    }
  }

  void updateTicketStatus(String ticketId, String status) {
    final ticketIndex = _bookedTickets.indexWhere((ticket) => ticket.id == ticketId);
    if (ticketIndex != -1) {
      final ticket = _bookedTickets[ticketIndex];
      final updatedTicket = TicketModel(
        id: ticket.id,
        movieTitle: ticket.movieTitle,
        moviePoster: ticket.moviePoster,
        date: ticket.date,
        showtime: ticket.showtime,
        seats: ticket.seats,
        totalPrice: ticket.totalPrice,
        cinema: ticket.cinema,
        bookingDate: ticket.bookingDate,
        status: status,
      );
      _bookedTickets[ticketIndex] = updatedTicket;
    }
  }

  List<TicketModel> getTicketsByStatus(String status) {
    return _bookedTickets.where((ticket) => ticket.status == status).toList();
  }

  List<String> getBookedSeatsForMovieAndShowtime(String movieTitle, String date, String showtime) {
    final bookedSeats = <String>[];

    for (final ticket in _bookedTickets) {
      if (ticket.movieTitle == movieTitle &&
          ticket.date == date &&
          ticket.showtime == showtime &&
          ticket.status == 'confirmed') {
        bookedSeats.addAll(ticket.seats);
      }
    }

    return bookedSeats;
  }
}