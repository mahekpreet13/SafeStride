import 'package:flutter/material.dart';

/// Maps navigation instruction codes to corresponding Material Icons.
/// 
/// This utility function translates numeric instruction codes from routing
/// services (like GraphHopper) into user-friendly direction icons.
/// The codes follow standard navigation instruction conventions.
IconData iconForInstruction(String sign) {
  switch (sign) {
    case '0':  // Continue straight
      return Icons.arrow_upward;
    case '1':  // Turn slight right
      return Icons.turn_slight_right;
    case '2':  // Turn right
      return Icons.turn_right;
    case '3':  // Turn sharp right
      return Icons.turn_sharp_right;
    case '4':  // U-turn right
      return Icons.rotate_right;
    case '-1': // Turn slight left
      return Icons.turn_slight_left;
    case '-2': // Turn left
      return Icons.turn_left;
    case '-3': // Turn sharp left
      return Icons.turn_sharp_left;
    case '-4': // U-turn left
      return Icons.rotate_left;
    case '5':  // Reached destination
      return Icons.flag;
    default:   // Default walking/unknown instruction
      return Icons.directions_walk;
  }
}
