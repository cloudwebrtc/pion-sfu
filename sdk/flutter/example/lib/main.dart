import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_pion/flutter_pion.dart';
import 'package:flutter_webrtc/webrtc.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Pion SDK Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class VideoRendererAdapter {
  String _id;
  RTCVideoRenderer _renderer;
  MediaStream _stream;
  RTCVideoViewObjectFit _objectFit =
      RTCVideoViewObjectFit.RTCVideoViewObjectFitContain;
  VideoRendererAdapter(this._id);

  setSrcObject(MediaStream stream, {bool localVideo = false}) async {
    if (_renderer == null) {
      _renderer = new RTCVideoRenderer();
      await _renderer.initialize();
    }
    _stream = stream;
    _renderer.srcObject = _stream;
    if (localVideo) {
      _objectFit = RTCVideoViewObjectFit.RTCVideoViewObjectFitCover;
      _renderer.mirror = true;
      _renderer.objectFit = _objectFit;
    }
  }

  switchObjFit() {
    _objectFit =
        (_objectFit == RTCVideoViewObjectFit.RTCVideoViewObjectFitContain)
            ? RTCVideoViewObjectFit.RTCVideoViewObjectFitCover
            : RTCVideoViewObjectFit.RTCVideoViewObjectFitContain;
    _renderer.objectFit = _objectFit;
  }

  dispose() async {
    if (_renderer != null) {
      print('dispose for texture id ' + _renderer.textureId.toString());
      _renderer.srcObject = null;
      await _renderer.dispose();
      _renderer = null;
    }
  }

  get id => _id;

  get renderer => _renderer;

  get stream => _stream;

  get streamId => _stream.id;
}

class _MyHomePageState extends State<MyHomePage> {
  String _server;
  String _roomId;
  SharedPreferences prefs;
  SFU _sfu;
  bool _inCalling = false;
  bool _connected = false;
  List<VideoRendererAdapter> _videoRendererAdapters = new List();

  @override
  initState() {
    super.initState();
    init();
  }

  init() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      _server = prefs.getString('server');
      _roomId = prefs.getString('room');
    });
  }

  handleConnect() async {
    if (_sfu == null) {
      var url = 'https://' + _server + ':8443/ws';
      _sfu = new SFU(url);
      _sfu.on('connect', () {
        print('connected');
        setState(() {
          _connected = true;
        });
      });
      _sfu.on('disconnect', () {
        print('disconnected');
        setState(() {
          _connected = false;
        });
      });
      _sfu.on('addLocalStream',(id, stream) async {
          var adapter = new VideoRendererAdapter(id);
          await adapter.setSrcObject(stream);
          setState(() {
            _videoRendererAdapters.add(adapter);
          });
      });

      _sfu.on('removeLocalStream', (id, stream) async {
        var adapter = _videoRendererAdapters.firstWhere((item) => item.id == id);
        await adapter.dispose();
        setState(() {
            _videoRendererAdapters.remove(adapter);
        });
      });

      _sfu.on('addRemoteStream',(id, stream) async {
          var adapter = new VideoRendererAdapter(id);
          await adapter.setSrcObject(stream);
          setState(() {
            _videoRendererAdapters.add(adapter);
          });
      });

      _sfu.on('removeRemoteStream', (id, stream) async {
        var adapter = _videoRendererAdapters.firstWhere((item) => item.id == id);
        await adapter.dispose();
        setState(() {
            _videoRendererAdapters.remove(adapter);
        });
      });
    }
  }

  handleJoin() async {
    try{
      await _sfu.join(_roomId);
      setState(() {
        _inCalling = true;
      });
      await _sfu.publish();
    }catch(error){

    }
  }

  handleLeave() async {
    setState(() {
      _inCalling = false;
    });
    if (_sfu != null) {
      await _sfu.leave();
      _sfu.close();
      _sfu = null;
    }
  }

Widget buildJoinView(context) {
    return new Align(
        alignment: Alignment(0, 0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                  width: 260.0,
                  child: TextField(
                    keyboardType: TextInputType.text,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(10.0),
                      border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black12)),
                      hintText: _roomId ?? 'Enter RoomID.',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _roomId = value;
                      });
                    },
                  )),
              SizedBox(width: 260.0, height: 48.0),
              SizedBox(
                  width: 220.0,
                  height: 48.0,
                  child: MaterialButton(
                    child: Text(
                      'Join',
                      style: TextStyle(fontSize: 16.0, color: Colors.white),
                    ),
                    color: Colors.blue,
                    textColor: Colors.white,
                    onPressed: () {
                      if (_roomId != null) {
                        handleJoin();
                        prefs.setString('room', _roomId);
                        return;
                      }
                      showDialog<Null>(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return new AlertDialog(
                            title: new Text('Room id is empty'),
                            content: new Text('Please enter Pion-SFU RoomID!'),
                            actions: <Widget>[
                              new FlatButton(
                                child: new Text('Ok'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ))
            ]));
}


  Widget buildConnectView(context) {
    return new Align(
        alignment: Alignment(0, 0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                  width: 260.0,
                  child: TextField(
                    keyboardType: TextInputType.text,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(10.0),
                      border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black12)),
                      hintText: _server ?? 'Enter Pion-SFU address.',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _server = value;
                      });
                    },
                  )),
              SizedBox(width: 260.0, height: 48.0),
              SizedBox(
                  width: 220.0,
                  height: 48.0,
                  child: MaterialButton(
                    child: Text(
                      'Connect',
                      style: TextStyle(fontSize: 16.0, color: Colors.white),
                    ),
                    color: Colors.blue,
                    textColor: Colors.white,
                    onPressed: () {
                      if (_server != null) {
                        handleConnect();
                        prefs.setString('server', _server);
                        return;
                      }
                      showDialog<Null>(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return new AlertDialog(
                            title: new Text('Server is empty'),
                            content: new Text('Please enter Pion-SFU address!'),
                            actions: <Widget>[
                              new FlatButton(
                                child: new Text('Ok'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ))
            ]));
  }

  Widget buildVideoView(VideoRendererAdapter adapter) {
    return Container(
      alignment: Alignment.center,
      child: RTCVideoView(adapter.renderer),
      color: Colors.black,
    );
  }

 List<Widget> _buildVideoViews() {
    List<Widget> views = new List<Widget>();
    _videoRendererAdapters.forEach((adapter) {
      views.add(buildVideoView(adapter));
    });
    return views;
  }

  Widget buildStreamsGridView() {
    return new GridView.extent(
      maxCrossAxisExtent: 300.0,
      padding: const EdgeInsets.all(1.0),
      mainAxisSpacing: 1.0,
      crossAxisSpacing: 1.0,
      children: _buildVideoViews(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(builder: (context, orientation) {
      return Scaffold(
        appBar: orientation == Orientation.portrait
            ? AppBar(
                title: Text(widget.title),
              )
            : null,
        body: Center(
          child: _connected?  _inCalling ? buildStreamsGridView() : buildJoinView(context) : buildConnectView(context),
        ),
        floatingActionButton: _inCalling
            ? FloatingActionButton(
                onPressed: handleLeave,
                backgroundColor: Colors.red,
                tooltip: 'Increment',
                child: Icon(Icons.call_end),
              )
            : null,
      );
    });
  }
}
