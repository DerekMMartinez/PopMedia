import 'package:flutter/material.dart';

Widget staticStarRating(double rating, {double size = 22}) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.black, width: 2),
      color: Colors.white,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        double fill;
        if (index + 1 <= rating) {
          fill = 1.0;
        } else if (index + 0.5 <= rating) {
          fill = 0.5;
        } else {
          fill = 0.0;
        }

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.star_border, size: size, color: Colors.black),
              if (fill > 0)
                ClipRect(
                  clipper: _StarClipper(fill),
                  child: Icon(Icons.star, size: size, color: Colors.amber),
                ),
            ],
          ),
        );
      }),
    )
    );
  }

class _StarClipper extends CustomClipper<Rect> {
  final double fill;

  _StarClipper(this.fill);

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * fill, size.height);

  @override
  bool shouldReclip(covariant _StarClipper oldClipper) => oldClipper.fill != fill;
}

