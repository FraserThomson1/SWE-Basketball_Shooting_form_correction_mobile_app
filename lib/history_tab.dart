import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

bool altered = false;
List<String> sUMS;
List listItems = [];

deleteRecord(index) async{
  final prefs = await SharedPreferences.getInstance();
  var last = prefs.getInt('LastIndex');
  var sum;
  var j;
  for(int i = index;i < last;i ++){
    j = i + 1;
    sum = prefs.getString('$j');
    prefs.setString('$i',sum);
  }
  if(last > -1){
    prefs.setInt('LastIndex', (last-1));
  }
}

getList()async{
  final prefs = await SharedPreferences.getInstance();
  int last = prefs.getInt('LastIndex');
  List<String> sums = List(last+1);
  for(int i = 0;i < last+1;i ++){
    sums[i] = prefs.getString('$i');
  }
  return sums;
}

List<Widget> genSum(pts){
  List<String> bad = List();
  List<Widget> b = <Widget>[];
  pts = json.decode(pts);
  if(!pts[0]){
      bad.add('Feet too wide apart');
  }
  if(!pts[1]){
    bad.add('Body bends over too much when bringing the ball down');
  }
  if(!pts[2]){
    bad.add('Hands should be close to chest when bringing the ball down');
  }
  if(!pts[3]){
    bad.add('Elbow should be close to side of body when shooting');
  }
  if(!pts[4]){
    bad.add('Ball should be kept close to body before the shot');
  }
  if(!pts[5]){
    bad.add('Body should be close to vertical to ground when shooting');
  }
  if(!pts[6]){
    bad.add('Extend out your arm upon release and follow through');
  }
  if(!pts[7]){
    bad.add('Ball should be released around your forehead');
  }
  if(!pts[8]){
    bad.add('Shooting arc is too low');
  }
  
  for(int i = 0;i < bad.length;i ++){
    b.add(
      Padding(
        padding: const EdgeInsets.only(left:16.0,right:16.0,top:8.0,bottom:8.0),
        child: Container(
          height:80,
          decoration: BoxDecoration(color:Colors.white,boxShadow: [BoxShadow(color:Colors.grey,spreadRadius: 5.0,blurRadius: 5.0)]),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(child:Padding(padding:EdgeInsets.all(10.0),child:Text(bad[i],style:TextStyle(color:Colors.black,fontSize: 20)))),
            ]
          )
        )
      )
    );
  }
  return b;
}

class HistoryTab extends StatefulWidget{
  final List<String> sums;

  HistoryTab(this.sums);

  @override 
  _HistoryTabState createState() => new _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab>{

  @override
  Widget build(BuildContext context){
    listItems = [];
    if(!altered){sUMS = widget.sums;}
    List<Widget> listSums = List(sUMS.length);

    var sum;
    var date;
    var score;
    var pts;

    for(int i = sUMS.length-1;i > -1;i --){

      sum = json.decode(sUMS[i]);
      date = sum['date'];
      score = sum['score'];
      pts = sum['pts'];

      listItems.add([score,pts]);
      listSums[sUMS.length-1-i] = Padding(
        padding: const EdgeInsets.only(top:12.0,bottom:12.0,right:5.0,left:3.0),
        child: FlatButton(
                child: Container(
                  height:100,
                  decoration: BoxDecoration(color:Colors.white,boxShadow: [BoxShadow(color:Color.fromRGBO(250, 87, 0, 1.0),spreadRadius: 5.0,blurRadius: 5.0)]),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(child:Padding(padding:EdgeInsets.all(20.0),child:Text(score,style:TextStyle(color:Colors.black,fontSize: 50)))),
                      Expanded(child:Padding(padding:EdgeInsets.all(10.0),child:Text(date,style: TextStyle(color:Colors.grey)))),
                      FlatButton(
                        child:
                          Icon(CupertinoIcons.delete),
                        onPressed: ()async{
                          deleteRecord(i);
                          var s;
                          await getList().then((summary){s=summary;});
                          setState(() {
                            altered = true;
                            sUMS = s;
                          });
                        },
                      )
                    ],
                  ),
                ),
                onPressed: (){
                  var scr = listItems[sUMS.length-1-i][0];
                  var pts = listItems[sUMS.length-1-i][1];
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AnalysisPage(pts,scr)));
                },
              ),
        );
    }
    
    return Scaffold(
      backgroundColor: Color.fromRGBO(153, 204, 255, 1.0),
      body:
          Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(top:90.0),
                child:ListView(
                  children: listSums,
                ),
              ),
                    
              
              Positioned(
                top: 10,
                right: 0,
                child: SafeArea(
                  child: Container(
                    alignment: Alignment.center,
                    height: 60,
                    width: 190,
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(250, 87, 0, 1.0),
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(30.0)),
                    ),
                    child: Text('History',style: TextStyle(color: Colors.white,fontStyle: FontStyle.italic,fontSize: 50, fontWeight: FontWeight.w500,))
                  ),
                ),
              ),

              Positioned(
                bottom: 0,
                left: 0,
                child: FlatButton(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(30.0))),
                  color: Color.fromRGBO(250, 87, 0, 1.0),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.subdirectory_arrow_left,color:Colors.white),
                      Text('AI',style: TextStyle(color: Colors.white,fontStyle: FontStyle.italic,fontSize: 50, fontWeight: FontWeight.w500,)),
                    ],
                  ),
                  onPressed: (){
                    altered = false;
                    Navigator.pop(context);
                  },
                ),
              ),
            ]
          ),
    );
  }
}

class AnalysisPage extends StatefulWidget{
  final pts;
  final score;

  AnalysisPage(this.pts,this.score);

  _AnalysisPageState createState() => new _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage>{
  @override 
  Widget build(BuildContext context){
    var b = genSum(widget.pts);
    return Scaffold(
      backgroundColor: Color.fromRGBO(153, 204, 255, 1.0),
      body: Stack(
        children:[
          
          Padding(
            padding: EdgeInsets.only(top:(MediaQuery.of(context).size.height*7/20)),
            child: Padding(padding:EdgeInsets.all(16.0),child:Text('Improvements Needed:',style: TextStyle(fontSize:30,fontStyle:FontStyle.italic,color:Colors.white),)),
          ),

          Padding(
            padding: EdgeInsets.only(top: (MediaQuery.of(context).size.height*7/20+60),bottom:60),
            child: ListView(
              children: b,
            ),  
          ),

          Positioned(
            top: 100,
            left: MediaQuery.of(context).size.width*0.5-65,
            child: Container(
              height: 130,
              width: 130,
              decoration: BoxDecoration(shape: BoxShape.circle,color:Colors.white,border: Border.all(color: Colors.indigo[300],width: 6.0)),
              
              child: Center(
                child:Text(widget.score,style:TextStyle(fontSize:60.0,color:Colors.black,fontWeight: FontWeight.w700))
              ),
            )
          ),

          Positioned(
            bottom: 0,
            left: 0,
            child: FlatButton(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(20.0))),
              color: Color.fromRGBO(250, 87, 0, 1.0),
              child: Row(
                children: <Widget>[
                  Icon(Icons.subdirectory_arrow_left,color:Colors.white),
                  Text('Back',style: TextStyle(color: Colors.white,fontStyle: FontStyle.italic,fontSize: 40, fontWeight: FontWeight.w500,)),
                ],
              ),
              onPressed: (){
                Navigator.pop(context);
              },
            ),
          ),

          Positioned(
            top:0,
            right: 0,
            child: SafeArea(
              child: Container(
                alignment: Alignment.center,
                height: 60,
                width: 210,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(250, 87, 0, 1.0),
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(30.0)),
                ),
                child: Text('Analysis',style: TextStyle(color: Colors.white,fontStyle: FontStyle.italic,fontSize: 50, fontWeight: FontWeight.w500,))
              ),
            ),
          ),
        ]
      ),
    );
  }
}