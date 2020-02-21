import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:core';
import 'package:shared_preferences/shared_preferences.dart';

storeSum(int index,summaryBody) async{
  final prefs = await SharedPreferences.getInstance();
  prefs.setInt('LastIndex', index);
  prefs.setString('$index', summaryBody);
}

Future<int> getLastIndex() async{
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('LastIndex') ?? -1;
}

class Summary{
  Color sumColorG = Colors.white;
  Color sumColorB = Colors.white;
  double fontS = 28.0;
  double pad = 12.0;
  int score = 0;
  String date = DateTime.now().year.toString() + '/' + DateTime.now().month.toString() + '/' + DateTime.now().day.toString();

  var pts = [
    false, //'feet not far apart'
    false, //'back tilted too much when knees bent'
    false, //'hand below shoulder when knees bent'
    false, //'elbow close to side of body'
    false, //'ball close to body when knees bent'

    false, //'back staright in air'
    false, //'arms extended in shot'
    false, //'hand at forehead before shot'
    false, //'shot arc high'
  ];

  setScore(){
    var count = 0;
    for(var i = 0;i < pts.length; i ++){
      if(pts[i]){
        count++;
      }
    }
    score = 100 * count~/(pts.length);
  }

  List<Widget> genSum(){
    List<String> bad = List();
    List<Widget> b = <Widget>[];
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
}

class Analysis extends StatefulWidget{
  final List data;
  final bool domR;
  Analysis(this.data,this.domR);

  @override
  _AnalysisState createState() => new _AnalysisState();
}

class _AnalysisState extends State<Analysis>{

  //doesnt always calculate correct angle
  double g(p1,p2){
    return ((p1[1]-p2[1])/(p1[0]-p2[0])).abs();
  }

  double angle(List p1,List p2,List p3){
    var first = p1[1]-p2[1];
    var sec = p3[1]-p2[1];
    var third = p3[0]-p2[0];
    var forth = p1[0]-p2[0];
    var theta1 = math.atan(g(p1,p2)) * (180/math.pi);
    var theta2 = math.atan(g(p3,p2)) * (180/math.pi);
        

    if(first<0){
      if(sec<0){
        //2
        return 180-theta1-theta2;
      }else{
        if(forth<0){
          //1
          return theta1 + theta2;
        }else{
          //4
          return theta1+theta2;
        }
      }
    }else{
      if(third<0){
        //3
        return theta1 + theta2;
      }else{
        //5
        return theta1 + 180 - theta2;
      }
    }
  }

  double distance(List p1,List p2){
    var d = math.pow((math.pow((p1[1]-p2[1]),2) + math.pow((p1[0]-p2[0]),2)),0.5);

    return d;
  }

  List limbAngles(pose,domR){
    if(domR){
      var rLeg = angle(pose[11],pose[10],pose[9]);
      var rArm = angle(pose[14],pose[13],pose[12]);
      return [rLeg,rArm];
    }else{
      var lLeg = angle(pose[3],pose[2],pose[1]);
      var lArm = angle(pose[6],pose[5],pose[4]);
      return [lLeg,lArm];
    }
  }

  double back(pose,domR){
    if(domR){
      var rightSW = g(pose[14],pose[11]);
      return rightSW;
    }else{
      var leftSW = g(pose[6],pose[3]);
      return leftSW;
    }
  }
  
  analyse(data,domR){

    Summary summary = new Summary();
    var limb = List(2);
    var backGrad;
    var handToShoulderY;
    bool elbowBetSH = false;
    var handToShoulderX;
    var ankleD = 0.0;
    var start = 0;

    //remove poses without full body
    for(var i = 0;i < data.length; i ++){
      var count = 0;
      for(var d in data[i]){
        if(d[2] < 0.2){
          count ++;
        }
      }
      if(count > 6){
        data.removeAt(i);
        i = i-1;
      } 
    }

    //find index where legs bent at 140 degrees
    for(var i = 0;i < data.length;i ++){
      limb = limbAngles(data[i], domR);
      if(limb[0] < 130){
        start = i;

        ankleD = distance(data[i][1],data[i][9]);
        backGrad = back(data[i],domR);
        print(backGrad);
        if(domR){
          handToShoulderY = (data[i][12][1]-data[i][14][1]);
          handToShoulderX = (data[i][12][0]-data[i][14][0]).abs();
          if(data[i][13][0]<data[i][11][0] && data[i][13][0] > data[i][14][0]){
            elbowBetSH = true;
          }else{
            elbowBetSH = false;
          }
        }else{
          handToShoulderY = (data[i][4][1]-data[i][6][1]);
          handToShoulderX = (data[i][4][0]-data[i][6][0]).abs();
          if(data[i][5][0]>data[i][3][0] && data[i][3][0] < data[i][6][0]){
            elbowBetSH = true;
          }else{
            elbowBetSH = false;
          }
        }

        if(ankleD < 0.1){
          summary.pts[0] = true;
        }
        if(backGrad > 1){
          summary.pts[1] = true;
        }
        if(handToShoulderY > 0){
          summary.pts[2] = true;
        }
        if(elbowBetSH){
          summary.pts[3] = true;
        }
        if(handToShoulderX < 0.1){
          summary.pts[4] = true;
        }
        break;
      }
    }
    if(start != 0){
      data = data.sublist(start,);
    }else{
      data = [];
    }
    var armsMaxAngle = 0.0;
    var backMax = 0.0;
    var arc = 0.0;
    
    bool arcHigh = false;
    bool handToH = false;
    
    for(var i = 0;i < data.length;i ++){
      limb = limbAngles(data[i],domR);
      if(limb[1] > armsMaxAngle){
        if(domR && data[i][12][1]<data[i][13][1]){
          
          armsMaxAngle = limb[1];
        }else{
          if(!domR && data[i][4][1]<data[i][5][1]){
            armsMaxAngle = limb[1];
          }
        }
      }
      
      if((domR && limb[1] == armsMaxAngle) || (!domR && limb[1] == armsMaxAngle)){
        if(domR){
          arc = math.atan(((data[i][14][1]-data[i][13][1])/(data[i][13][0]-data[i][14][0])).abs());
          arc = arc / math.pi * 180;
        }else{
          arc = math.atan(((data[i][6][1]-data[i][5][1])/(data[i][5][0]-data[i][6][0])).abs());
          arc = arc / math.pi * 180;
        }
        if(arc>45){
          arcHigh = true;
        }
      }
      

      backGrad = back(data[i],domR);
      if(backGrad>backMax && limb[1] == armsMaxAngle){
        backMax = backGrad;
      }

      if((distance(data[i][12],data[i][16]) < 0.1) && domR){
        handToH = true;
      }else if((distance(data[i][4],data[i][8]) < 0.1) && !domR){
        handToH = true;
      }
    }

    if(armsMaxAngle > 150){
      summary.pts[6] = true;  
    }
    if(backMax > 20){
      summary.pts[5] = true;
    }
    if(handToH){
      summary.pts[7] = true;
    }
    if(arcHigh){
      summary.pts[8] = true;
    }

    summary.setScore();

    return summary;
  }
  

  @override
  Widget build(BuildContext context){
    Summary sum = analyse(widget.data,widget.domR);
    bool saved = false;
    var sumBody = {};
    sumBody['date'] = sum.date.toString();
    sumBody['score'] = sum.score.toString();
    sumBody['pts'] = sum.pts.toString();

    List<Widget> b;
    b = sum.genSum();
    var score = sum.score;

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
                child:Text('$score',style:TextStyle(fontSize:60.0,color:Colors.black,fontWeight: FontWeight.w700))
              ),
            )
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
            bottom:0,
            right:0,
            child:
              FlatButton(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft:Radius.circular(20.0))),
                color: Color.fromRGBO(250, 87, 0, 1.0),
                child:Row(
                  children: <Widget>[
                    Text('Save',style: TextStyle(color:Colors.white,fontSize:40,fontWeight:FontWeight.w500,fontStyle: FontStyle.italic)),
                    Icon(Icons.save_alt,color: Colors.white,)
                  ],
                ),
                onPressed: () async{
                  if(!saved){
                    int lastIndex = await getLastIndex();
                    String summary = json.encode(sumBody);
                    await storeSum(lastIndex+1,summary);
                    saved = true;
                  }
                },
              )
          )
          
        ]
      )
    );
  }
}