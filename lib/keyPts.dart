import 'package:flutter/material.dart';
import 'data.dart';

typedef void Callback(double);

class KeyPoints extends StatelessWidget {
  final List<dynamic> results;
  final int previewH;
  final int previewW;
  final double screenH;
  final double screenW;
  final bool paused;

  KeyPoints(this.results, this.previewH, this.previewW, this.screenH, this.screenW,this.paused);

  @override
  Widget build(BuildContext context) {
      List<Widget> _renderKeypoints() {
        var lists = <Widget>[];
        var index = 0;
        var res = new List(17);
        results.forEach((re) {
          var list = re['keypoints'].values.map<Widget>((k) {
            var _x = k['x'];
            var _y = k['y'];
            var _s = k['score'];
            var _p = k['part'];
            //smooth out keypoints transition
            /* if(getLength() > 0){
              var pose = getLastPose();
              var cx = pose[index][0];
              var cy = pose[index][1];

              var dx = _x - cx;
              var dy = _y - cy;
              
              double thrshd = 0.05;

              dx < -thrshd?_x = cx - thrshd:dx > thrshd?_x = cx + thrshd:_x = _x;
              dy < -thrshd?_y = cy - thrshd:dy > thrshd?_y = cy + thrshd:_y = _y;
            } */
            res[index] = [_x,_y,_s,_p];
            index += 1;

            var scaleW, scaleH, x, y;

            if (screenH / screenW > previewH / previewW) {
              scaleW = screenH / previewH * previewW;
              scaleH = screenH;
              var difW = (scaleW - screenW) / scaleW;
              x = (_x - difW / 2) * scaleW;
              y = _y * scaleH;
            } else {
              scaleH = screenW / previewW * previewH;
              scaleW = screenW;
              var difH = (scaleH - screenH) / scaleH;
              x = _x * scaleW;
              y = (_y - difH / 2) * scaleH;
            }

            return Positioned(
              left: x-6,
              top: y-6,
              width: 100,
              height: 12,
              child: Container(
                child: Text(
                  //"● ${k["part"]}",
                  '●',
                  style: TextStyle(
                    color: Color.fromRGBO(37, 213, 253, 1.0),
                    fontSize: 12.0,
                  ),
                ),
              ),
            );
          }).toList();
          lists..addAll(list);
        });
        if(!paused && index != 0){
          appendFrame(res);
        }
        return lists;
      }
      return Stack(
        children:  _renderKeypoints(),
      );
  }
}