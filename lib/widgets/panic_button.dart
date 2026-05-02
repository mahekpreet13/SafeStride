import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/panic_bloc/panic_bloc.dart';

/// Emergency panic button widget that provides immediate access to emergency services.
/// Features a pulsing animation to draw attention and requires confirmation before activation.
class PanicButton extends StatefulWidget {
  const PanicButton({super.key});

  @override
  State<PanicButton> createState() => _PanicButtonState();
}

class _PanicButtonState extends State<PanicButton>
    with SingleTickerProviderStateMixin {
  /// Controls the pulsing animation of the panic button.
  late AnimationController _animationController;
  
  /// Animation that creates the pulsing effect to draw user attention.
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showPanicConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PanicConfirmationDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PanicBloc, PanicState>(
      listener: (context, state) {
        if (state is PanicConfirming) {
          _animationController.repeat(reverse: true);
        } else {
          _animationController.stop();
          _animationController.reset();
        }

        if (state is PanicActivated) {
          _showPanicAlert(context);
        }
      },
      child: BlocBuilder<PanicBloc, PanicState>(
        builder: (context, state) {
          return AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: state is PanicConfirming ? _pulseAnimation.value : 1.0,
                child: FloatingActionButton.large(
                  onPressed: () {
                    if (state is PanicInitial) {
                      _showPanicConfirmation();
                    }
                  },
                  backgroundColor: state is PanicConfirming
                      ? Colors.orange
                      : Colors.red.shade600,
                  child: Icon(Icons.warning, size: 36, color: Colors.white),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showPanicAlert(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 32),
              SizedBox(width: 8),
              Text('PANIC ALERT ACTIVATED'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Emergency alert has been triggered.'),
              SizedBox(height: 16),
              Text('Time: ${DateTime.now().toString().substring(0, 19)}'),
              SizedBox(height: 8),
              Text('Status: Active'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<PanicBloc>().add(ResetPanic());
              },
              child: Text('DISMISS'),
            ),
          ],
        );
      },
    );
  }
}

class PanicConfirmationDialog extends StatefulWidget {
  @override
  State<PanicConfirmationDialog> createState() =>
      _PanicConfirmationDialogState();
}

class _PanicConfirmationDialogState extends State<PanicConfirmationDialog> {
  double _dragDistance = 0.0;
  static const double _confirmThreshold = 200.0;

  @override
  void initState() {
    super.initState();

    context.read<PanicBloc>().add(StartPanicConfirmation());
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragDistance += details.delta.dx;
      _dragDistance = _dragDistance.clamp(0.0, _confirmThreshold);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragDistance >= _confirmThreshold) {
      context.read<PanicBloc>().add(TriggerPanic());
      Navigator.of(context).pop();
    } else {
      setState(() {
        _dragDistance = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PanicBloc, PanicState>(
      listener: (context, state) {
        if (state is PanicInitial) {
          Navigator.of(context).pop();
        }
      },
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'EMERGENCY ALERT',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Slide the button to the right to confirm emergency alert',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 32),
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          'SLIDE TO CONFIRM',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      left: _dragDistance,
                      child: GestureDetector(
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.double_arrow,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      context.read<PanicBloc>().add(CancelPanicConfirmation());
                    },
                    child: Text('CANCEL'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
