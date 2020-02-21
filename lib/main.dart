import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';
import 'coach_tab.dart';
import 'dart:async'; 

List<CameraDescription> cameras;

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //loadmodel
  Tflite.close();
  await Tflite.loadModel(model: "assets/posenet_mv1_075_float_from_checkpoints.tflite");
  

  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error: $e.code\nError Message: $e.message');
  }
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
  .then((_) => runApp(CoachApp()),
  );
}

class CoachApp extends StatefulWidget{
  @override
  _CoachAppState createState() => new _CoachAppState();
}

class _CoachAppState extends State<CoachApp>{

  @override
  Widget build(BuildContext context) {
      return MaterialApp(
        home: LaunchScreen(),
      );
  }
}


class LaunchScreen extends StatefulWidget{
  @override
  _LaunchScreenState createState() => new _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen>{

  void initState(){
    super.initState();
    Timer(Duration(seconds: 5), () => Navigator.push(context,MaterialPageRoute(builder: (context) => CoachPage(cameras))));
  }

  @override 
  Widget build(BuildContext context){
    return MaterialApp(
      home: Scaffold(
          body:
            Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Container(
                  color: Color.fromRGBO(250, 87, 0, 1.0),
                ),

                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child:Container(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.supervisor_account,size: 60.0,color:Color.fromRGBO(250, 87, 0, 1.0))
                            ),

                            Padding(
                              padding: EdgeInsets.only(top: 10.0),
                            ),
                            
                            Text('Ball-AI',style:TextStyle(color:Colors.white,fontSize: 20,fontStyle: FontStyle.italic,fontWeight: FontWeight.w500 )),
                          ],
                        ),
                      ),
                    ),

                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(Colors.white),),
                          Padding(padding: EdgeInsets.all(20)),
                          Text('Ball-AI provides you with an AI based\npersonalised basketball shooting coach.',style:TextStyle(color:Colors.white,fontStyle: FontStyle.italic,fontWeight: FontWeight.w400)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ),

      );
  }
}