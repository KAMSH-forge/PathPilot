class VoiceCommandHandler {
  final Function(String) showFeedback;
  final Function getDestination; // Updated to match _getDestination
  final Function getUserLocation; // Updated to match _getUserLocation
  final Function stopNavigation;
  final Function togglePrimaryView;
  final Function toggleCameraVisibility;

  VoiceCommandHandler({
    required this.showFeedback,
    required this.getDestination,
    required this.getUserLocation,
    required this.stopNavigation,
    required this.togglePrimaryView,
    required this.toggleCameraVisibility,
  });

  void processVoiceCommand(String recognizedText) {
    String text = _normalizeInput(recognizedText);

    // Check if the command starts with "pilot"
    if (!_isValidCommand(text)) {
      showFeedback("Please start your command with 'Path Pilot'.");
      return;
    }

    // Extract the actual command after "pilot"
    String command = _extractCommand(text);

    // Handle the command
    if (_handleTakeMeTo(command)) {
      return;
    } else if (_handleWhereAmI(command)) {
      return;
    } else if (_handleStopNavigation(command)) {
      return;
    } else if (_handleShowCamera(command)) {
      return;
    } else if (_handleHideCamera(command)) {
      return;
    } else if (_handleSwitchView(command)) {
      return;
    } else {
      showFeedback("Command not recognized. Try 'take me to...', 'where am i?', or 'stop navigation'.");
    }
  }

  // Normalize input
  String _normalizeInput(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
        .trim();
  }

  // Validate the command
  bool _isValidCommand(String text) {
    return text.contains("pilot");
  }

  // Extract the command after "pilot"
  String _extractCommand(String text) {
    return text.replaceAll("pilot", "").trim();
  }

  // Handle "take me to" or "navigate to" commands
  bool _handleTakeMeTo(String command) {
    if (command.startsWith("take me to") || command.startsWith("navigate to")) {
      String destinationQuery = command
          .replaceAll("take me to", "")
          .replaceAll("navigate to", "")
          .trim();
      if (destinationQuery.isNotEmpty) {
        // Update the search controller and call getDestination
        getDestination(destinationQuery); // Call the callback
        print("Destination: ${destinationQuery}");
        return true;
      } else {
        showFeedback("Please specify a destination after 'take me to'.");
        return true;
      }
    }
    return false;
  }

  // Handle "where am i" or similar commands
  bool _handleWhereAmI(String command) {
    if (command == "where am i" ||
        command == "tell me my location" ||
        command == "current location") {
      getUserLocation(); // Call the callback
      return true;
    }
    return false;
  }

  // Handle "stop navigation" or similar commands
  bool _handleStopNavigation(String command) {
    if (command == "stop navigation" || command == "cancel navigation") {
      stopNavigation();
      showFeedback("Navigation stopped.");
      return true;
    }
    return false;
  }

  // Handle "show camera" command
  bool _handleShowCamera(String command) {
    if (command == "show camera") {
      toggleCameraVisibility(true);
      showFeedback("Showing camera.");
      return true;
    }
    return false;
  }

  // Handle "hide camera" command
  bool _handleHideCamera(String command) {
    if (command == "hide camera") {
      toggleCameraVisibility(false);
      showFeedback("Hiding camera.");
      return true;
    }
    return false;
  }

  // Handle "switch view" or "toggle view" commands
  bool _handleSwitchView(String command) {
    if (command == "switch view" || command == "toggle view") {
      togglePrimaryView();
      showFeedback("Switching view.");
      return true;
    }
    return false;
  }
}