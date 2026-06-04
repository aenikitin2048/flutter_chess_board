import 'dart:math';

import 'package:chess_vectors_flutter/chess_vectors_flutter.dart';
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as ch hide State;
import 'board_arrow.dart';
import 'chess_board_controller.dart';
import 'constants.dart';

class ChessBoard extends StatefulWidget {
  /// An instance of [ChessBoardController] which holds the game and allows
  /// manipulating the board programmatically.
  final ChessBoardController controller;

  /// Size of chessboard
  final double? size;

  /// A boolean which checks if the user should be allowed to make moves
  final bool enableUserMoves;

  /// The color type of the board
  final BoardColor boardColor;

  final PlayerColor boardOrientation;

  final VoidCallback? onMove;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;

  final List<BoardArrow> arrows;

  const ChessBoard({
    Key? key,
    required this.controller,
    this.size,
    this.enableUserMoves = true,
    this.boardColor = BoardColor.brown,
    this.boardOrientation = PlayerColor.white,
    this.onMove,
    this.onDragStarted,
    this.onDragEnd,
    this.arrows = const [],
  }) : super(key: key);

  @override
  State<ChessBoard> createState() => _ChessBoardState();
}

class _ChessBoardState extends State<ChessBoard> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: _getBoardImage(widget.boardColor),
          ),
          ValueListenableBuilder<ch.Chess>(
            valueListenable: widget.controller,
            builder: (context, game, _) {
              return Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.0,
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 8),
                      itemBuilder: (context, index) {
                        var row = index ~/ 8;
                        var column = index % 8;
                        var boardRank =
                            widget.boardOrientation == PlayerColor.black
                                ? '${row + 1}'
                                : '${(7 - row) + 1}';
                        var boardFile =
                            widget.boardOrientation == PlayerColor.white
                                ? files[column]
                                : files[7 - column];

                        var squareName = '$boardFile$boardRank';
                        var pieceOnSquare = game.get(squareName);

                        var piece = pieceOnSquare != null
                            ? BoardPiece(
                                pieceType: pieceOnSquare.type.toUpperCase(),
                                pieceColor: pieceOnSquare.color,
                              )
                            : const SizedBox();

                        var draggable = pieceOnSquare != null
                            ? Draggable<PieceMoveData>(
                                feedback: BoardPiece(
                                  pieceType: pieceOnSquare.type.toUpperCase(),
                                  pieceColor: pieceOnSquare.color,
                                ),
                                childWhenDragging: const SizedBox(),
                                onDragStarted: widget.onDragStarted,
                                onDragEnd: (_) => widget.onDragEnd?.call(),
                                data: PieceMoveData(
                                  squareName: squareName,
                                  pieceType: pieceOnSquare.type.toUpperCase(),
                                  pieceColor: pieceOnSquare.color,
                                ),
                                child: piece,
                              )
                            : const SizedBox();

                        var dragTarget = DragTarget<PieceMoveData>(
                            builder: (context, list, _) {
                          return draggable;
                        }, onWillAcceptWithDetails: (details) {
                          return widget.enableUserMoves ? true : false;
                        }, onAcceptWithDetails: (details) async {
                          PieceMoveData pieceMoveData = details.data;
                          // A way to check if move occurred.
                          ch.Color moveColor = game.turn;

                          if (pieceMoveData.pieceType == "P" &&
                              ((pieceMoveData.squareName[1] == "7" &&
                                      squareName[1] == "8" &&
                                      pieceMoveData.pieceColor ==
                                          ch.Color.WHITE) ||
                                  (pieceMoveData.squareName[1] == "2" &&
                                      squareName[1] == "1" &&
                                      pieceMoveData.pieceColor ==
                                          ch.Color.BLACK))) {
                            var val = await _promotionDialog(context);

                            if (val != null) {
                              widget.controller.makeMoveWithPromotion(
                                  from: pieceMoveData.squareName,
                                  to: squareName,
                                  pieceToPromoteTo: val);
                            } else {
                              return;
                            }
                          } else {
                            widget.controller.makeMove(
                                from: pieceMoveData.squareName, to: squareName);
                          }
                          if (game.turn != moveColor) {
                            widget.onMove?.call();
                          }
                        });

                        return dragTarget;
                      },
                      itemCount: 64,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                    ),
                  ),
                  if (widget.arrows.isNotEmpty)
                    IgnorePointer(
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: _ArrowPainter(
                                widget.arrows, widget.boardOrientation),
                            child: Container(),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Returns the board image
  Image _getBoardImage(BoardColor color) {
    switch (color) {
      case BoardColor.brown:
        return Image.asset(
          "images/brown_board.png",
          package: 'flutter_chess_board',
          fit: BoxFit.cover,
        );
      case BoardColor.darkBrown:
        return Image.asset(
          "images/dark_brown_board.png",
          package: 'flutter_chess_board',
          fit: BoxFit.cover,
        );
      case BoardColor.green:
        return Image.asset(
          "images/green_board.png",
          package: 'flutter_chess_board',
          fit: BoxFit.cover,
        );
      case BoardColor.orange:
        return Image.asset(
          "images/orange_board.png",
          package: 'flutter_chess_board',
          fit: BoxFit.cover,
        );
    }
  }

  /// Show dialog when pawn reaches last square
  Future<String?> _promotionDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose promotion'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              InkWell(
                child: WhiteQueen(),
                onTap: () {
                  Navigator.of(context).pop("q");
                },
              ),
              InkWell(
                child: WhiteRook(),
                onTap: () {
                  Navigator.of(context).pop("r");
                },
              ),
              InkWell(
                child: WhiteBishop(),
                onTap: () {
                  Navigator.of(context).pop("b");
                },
              ),
              InkWell(
                child: WhiteKnight(),
                onTap: () {
                  Navigator.of(context).pop("n");
                },
              ),
            ],
          ),
        );
      },
    ).then((value) {
      return value;
    });
  }
}

class BoardPiece extends StatelessWidget {
  final String pieceType;
  final ch.Color pieceColor;

  static final Map<String, Widget> _pieceCache = {};

  const BoardPiece({
    Key? key,
    required this.pieceType,
    required this.pieceColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String pieceKey = (pieceColor == ch.Color.WHITE ? 'W' : 'B') + pieceType;

    return _pieceCache.putIfAbsent(pieceKey, () {
      switch (pieceKey) {
        case "WP":
          return WhitePawn();
        case "WR":
          return WhiteRook();
        case "WN":
          return WhiteKnight();
        case "WB":
          return WhiteBishop();
        case "WQ":
          return WhiteQueen();
        case "WK":
          return WhiteKing();
        case "BP":
          return BlackPawn();
        case "BR":
          return BlackRook();
        case "BN":
          return BlackKnight();
        case "BB":
          return BlackBishop();
        case "BQ":
          return BlackQueen();
        case "BK":
          return BlackKing();
        default:
          return WhitePawn();
      }
    });
  }
}

class PieceMoveData {
  final String squareName;
  final String pieceType;
  final ch.Color pieceColor;

  PieceMoveData({
    required this.squareName,
    required this.pieceType,
    required this.pieceColor,
  });
}

class _ArrowPainter extends CustomPainter {
  List<BoardArrow> arrows;
  PlayerColor boardOrientation;

  _ArrowPainter(this.arrows, this.boardOrientation);

  @override
  void paint(Canvas canvas, Size size) {
    var blockSize = size.width / 8;
    var halfBlockSize = size.width / 16;

    for (var arrow in arrows) {
      var startFile = files.indexOf(arrow.from[0]);
      var startRank = int.parse(arrow.from[1]) - 1;
      var endFile = files.indexOf(arrow.to[0]);
      var endRank = int.parse(arrow.to[1]) - 1;

      int effectiveRowStart = 0;
      int effectiveColumnStart = 0;
      int effectiveRowEnd = 0;
      int effectiveColumnEnd = 0;

      if (boardOrientation == PlayerColor.black) {
        effectiveColumnStart = 7 - startFile;
        effectiveColumnEnd = 7 - endFile;
        effectiveRowStart = startRank;
        effectiveRowEnd = endRank;
      } else {
        effectiveColumnStart = startFile;
        effectiveColumnEnd = endFile;
        effectiveRowStart = 7 - startRank;
        effectiveRowEnd = 7 - endRank;
      }

      var startOffset = Offset(
          ((effectiveColumnStart + 1) * blockSize) - halfBlockSize,
          ((effectiveRowStart + 1) * blockSize) - halfBlockSize);
      var endOffset = Offset(
          ((effectiveColumnEnd + 1) * blockSize) - halfBlockSize,
          ((effectiveRowEnd + 1) * blockSize) - halfBlockSize);

      var yDist = 0.8 * (endOffset.dy - startOffset.dy);
      var xDist = 0.8 * (endOffset.dx - startOffset.dx);

      var paint = Paint()
        ..strokeWidth = halfBlockSize * 0.8
        ..color = arrow.color;

      canvas.drawLine(startOffset,
          Offset(startOffset.dx + xDist, startOffset.dy + yDist), paint);

      var slope =
          (endOffset.dy - startOffset.dy) / (endOffset.dx - startOffset.dx);

      var newLineSlope = -1 / slope;

      var points = _getNewPoints(
          Offset(startOffset.dx + xDist, startOffset.dy + yDist),
          newLineSlope,
          halfBlockSize);
      var newPoint1 = points[0];
      var newPoint2 = points[1];

      var path = Path();

      path.moveTo(endOffset.dx, endOffset.dy);
      path.lineTo(newPoint1.dx, newPoint1.dy);
      path.lineTo(newPoint2.dx, newPoint2.dy);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  List<Offset> _getNewPoints(Offset start, double slope, double length) {
    if (slope == double.infinity || slope == double.negativeInfinity) {
      return [
        Offset(start.dx, start.dy + length),
        Offset(start.dx, start.dy - length)
      ];
    }

    return [
      Offset(start.dx + (length / sqrt(1 + (slope * slope))),
          start.dy + ((length * slope) / sqrt(1 + (slope * slope)))),
      Offset(start.dx - (length / sqrt(1 + (slope * slope))),
          start.dy - ((length * slope) / sqrt(1 + (slope * slope)))),
    ];
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) {
    return arrows != oldDelegate.arrows;
  }
}
