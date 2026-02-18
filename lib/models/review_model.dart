class ReviewCreate {
  final String bookingId;
  final double rating;
  final String reviewText;
  final String mobileNumber;

  ReviewCreate({
    required this.bookingId,
    required this.rating,
    required this.reviewText,
    required this.mobileNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'rating': rating,
      'review_text': reviewText,
      // mobileNumber is passed in header, not body
    };
  }
}
