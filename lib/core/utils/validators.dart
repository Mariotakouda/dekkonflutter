class Validators {
  Validators._();

  static String? required(String? value, {String field = 'Ce champ'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field est obligatoire.';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L\'email est obligatoire.';
    }
    final regex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!regex.hasMatch(value)) {
      return 'Format d\'email invalide.';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le téléphone est obligatoire.';
    }
    final regex = RegExp(r'^\+?[0-9]{8,15}$');
    if (!regex.hasMatch(value)) {
      return 'Format de téléphone invalide.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est obligatoire.';
    }
    if (value.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères.';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(value) || !RegExp(r'[0-9]').hasMatch(value)) {
      return 'Le mot de passe doit contenir des lettres et des chiffres.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value != original) {
      return 'Les mots de passe ne correspondent pas.';
    }
    return null;
  }
}