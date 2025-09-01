import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_colors.dart';

class CustomDashboardCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color? cardColor;
  final VoidCallback onTap;
  final bool showGradient;

  const CustomDashboardCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.cardColor,
    this.showGradient = true,
  });

  @override
  State<CustomDashboardCard> createState() => _CustomDashboardCardState();
}

class _CustomDashboardCardState extends State<CustomDashboardCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovering = true;
          _controller.reverse();
        });
      },
      onExit: (_) {
        setState(() {
          _isHovering = false;
          _controller.forward();
        });
      },
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onTap: () {
              // Add a little bounce effect when tapped
              _controller.reset();
              _controller.forward();
              widget.onTap();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: size.height * 0.24,
              decoration: BoxDecoration(
                color: _isHovering
                    // ignore: deprecated_member_use
                    ? (widget.cardColor ?? theme.cardColor).withOpacity(0.95)
                    : widget.cardColor ?? theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: _isHovering
                    ? [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: widget.iconColor.withOpacity(0.2),
                          blurRadius: 16,
                          spreadRadius: 2,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: AppColors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                border: Border.all(
                  color: _isHovering
                      // ignore: deprecated_member_use
                      ? widget.iconColor.withOpacity(0.3)
                      // ignore: deprecated_member_use
                      : AppColors.primary.withOpacity(0.2),
                  width: 1.5,
                ),
                gradient: widget.showGradient
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          // ignore: deprecated_member_use
                          (widget.cardColor ?? theme.cardColor).withOpacity(
                            0.8,
                          ),
                          // ignore: deprecated_member_use
                          (widget.cardColor ?? theme.cardColor).withOpacity(
                            0.95,
                          ),
                        ],
                        stops: const [0.0, 1.0],
                      )
                    : null,
              ),
              padding: EdgeInsets.all(size.width * 0.04),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon with animated background
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _isHovering
                          // ignore: deprecated_member_use
                          ? widget.iconColor.withOpacity(0.2)
                          // ignore: deprecated_member_use
                          : widget.iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      boxShadow: _isHovering
                          ? [
                              BoxShadow(
                                // ignore: deprecated_member_use
                                color: widget.iconColor.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: FaIcon(
                      widget.icon,
                      color: widget.iconColor,
                      size: size.width * 0.07,
                    ),
                  ),

                  // Title with smooth transition
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: size.width * 0.045,
                      color: _isHovering
                          ? widget.iconColor
                          : theme.textTheme.titleMedium?.color,
                    ),
                    textAlign: TextAlign.center,
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Description with smooth transition
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: size.width * 0.035,
                        color: _isHovering
                            ? theme.textTheme.bodyMedium?.color
                            // ignore: deprecated_member_use
                            : theme.textTheme.bodyMedium?.color?.withOpacity(
                                0.8,
                              ),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          widget.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),

                  // Optional subtle "Tap" indicator
                  if (_isHovering)
                    Icon(
                      Icons.touch_app_outlined,
                      size: 16,
                      // ignore: deprecated_member_use
                      color: widget.iconColor.withOpacity(0.7),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
