import 'package:flutter/material.dart';
import 'design.dart';
import 'model.dart';
export 'coach.dart';

class ScreenHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Widget? trailing;
  const ScreenHeader({super.key,required this.title,required this.onBack,this.trailing});
  @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.fromLTRB(12,8,16,8),
    child:Row(children:[IconButton(tooltip:'Back',onPressed:onBack,icon:const Icon(Icons.arrow_back_rounded,size:22)),
      const SizedBox(width:4),Expanded(child:Text(title,style:Theme.of(context).textTheme.titleMedium)),
      ?trailing]));
}

class HomeScreen extends StatelessWidget {
  final ExecutionModel model;
  const HomeScreen({super.key,required this.model});
  @override Widget build(BuildContext context) {
    final c=AstraColors.of(context), text=Theme.of(context).textTheme;
    final task=model.active;
    return ListView(padding:const EdgeInsets.fromLTRB(24,12,24,20),children:[
      Row(children:[const StarMark(size:27),const SizedBox(width:9),Text('astra',style:TextStyle(fontSize:28,fontWeight:FontWeight.w600,letterSpacing:-1.4,color:c.ink)),
        const Spacer(),IconButton(key:const Key('theme-toggle'),tooltip:model.dark?'Use light theme':'Use dark theme',
          onPressed:model.toggleTheme,icon:Icon(model.dark?Icons.light_mode_outlined:Icons.dark_mode_outlined,size:21))]),
      const SizedBox(height:30),const Eyebrow('A little focus. A real step forward.'),const SizedBox(height:10),
      Text('Start where\nyou are.',style:TextStyle(fontFamily:'Newsreader',fontSize:46,height:1.02,letterSpacing:-1.3,color:c.ink)),
      const SizedBox(height:15),Text(task==null?'Choose one thing. The rest can wait.':'Your next step is already here.',style:text.bodyLarge?.copyWith(color:c.muted)),
      const SizedBox(height:26),
      if(task!=null) Surface(color:c.wash,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[Icon(Icons.bookmark_outline_rounded,size:16,color:c.accent),const SizedBox(width:8),Eyebrow('Ready to resume',color:c.accent)]),
        const SizedBox(height:14),Text(task.title,style:text.titleLarge),const SizedBox(height:16),
        OutcomeBar(task.verified,task.milestones.length),const SizedBox(height:8),
        Text('${task.verified} of ${task.milestones.length} outcomes verified',style:text.bodyMedium?.copyWith(fontSize:12)),
        const SizedBox(height:22),const Eyebrow('Your next action'),const SizedBox(height:7),
        Text(task.nextAction,style:text.titleMedium?.copyWith(fontSize:19,height:1.45)),const SizedBox(height:21),
        PrimaryButton('Resume focus',key:const Key('resume-focus'),onPressed:()=>model.resume(task)),
      ]))
      else ...[
        for(final t in model.available.take(3)) TaskRow(task:t,onTap:()=>model.resume(t)),
        if(model.available.isEmpty) Surface(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Icon(Icons.check_circle_outline,color:c.green),const SizedBox(height:10),Text('Everything you chose is done.',style:text.titleLarge),
          const SizedBox(height:8),const Text('Capture something new whenever you’re ready.')]))
      ],
      const SizedBox(height:6),
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
        if(task!=null) TextButton(onPressed:()=>model.preview(task),child:const Text('Where was I?')),
        TextButton(onPressed:()=>model.go(AppPage.recovery),child:const Row(mainAxisSize:MainAxisSize.min,children:[Text('Switch task'),SizedBox(width:6),Icon(Icons.swap_horiz_rounded,size:18)])),
      ]),
      const SizedBox(height:16),InkWell(key:const Key('capture-task'),borderRadius:BorderRadius.circular(18),
        onTap:()=>captureTask(context,model),child:Container(padding:const EdgeInsets.symmetric(horizontal:16,vertical:17),
          decoration:BoxDecoration(border:Border.all(color:c.line),borderRadius:BorderRadius.circular(18)),
          child:Row(children:[Icon(Icons.add_rounded,color:c.accent),const SizedBox(width:12),Expanded(child:Text('Get a task out of your head',style:text.bodyMedium))]))),
    ]);
  }
}

Future<void> captureTask(BuildContext context,ExecutionModel model) async {
  final controller=TextEditingController();
  await showModalBottomSheet<void>(context:context,isScrollControlled:true,builder:(ctx)=>Padding(
    padding:EdgeInsets.fromLTRB(24,0,24,24+MediaQuery.viewInsetsOf(ctx).bottom),
    child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text('Put it down. Come back later.',style:Theme.of(ctx).textTheme.headlineMedium),const SizedBox(height:12),
      const Text('A few words are enough. Your current task stays right where it is.'),const SizedBox(height:20),
      TextField(key:const Key('capture-input'),controller:controller,autofocus:true,maxLength:120,
        textCapitalization:TextCapitalization.sentences,decoration:const InputDecoration(labelText:'What needs doing?')),
      const SizedBox(height:16),PrimaryButton('Save for later',onPressed:(){
        if(controller.text.trim().isEmpty) { return; }
        model.addTask(controller.text);Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Saved. Your current focus hasn’t changed.')));
      },icon:Icons.add_rounded),
    ]))));
  // The sheet can still be animating out when its future completes.
  await Future<void>.delayed(const Duration(milliseconds:300));
  controller.dispose();
}

class FocusScreen extends StatelessWidget {
  final ExecutionModel model;
  const FocusScreen({super.key,required this.model});
  @override Widget build(BuildContext context) {
    final c=AstraColors.of(context), text=Theme.of(context).textTheme;
    final t=model.selected;
    return Column(children:[
      ScreenHeader(title:'Your focus',onBack:()=>model.go(AppPage.home),trailing:TextButton(
        key:const Key('switch-task'),onPressed:()=>model.go(AppPage.recovery),child:const Text('Switch task'))),
      Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(24,4,24,16),children:[
        Text(t.title,style:text.bodyMedium),const SizedBox(height:16),
        ViewTabs(selected:0,onChange:(i){if(i>0) {model.openRoadmap(milestone:i==1);}}),
        const SizedBox(height:24),Row(children:[Icon(Icons.verified_outlined,color:c.green,size:16),const SizedBox(width:7),
          Flexible(child:Text('${t.verified} of ${t.milestones.length} outcomes verified',style:text.bodyMedium?.copyWith(color:c.green,fontSize:12)))]),
        const SizedBox(height:10),Text(t.milestone.title,style:text.titleMedium),const SizedBox(height:18),const Divider(),
        const SizedBox(height:27),
        if(t.finished) ...[
          Eyebrow('Outcome achieved',color:c.green),const SizedBox(height:14),Text('This is a real\nstep forward.',style:text.headlineLarge),
          const SizedBox(height:18),Text(t.milestone.evidence,style:text.bodyLarge),
        ] else if(t.awaitingVerification) ...[
          Eyebrow('One final check',color:c.accent),const SizedBox(height:14),Text('Does the result\nmatch?',style:text.headlineLarge),
          const SizedBox(height:20),Surface(color:c.greenWash,child:Text(t.milestone.evidence,style:text.titleMedium)),
          const SizedBox(height:16),const Text('Only you can confirm this outcome. Finishing instructions alone doesn’t verify it.'),
        ] else ...[
          Row(children:[Expanded(child:Eyebrow('Just this next action',color:c.accent)),const SizedBox(width:8),StarMark(size:18,color:c.accent)]),
          const SizedBox(height:16),AnimatedSwitcher(duration:MediaQuery.disableAnimationsOf(context)?Duration.zero:const Duration(milliseconds:160),
            child:Align(key:ValueKey(t.nextAction),alignment:Alignment.centerLeft,child:Text(t.nextAction,style:text.headlineLarge))),
          const SizedBox(height:20),Text(t.instruction(),style:text.bodyLarge?.copyWith(color:c.muted)),
          const SizedBox(height:26),const Eyebrow('Instruction detail'),const SizedBox(height:8),
          ViewTabs(selected:t.detail.index,labels:const ['Micro','Normal','High-level'],onChange:(i)=>model.setDetail(Detail.values[i])),
        ],
      ])),
      Padding(padding:const EdgeInsets.fromLTRB(24,8,24,14),child:Column(children:[
        if(t.finished) PrimaryButton('Choose what’s next',onPressed:()=>model.go(AppPage.home))
        else if(t.awaitingVerification) ...[
          PrimaryButton('Yes, verify outcome',key:const Key('verify-outcome'),onPressed:(){model.verifyOutcome();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Outcome verified. Your roadmap has moved forward.')));},icon:Icons.check_rounded),
          TextButton(onPressed:model.retryOutcome,child:const Text('Not yet · return to the action')),
        ] else ...[
          PrimaryButton('Action completed',key:const Key('complete-action'),onPressed:model.completeAction,icon:Icons.check_rounded),
          const SizedBox(height:8),Row(children:[Expanded(child:TextButton.icon(key:const Key('stuck'),onPressed:()=>model.openCoach(stuck:true),
            icon:const Icon(Icons.help_outline_rounded,size:18),label:const Text('I’m stuck'))),
            Container(height:20,width:1,color:c.line),Expanded(child:TextButton.icon(onPressed:()=>model.openCoach(),
              icon:const Icon(Icons.auto_awesome_outlined,size:18),label:const Text('Ask AI')))]),
        ],
      ])),
    ]);
  }
}

class RoadmapScreen extends StatelessWidget {
  final ExecutionModel model;
  const RoadmapScreen({super.key,required this.model});
  @override Widget build(BuildContext context) {
    final c=AstraColors.of(context),text=Theme.of(context).textTheme,t=model.selected;
    return Column(children:[ScreenHeader(title:'The bigger picture',onBack:()=>model.go(AppPage.home)),
      Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(24,4,24,24),children:[
        Text(t.title,style:text.bodyMedium),const SizedBox(height:16),
        ViewTabs(selected:model.milestoneView?1:2,onChange:(i){if(i==0){model.resume(t);}else{model.openRoadmap(milestone:i==1);}}),
        const SizedBox(height:28),
        if(model.milestoneView) ...[
          Eyebrow(t.finished?'Verified outcome':'Current milestone',color:c.accent),const SizedBox(height:10),Text(t.milestone.title,style:text.headlineMedium),
          const SizedBox(height:22),Surface(color:c.greenWash,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Eyebrow('What done looks like',color:c.green),const SizedBox(height:10),Text(t.milestone.evidence,style:text.titleMedium)])),
          const SizedBox(height:24),const Eyebrow('Actions toward this outcome'),const SizedBox(height:10),
          ...List.generate(t.steps.length,(i)=>Padding(padding:const EdgeInsets.symmetric(vertical:12),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Icon(i<t.actionIndex||t.awaitingVerification||t.finished?Icons.check_circle_outline:i==t.actionIndex?Icons.radio_button_checked:Icons.radio_button_unchecked,
              color:i==t.actionIndex?c.accent:c.muted,size:20),const SizedBox(width:12),Expanded(child:Text(t.steps[i].title,style:text.bodyLarge?.copyWith(fontSize:15)))]))),
          const SizedBox(height:12),const Text('Actions help you get there. Only a confirmed outcome changes project progress.'),
        ] else ...[
          Row(children:[OutcomeRing(t.verified,t.milestones.length),const SizedBox(width:22),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text('Real progress.',style:TextStyle(fontFamily:'Newsreader',fontSize:30,height:1.1,color:c.ink)),const SizedBox(height:7),
            Text('${t.verified} outcomes verified\n${t.milestones.length-t.verified} still ahead',style:text.bodyMedium)]))]),
          const SizedBox(height:30),const Eyebrow('Your path to done'),const SizedBox(height:18),
          ...List.generate(t.milestones.length,(i)=>_milestone(context,t,i)),
          const SizedBox(height:12),Text('Future milestones stay high-level. We’ll work out the actions when you get there.',style:text.bodyMedium),
        ],
      ])),
      Padding(padding:const EdgeInsets.fromLTRB(24,8,24,20),child:PrimaryButton(t.finished?'Back to today':'Back to the next action',
        onPressed:()=>t.finished?model.go(AppPage.home):model.resume(t))),
    ]);
  }
  Widget _milestone(BuildContext context,WorkTask t,int i) {
    final c=AstraColors.of(context),text=Theme.of(context).textTheme;
    final done=i<t.verified,current=i==t.verified;
    return IntrinsicHeight(child:Row(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      SizedBox(width:30,child:Column(children:[Container(width:28,height:28,
        decoration:BoxDecoration(color:done?c.greenWash:current?c.accent:Colors.transparent,shape:BoxShape.circle,border:Border.all(color:done?c.greenWash:current?c.accent:c.line)),
        child:Center(child:done?Icon(Icons.check_rounded,size:16,color:c.green):Text('${i+1}',style:TextStyle(fontSize:12,fontWeight:FontWeight.w700,color:current?c.onAccent:c.muted)))),
        if(i<t.milestones.length-1) Expanded(child:Container(width:1,margin:const EdgeInsets.symmetric(vertical:5),color:c.line)),
      ])),const SizedBox(width:14),Expanded(child:Padding(padding:const EdgeInsets.only(bottom:22),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(t.milestones[i].title,style:text.titleMedium?.copyWith(color:current?c.accent:c.ink,fontSize:15)),
        const SizedBox(height:4),Text(done?'Verified by you':current?'Current milestone':'Ahead',style:text.bodyMedium?.copyWith(fontSize:12,color:done?c.green:c.muted)),
        if(done) InkWell(onTap:()=>showModalBottomSheet<void>(context:context,builder:(ctx)=>Padding(padding:const EdgeInsets.fromLTRB(24,0,24,32),
          child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[Eyebrow('Verified outcome',color:c.green),const SizedBox(height:12),Text(t.milestones[i].evidence,style:text.titleLarge)]))),
          child:const Padding(padding:EdgeInsets.symmetric(vertical:15),child:Text('View evidence',style:TextStyle(fontSize:12,decoration:TextDecoration.underline)))),
      ]))),
    ]));
  }
}

class RecoveryScreen extends StatelessWidget {
  final ExecutionModel model;
  const RecoveryScreen({super.key,required this.model});
  @override Widget build(BuildContext context) {
    final c=AstraColors.of(context),text=Theme.of(context).textTheme,t=model.selected;
    final away=DateTime.now().difference(t.lastTouched).inDays;
    return Column(children:[ScreenHeader(title:'Switch & resume',onBack:()=>model.go(AppPage.home)),
      Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(24,8,24,16),children:[
        Text('Your place\nis still here.',style:TextStyle(fontFamily:'Newsreader',fontSize:40,height:1.05,letterSpacing:-.8,color:c.ink)),
        const SizedBox(height:12),Text('Change direction without starting over.',style:text.bodyMedium),const SizedBox(height:24),
        Surface(color:c.wash,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[Icon(Icons.history_rounded,color:c.accent,size:18),const SizedBox(width:8),
            Expanded(child:Eyebrow(away>=14?'After two weeks away':t.visited?'Your saved place':'Ready when you are',color:c.accent))]),
          const SizedBox(height:14),Text(t.title,style:text.titleLarge),const SizedBox(height:12),
          Text(t.resumeContext,style:text.bodyMedium),
          if(t.blocker.isNotEmpty) ...[const SizedBox(height:12),Text('Last blocker: ${t.blocker}',style:text.bodyMedium?.copyWith(color:c.ink))],
          const SizedBox(height:18),Divider(color:c.accent.withValues(alpha:.2)),const SizedBox(height:16),
          const Eyebrow('Pick up right here'),const SizedBox(height:8),Text(t.nextAction,style:text.titleMedium),
          const SizedBox(height:20),PrimaryButton(t.visited?'Resume this task':'Start this task',key:const Key('resume-selected'),onPressed:()=>model.resume(t)),
        ])),
        const SizedBox(height:22),const Eyebrow('Or choose a different task'),const SizedBox(height:8),
        for(final other in model.available.where((x)=>x.id!=t.id).take(2)) TaskRow(task:other,
          onTap:()=>model.resume(other),onPreview:()=>model.preview(other)),
        if(model.available.length>3) TextButton(onPressed:()=>showModalBottomSheet<void>(context:context,isScrollControlled:true,
          builder:(ctx)=>SafeArea(child:SizedBox(height:MediaQuery.sizeOf(ctx).height*.65,child:ListView(padding:const EdgeInsets.all(24),children:[
            Text('Your captured tasks',style:text.headlineMedium),const SizedBox(height:20),
            for(final other in model.available) TaskRow(task:other,onTap:(){Navigator.pop(ctx);model.resume(other);}),
          ])))),child:const Text('See captured tasks')),
        if(t.history.isNotEmpty) TextButton(onPressed:()=>showModalBottomSheet<void>(context:context,isScrollControlled:true,
          builder:(ctx)=>SafeArea(child:SizedBox(height:MediaQuery.sizeOf(ctx).height*.6,child:ListView(padding:const EdgeInsets.all(24),children:[
            Text('Project memory',style:text.headlineMedium),const SizedBox(height:8),const Text('Kept on this device.'),const SizedBox(height:16),
            for(final entry in t.history) Padding(padding:const EdgeInsets.symmetric(vertical:10),child:Text(entry,style:text.bodyLarge)),
          ])))),child:const Text('View project memory')),
      ])),
    ]);
  }
}

class TaskRow extends StatelessWidget {
  final WorkTask task;
  final VoidCallback onTap;
  final VoidCallback? onPreview;
  const TaskRow({super.key,required this.task,required this.onTap,this.onPreview});
  @override Widget build(BuildContext context) {
    final c=AstraColors.of(context),text=Theme.of(context).textTheme;
    return Container(decoration:BoxDecoration(border:Border(bottom:BorderSide(color:c.line))),
      child:Row(children:[Expanded(child:InkWell(onTap:onTap,child:Padding(padding:const EdgeInsets.symmetric(vertical:17),
        child:Row(children:[Container(width:42,height:42,decoration:BoxDecoration(color:c.surface,borderRadius:BorderRadius.circular(13)),
          child:Icon(task.id=='indicator'?Icons.show_chart_rounded:task.id=='application'?Icons.description_outlined:task.id=='bulb'?Icons.lightbulb_outline:Icons.inbox_outlined,size:21,color:c.accent)),
          const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(task.title,style:text.titleMedium?.copyWith(fontSize:14)),
            const SizedBox(height:4),Text(task.visited?'Resume saved action':task.category,style:text.bodyMedium?.copyWith(fontSize:12))])),
          const SizedBox(width:8),Icon(Icons.arrow_forward_rounded,size:18,color:c.muted)])))),
        if(onPreview!=null) IconButton(tooltip:'Context for ${task.title}',onPressed:onPreview,icon:Icon(Icons.history_rounded,size:20,color:c.muted)),
      ]));
  }
}
