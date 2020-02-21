import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

import 'history_tab.dart';
import 'camera.dart';
import 'keyPts.dart';

getListSum() async{
  final prefs = await SharedPreferences.getInstance();
  int last = prefs.getInt('LastIndex');
  List<String> sums = List(last+1);
  for(int i = 0;i < last+1;i ++){
    sums[i] = prefs.getString('$i');
  }
  return sums;
}

class CoachPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  CoachPage(this.cameras);
  
  @override
  _CoachPageState createState() => new _CoachPageState();
}

class _CoachPageState extends State<CoachPage> {
  List<dynamic> _recognitions;
  int _imageHeight = 0;
  int _imageWidth = 0;
  bool _paused = true;

  @override
  void initState() {
    super.initState();
  }

  setRecognitions(recognitions, imageHeight, imageWidth,paused) {
    setState(() {
      _recognitions = recognitions;
      _imageHeight = imageHeight;
      _imageWidth = imageWidth;
      _paused = paused;
    });
  }

  @override
  Widget build(BuildContext context) {

    Size screen = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body:
            Stack(
              children: [
                Camera(
                  widget.cameras,
                  setRecognitions,
                ),

                KeyPoints(
                    _recognitions == null ? [] : _recognitions,
                    math.max(_imageHeight, _imageWidth),
                    math.min(_imageHeight, _imageWidth),
                    screen.height,
                    screen.width,
                    _paused,
                ),

                Positioned(
                  top: 10,
                  left: 0,
                  child: SafeArea(
                    child: Container(
                      alignment: Alignment.center,
                      height: 60,
                      width: 90,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(250, 87, 0, 0.6),
                        borderRadius: BorderRadius.horizontal(right: Radius.circular(30.0)),
                      ),
                      child: Text('AI',style: TextStyle(color: Colors.white,fontStyle: FontStyle.italic,fontSize: 50, fontWeight: FontWeight.w500,))
                    ),
                  ),
                ),

                Positioned(
                  bottom: 0,
                  right: 0,
                    child: FlatButton(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(30.0))),
                      color: Color.fromRGBO(250, 87, 0, 0.6),
                      child: Row(
                        children: <Widget>[
                          Text('History',style: TextStyle(color: Colors.white,fontStyle: FontStyle.italic,fontSize: 50, fontWeight: FontWeight.w500,)),
                          Icon(Icons.subdirectory_arrow_right,color:Colors.white),
                        ],
                      ),
                      
                      onPressed: ()async{
                        if(_paused){
                          var sum = await getListSum();
                          Navigator.push(context,MaterialPageRoute(builder: (context) => HistoryTab(sum)));
                        }
                      },
                    ),
                ),
              
                Positioned(
                  top:50,
                  right:30,
                  child: Tooltip(
                    padding: EdgeInsets.all(10.0),
                    decoration: BoxDecoration(color:Color.fromRGBO(250, 87, 0, 0.6),),
                    textStyle: TextStyle(fontStyle: FontStyle.italic,color:Colors.white),
                    waitDuration: Duration(microseconds:0),
                    showDuration: Duration(microseconds:0),
                    message: 'Double-tap to start/stop recording.\n\nMake sure your camera is facing\nthe shooting side of your body.\n\nStart shooting after the countdown.',
                    child: Icon(CupertinoIcons.info,color: Colors.white,),
                  ),

                )
              ]
            ),
    );
  }
}