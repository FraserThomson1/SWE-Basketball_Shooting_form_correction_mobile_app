List data = [];

appendFrame(res){
  data.add(res);
}

int getLength(){
  return data.length;
}

List getData(){
  return data;
}

List getLastPose(){
  return data.last;
}

clearData(){
  data = [];
}