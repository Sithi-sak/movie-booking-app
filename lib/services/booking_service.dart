

import 'package:movie_booking_app/models/movie_model.dart';
import 'package:movie_booking_app/models/ticket_model.dart';

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
    final ticketId = 'TKT${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    final newTicket = TicketModel(
      id: ticketId,
      movieTitle: movie.title,
      moviePoster: movie.posterUrl,
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
}