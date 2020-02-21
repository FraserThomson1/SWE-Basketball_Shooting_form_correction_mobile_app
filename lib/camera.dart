import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tflite/tflite.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:core';
import 'dart:math' as math;
import 'data.dart';

import 'package:coach_ai/analysis.dart';

bool inverting = false;

String displayCD = '';

Future<bool> getPref() async{
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('setDomHand');
}

Future<bool> getH() async{
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('domR');
}

Future<Null> confirmation(BuildContext context,domR,cam)async{
    await showDialog(
      context: context,
      builder: (BuildContext context){
        return ConfirmDialog(domR,cam);
      }
    );
  }

Future<Null> confirmHand(BuildContext context)async{
    await showDialog(
      context: context,
      builder: (BuildContext context){
        return HandDialog();
      }
    );
  }

class HandDialog extends StatefulWidget{
  final Widget child;
  HandDialog({Key key,this.child}) : super(key:key);

  _HandDialogState createState() => _HandDialogState();
}

class _HandDialogState extends State<HandDialog>{

  setPreference(bool rH) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('domR', rH);
    prefs.setBool('setDomHand',true);
  }

  @override
  Widget build(BuildContext context){
    return CupertinoAlertDialog(
      title: Text('Choose Shooting Hand'),
      content: Text('Please Choose your dominant shooting hand.'),
      actions: <Widget>[
        FlatButton(
          child: Text('Left',style: TextStyle(color: Colors.blue),),
          onPressed: ()async{
            setPreference(false);
            Navigator.of(context, rootNavigator: true).pop("Left");
          },
        ),
        FlatButton(
          child: Text('Right',style: TextStyle(color: Colors.blue),),
          onPressed: ()async{
            setPreference(true);
            Navigator.of(context, rootNavigator: true).pop("Right");
          },
        ),
      ],
    );
  }
}

class ConfirmDialog extends StatefulWidget{
  final Widget child;
  final int cam;
  final bool domR;
  ConfirmDialog(this.domR,this.cam,{Key key,this.child}) : super(key:key);

  _ConfirmDialogState createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<ConfirmDialog>{
  @override
  Widget build(BuildContext context){
    return CupertinoAlertDialog(
      title: Text('Confirm Submission'),
      content: Text('Do you wish to submit the recorded clip for analysis?'),
      actions: <Widget>[
        FlatButton(
          child: Text('Cancel',style: TextStyle(color: Colors.blue),),
          onPressed: (){
            clearData();
            Navigator.of(context, rootNavigator: true).pop("Cancel");
          },
        ),
        FlatButton(
          child: Text('Confirm',style: TextStyle(color: Colors.blue),),
          onPressed: ()async{
            Navigator.of(context, rootNavigator: true).pop("Confirm");
            var dR = widget.domR;
            if(widget.cam == 0){
              dR = !dR;
            }
            await Navigator.push(context,MaterialPageRoute(builder: (context) => Analysis(getData(),dR)));
            clearData();
          },
        ),
      ],
    );
  }
}

typedef void Callback(List<dynamic> list, int h, int w, bool p);

class Camera extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Callback setRecognitions;

  Camera(this.cameras, this.setRecognitions);

  @override
  _CameraState createState() => new _CameraState();
}

class _CameraState extends State<Camera> {
  CameraController controller;
  bool isDetecting = false;
  bool paused = true;
  List<dynamic> recognitions;
  Timer _timer;
  int camera;
  int _start = 3;
  bool timerStarted = false;

  startTimer() {
    timerStarted = true;
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) => setState(
        () {
          if (_start < 1) {
            displayCD = '';
            paused = false;
            _start = 3;
            timerStarted = false;
            timer.cancel();
          } else {
            displayCD = (_start).toString();
            _start = _start - 1;
          }
        },
      ),
    );
  }

  initController(cam){
    camera = cam;
    if (widget.cameras == null || widget.cameras.length < 1) {
      print('No camera is found');
    } else {
      controller = new CameraController(
        widget.cameras[cam],
        ResolutionPreset.high,
      );
      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState((){});
        controller.startImageStream((CameraImage img) {
          if (paused){
            widget.setRecognitions(null, 0, 0, paused);
          }
          if (!isDetecting & !paused) {
            isDetecting = !isDetecting;
            var byteslist = [img.planes[0].bytes];
            Tflite.runPoseNetOnFrame(
                bytesList: byteslist,
                imageHeight: img.height,
                imageWidth: img.width,
                numResults: 1,
                threshold: 0.85,
                nmsRadius: 1,
              ).then((recognitions){
                widget.setRecognitions(recognitions, img.height, img.width, paused);
                isDetecting = !isDetecting;
            });
          }
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    initController(1);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller.value.isInitialized) {
      if(!inverting){
        return Center(
            child:Text('Please go to Settings and enable camera access.',style: TextStyle(color:Colors.grey),),
        );
      }else{
        return Container(
          color: Colors.black,
        );
      }
    }
    inverting = false;

    var tmp = MediaQuery.of(context).size;
    var screenH = math.max(tmp.height, tmp.width);
    var screenW = math.min(tmp.height, tmp.width);
    tmp = controller.value.previewSize;
    var previewH = math.max(tmp.height, tmp.width);
    var previewW = math.min(tmp.height, tmp.width);
    var screenRatio = screenH / screenW;
    var previewRatio = previewH / previewW;


    return Stack(
      children: <Widget>[
        GestureDetector(
            child: OverflowBox(
              maxHeight:
                  screenRatio > previewRatio ? screenH : screenW / previewW * previewH,
              maxWidth:
                  screenRatio > previewRatio ? screenH / previewH * previewW : screenW,
              child: CameraPreview(controller), 
            ),
            onDoubleTap: () async{
              bool domSet;
              bool domR;
              await getPref().then((domS){domSet = domS;});
              await getH().then((domHand){domR = domHand;});
              if(domSet != true){
                confirmHand(context);
                await getPref().then((domS){domSet = domS;});
                await getH().then((domHand){domR = domHand;});
              }
              if(domSet == true){
                if(paused && !timerStarted){
                  return startTimer();
                }else if(!paused){
                  paused = true;
                  confirmation(context,domR,camera);
                }
              }
            },
        ),

        Center(
          child: Text(displayCD,style:TextStyle(fontSize:150.0,color:Colors.white)),
        ),

        Positioned(
          bottom:0,
          left: 0,         
          child: FlatButton(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(30.0))),
            color: Color.fromRGBO(250, 87, 0, 0.6),
            child:Icon(CupertinoIcons.switch_camera,size:50),
            onPressed: (){
              inverting = true;
              initController(1-camera);
            },
          )
        ),
      ],
    );
  }
}


