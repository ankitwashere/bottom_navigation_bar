import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:developer' as dev show log;
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

extension Log on Object {
  void log() => dev.log(toString());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // void _onTapped(int index) {}
  final ValueNotifier<int> _selectedIndex = ValueNotifier(0);
  final ValueNotifier<bool> _hideBottomNavBar = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bottom Nav Bar")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _hideBottomNavBar.value = !_hideBottomNavBar.value;
          },
          child: const Text("Toogle Bottom Nav Bar"),
        ),
      ),
      bottomNavigationBar: ValueListenableBuilder<int>(
          valueListenable: _selectedIndex,
          builder: (context, sI, _) {
            return NavBar(
              onItemTapped: (index) {
                _selectedIndex.value = index;
              },
              selectedItemColor: Colors.white,
              backgroundColor: Colors.blue,
              height: kBottomNavigationBarHeight + 10,
              items: [
                NavBarItemModel("Home", Icons.home),
                NavBarItemModel("Search", Icons.search),
                NavBarItemModel("Shorts", Icons.video_collection_sharp),
                NavBarItemModel("Explore", Icons.explore),
                NavBarItemModel("Shop", Icons.shop),
              ],
              selectedIndex: sI,
            );
          }),
    );
  }
}

class NavBarItemModel {
  final String text;
  final IconData iconData;

  NavBarItemModel(this.text, this.iconData);
}

class NavBar extends StatefulWidget {
  final Color? backgroundColor;
  final double height;
  final List<NavBarItemModel> items;
  final Function(int) onItemTapped;
  final int selectedIndex;
  final Color selectedItemColor;
  final Color? unSelectedItemColor;
  const NavBar({
    super.key,
    this.backgroundColor,
    required this.height,
    required this.items,
    required this.onItemTapped,
    required this.selectedIndex,
    required this.selectedItemColor,
    this.unSelectedItemColor,
  }) : assert(items.length >= 2);
  // assert(height >= 70 && height <= 100);

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  List<GlobalKey> keys = [];
  List<double> offsets = [];
  Offset _topOffset = Offset.zero;
  Size _topSize = const Size.fromHeight(0);

  late ValueNotifier<bool> _buildTop;

  @override
  void initState() {
    super.initState();
    _buildTop = ValueNotifier(false);
    double val = -1 * (widget.items.length / 2 - .5);
    for (int i = 0; i < widget.items.length; i++) {
      keys.add(GlobalKey());
      offsets.add(val++);
    }
    offsets.log();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // calculate top offset and top size here
      final rBox = keys[widget.selectedIndex].currentContext?.findRenderObject() as RenderBox;
      _topOffset = rBox.localToGlobal(Offset.zero);
      _topSize = rBox.size;
      _buildTop.value = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ?? Theme.of(context).bottomAppBarColor;
    return AnimatedContainer(
      decoration: BoxDecoration(color: bg),
      duration: const Duration(milliseconds: 300),
      height:  widget.height,
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // animated slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: widget.items.map((item) {
              int index = widget.items.indexOf(item);
              return Expanded(
                child: GestureDetector(
                  key: keys[index],
                  onTap: () {
                    final rBox = keys[index].currentContext?.findRenderObject() as RenderBox;
                    _topOffset = rBox.localToGlobal(Offset.zero);
                    _topSize = rBox.size;
                    widget.onItemTapped(index);
                  },
                  child: NavBarItem(
                    isSelected: index == widget.selectedIndex,
                    model: item,
                    color: index == widget.selectedIndex ? widget.selectedItemColor : Colors.white,
                  ),
                ),
              );
            }).toList(),
          ),
          ValueListenableBuilder<bool>(
              valueListenable: _buildTop,
              builder: (context, value, _) {
                return value
                    ? AnimatedSlide(
                        offset: Offset(offsets[widget.selectedIndex], 0.0),
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          decoration: CustomBoxDecoration(),
                          // decoration: BoxDecoration(
                          //   borderRadius: BorderRadius.circular(10),
                          //   color: Colors.amber,
                          // ),
                          transform: Matrix4.identity()..translate(0.0,-10.0),
                          height: 5,
                          width: _topSize.width,
                        ),
                      )
                    : const SizedBox();
              }),
        ],
      ),
    );
  }
}

class NavBarItem extends StatelessWidget {
  final bool isSelected;
  final NavBarItemModel model;
  final Color color;
  const NavBarItem({super.key, required this.isSelected, required this.model, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSlide(
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            offset: isSelected ? const Offset(0.0, -0.18) : Offset.zero,
            child: Icon(
              model.iconData,
              color: color,
              size: 30,
            ),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 100),
            opacity: !isSelected ? 1 : 0,
            child: Transform.translate(
              offset: const Offset(0.0, 0.0),
              child: Text(
                model.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomBoxDecoration extends Decoration {
  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _CustomDecorationPainter();
}

class _CustomDecorationPainter extends BoxPainter {
  final _paint = Paint()
    ..color = Colors.amber
    ..style = PaintingStyle.fill;
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final workingWidth = configuration.size!.width / 2;
    // Vertices vert = Vertices(VertexMode.triangleFan, [
    //   offset + Offset(workingWidth - 15, 0.0),
    //   offset + Offset(workingWidth + 15, 0.0),
    //   offset + Offset(workingWidth, 7),
    // ]);
    // canvas.drawVertices(vert, BlendMode.darken, _paint);
    canvas.drawCircle(offset + Offset(workingWidth,0.0), 5, _paint);
  }
}
