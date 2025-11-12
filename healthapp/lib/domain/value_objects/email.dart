class Email {
  final String value;
  Email(this.value) {
    if (!value.contains('@')) {
      throw ArgumentError('Invalid email');
    }
  }
}

