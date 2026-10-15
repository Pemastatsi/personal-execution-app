import 'dart:math' as math;
import 'package:flutter/material.dart';

class AstraColors {
  final bool dark;
  const AstraColors(this.dark);
  Color get paper => Color(dark ? 0xFF18181D : 0xFFFAF8F3);
  Color get surface => Color(dark ? 0xFF24242B : 0xFFFFFFFF);
  Color get ink => Color(dark ? 0xFFF3F0E9 : 0xFF292832);
  Color get muted => Color(dark ? 0xFFB6B3C2 : 0xFF6A6677);
  Color get line => Color(dark ? 0xFF3E3C47 : 0xFFDEDAE3);
  Color get accent => Color(dark ? 0xFFC6B6FF : 0xFF6550AA);
  Color get onAccent => Color(dark ? 0xFF22183F : 0xFFFFFFFF);
  Color get wash => Color(dark ? 0xFF302B40 : 0xFFEEE8F6);
  Color get green => Color(dark ? 0xFFA7C9AF : 0xFF416B52);
  Color get greenWash => Color(dark ? 0xFF25372C : 0xFFE7EFE5);
  static AstraColors of(BuildContext c) => AstraColors(Theme.of(c).brightness == Brightness.dark);
}

ThemeData astraTheme(bool dark) {
  final c = AstraColors(dark);
  final scheme = ColorScheme.fromSeed(seedColor: c.accent,
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: c.accent, onPrimary: c.onAccent, surface: c.paper,
    onSurface: c.ink, outline: c.line);
  return ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: 'Manrope',
    scaffoldBackgroundColor: c.paper,
    textTheme: TextTheme(
      headlineLarge: TextStyle(fontSize: 36, height: 1.15, letterSpacing: -1.3, fontWeight: FontWeight.w600, color: c.ink),
      headlineMedium: TextStyle(fontSize: 28, height: 1.2, letterSpacing: -0.8, fontWeight: FontWeight.w600, color: c.ink),
      titleLarge: TextStyle(fontSize: 23, height: 1.3, letterSpacing: -0.5, fontWeight: FontWeight.w600, color: c.ink),
      titleMedium: TextStyle(fontSize: 16, height: 1.45, fontWeight: FontWeight.w600, color: c.ink),
      bodyLarge: TextStyle(fontSize: 16, height: 1.6, color: c.ink),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: c.muted),
      labelLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    ),
    dividerTheme: DividerThemeData(color: c.line, space: 1),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(
      minimumSize: const Size(48,48), foregroundColor: c.ink)),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
      minimumSize: const Size(48,56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: const TextStyle(fontFamily: 'Manrope', fontSize: 16, fontWeight: FontWeight.w700))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
      minimumSize: const Size(48,52), foregroundColor: c.ink,
      side: BorderSide(color:c.line), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(minimumSize: const Size(48,48),
      textStyle: const TextStyle(fontFamily: 'Manrope', fontSize: 14, fontWeight: FontWeight.w700))),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: c.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal:18, vertical:16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color:c.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color:c.line))),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor:c.paper, showDragHandle: true),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor:c.ink, contentTextStyle:TextStyle(color:c.paper)),
  );
}

class Eyebrow extends StatelessWidget {
  final String text;
  final Color? color;
  const Eyebrow(this.text, {super.key, this.color});
  @override Widget build(BuildContext context) => Text(text.toUpperCase(),
    style: TextStyle(fontSize: 11, height: 1.5, letterSpacing: 1.7, fontWeight: FontWeight.w800,
      color: color ?? AstraColors.of(context).muted));
}

class StarMark extends StatelessWidget {
  final double size;
  final Color? color;
  const StarMark({super.key, this.size = 28, this.color});
  @override Widget build(BuildContext context) => CustomPaint(size: Size.square(size),
    painter: _StarPainter(color ?? AstraColors.of(context).accent));
}
class _StarPainter extends CustomPainter {
  final Color color;
  _StarPainter(this.color);
  @override void paint(Canvas canvas, Size size) {
    final w=size.width, h=size.height;
    final path=Path()..moveTo(w/2,0)..cubicTo(w*.58,h*.36,w*.64,h*.42,w,h/2)
      ..cubicTo(w*.64,h*.58,w*.58,h*.64,w/2,h)
      ..cubicTo(w*.42,h*.64,w*.36,h*.58,0,h/2)
      ..cubicTo(w*.36,h*.42,w*.42,h*.36,w/2,0);
    canvas.drawPath(path,Paint()..color=color);
  }
  @override bool shouldRepaint(_StarPainter oldDelegate)=>oldDelegate.color!=color;
}

class OutcomeBar extends StatelessWidget {
  final int verified, total;
  const OutcomeBar(this.verified, this.total, {super.key});
  @override Widget build(BuildContext context) {
    final c=AstraColors.of(context);
    return Semantics(label:'$verified of $total outcomes verified', child: Row(children:List.generate(total,
      (i)=>Expanded(child: Container(height:5,margin:EdgeInsets.only(right:i==total-1?0:5),
        decoration:BoxDecoration(color:i<verified?c.green:c.line,borderRadius:BorderRadius.circular(4)))))));
  }
}

class OutcomeRing extends StatelessWidget {
  final int verified,total;
  const OutcomeRing(this.verified,this.total,{super.key});
  @override Widget build(BuildContext context) {
    final c=AstraColors.of(context);
    return Semantics(label:'$verified of $total verified outcomes', child: SizedBox.square(dimension:100,
      child:CustomPaint(painter:_RingPainter(verified,total,c),child:Center(child:Text('$verified / $total',
        style:TextStyle(fontSize:25,fontWeight:FontWeight.w600,color:c.ink,letterSpacing:-1))))));
  }
}
class _RingPainter extends CustomPainter {
  final int verified,total;
  final AstraColors c;
  _RingPainter(this.verified,this.total,this.c);
  @override void paint(Canvas canvas,Size size) {
    final rect=Rect.fromLTWH(6,6,size.width-12,size.height-12);
    final sweep=math.pi*2/total;
    for(var i=0;i<total;i++) {
      canvas.drawArc(rect,-math.pi/2+sweep*i+.06,sweep-.12,false,
        Paint()..color=i<verified?c.green:c.line..style=PaintingStyle.stroke..strokeWidth=6..strokeCap=StrokeCap.round);
    }
  }
  @override bool shouldRepaint(_RingPainter old)=>old.verified!=verified||old.c.dark!=c.dark;
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData icon;
  const PrimaryButton(this.label,{super.key,required this.onPressed,this.icon=Icons.arrow_forward_rounded});
  @override Widget build(BuildContext context) => SizedBox(width:double.infinity,
    child:FilledButton(onPressed:onPressed,child:Padding(padding:const EdgeInsets.symmetric(vertical:15),
      child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[Flexible(child:Text(label,textAlign:TextAlign.center)),
        const SizedBox(width:12),Icon(icon,size:20)]))));
}

class Surface extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsets padding;
  const Surface({super.key,required this.child,this.color,this.padding=const EdgeInsets.all(22)});
  @override Widget build(BuildContext context)=>Container(width:double.infinity,
    padding:padding,decoration:BoxDecoration(color:color??AstraColors.of(context).surface,
      borderRadius:BorderRadius.circular(24)),child:child);
}

class ViewTabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChange;
  final List<String> labels;
  const ViewTabs({super.key,required this.selected,required this.onChange,this.labels=const ['Focus','Milestone','Roadmap']});
  @override Widget build(BuildContext context) {
    final c=AstraColors.of(context);
    return Container(padding:const EdgeInsets.all(4),decoration:BoxDecoration(color:c.dark?c.surface:const Color(0xFFEFECE8),borderRadius:BorderRadius.circular(17)),
      child:Row(children:List.generate(labels.length,(i)=>Expanded(child:Semantics(selected:selected==i,
        child:TextButton(onPressed:()=>onChange(i),style:TextButton.styleFrom(
          backgroundColor:selected==i?c.surface:Colors.transparent,foregroundColor:selected==i?c.ink:c.muted,
          padding:const EdgeInsets.symmetric(horizontal:4),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(13))),
          child:Text(labels[i],style:const TextStyle(fontSize:13))))))));
  }
}
