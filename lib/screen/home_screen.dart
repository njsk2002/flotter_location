

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatelessWidget {
  //지도 초기화 위치
  static final LatLng companyLatLng = LatLng(
      37.4219983, //위도
      -122.084, //경도
  );
  
  //회사 위치 마커 선언
  static final Marker marker = Marker(
      markerId: MarkerId('company'),
      position: companyLatLng,
  );

  //회사 위치 반경(원형)표시
  static final Circle circle = Circle(
    circleId: CircleId('CheckAreaCircle'),
    center: companyLatLng, // 원의 중심이 되는 위치,latLng값 전달
    fillColor: Colors.blue.withOpacity(0.5),//원의 색상
    radius: 100, //원의 반지름(미터단위)
    strokeColor: Colors.blue, //원의 테두리 색
    strokeWidth: 1, // 원의 테두리 두께
  );
  
  const HomeScreen({Key? key}) : super(key: key);

  AppBar renderAppBar() {
    //APP BAR 구현
    return AppBar(
      centerTitle: true,
      title: Text(
        "오늘도 출근",
        style: TextStyle(
          color : Colors.blue,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: Colors.white,
    );
  }

  Future<String> checkPermission() async{
    final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    //위치 서비스 활성화 여부 확인

    if(!isLocationEnabled) { // 위이 서비서 활성화 안됨
      return '위치 서비스를 활성화해주세요!';
    }

    LocationPermission checkedPermission = await Geolocator.checkPermission();
    //위치 권한 확인

    if(checkedPermission == LocationPermission.denied){//위치 권한 거절됨
      //위치 권한 요청하기
      checkedPermission = await Geolocator.requestPermission();

      if(checkedPermission == LocationPermission.denied){
        return '위치 권한을 허가해 주세요!';
      }
    }

    //위치 권한 거절됨(앱에서 재요청 불가)
    if(checkedPermission == LocationPermission.denied){
      return '앱의 위치 권한을 설정에서 허가해주세요!';
    }

    //위의 모든 조건이 통과되면 위치 권한 허가 완료
    return '위치 권한이 허가 되었습니다.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: renderAppBar(),
      body: FutureBuilder<String>(
          future: checkPermission(),
          builder: (context, snapshot){
            //로딩상태
            if(!snapshot.hasData &&
            snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            // 권한 허가 상태
            if(snapshot.data == '위치 권한이 허가 되었습니다.'){
              return Column(
                children: [
                  Expanded( // 2/3만큼 차지
                    flex: 2,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: companyLatLng,
                        zoom: 16, // 확대 정도 (높을수록 크게 보임)
                      ),
                      myLocationEnabled: true, //내위치 보여주기
                      markers: Set.from([marker]), // Set로 Marker제공
                      circles: Set.from([circle]),
                    ),
                  ),
                  Expanded(child: Column( // 1/3만큼 차지
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timelapse_outlined,
                        color: Colors.blue,
                        size: 50.0,
                      ),
                      const SizedBox(height: 20.0,),
                      ElevatedButton(
                        onPressed: () async{
                          final curPosition = await Geolocator.getCurrentPosition();//현재위치
                          print('현재 위치는 ${curPosition}');
                          final distance = Geolocator.distanceBetween(
                            curPosition.latitude, // 현재 위도
                            curPosition.longitude, //현재 경도
                            companyLatLng.latitude, // 회사 위도
                            companyLatLng.longitude, //회사 경도
                          );
                          bool canCheck = distance < 100; // 100미터 이내에 있으면 출근가능

                          showDialog(
                              context: context,
                              builder: (_){
                                return AlertDialog(
                                  title: Text('출근하기'),

                                  // 출근 가능 유무에 따라 다른 메세지 제공
                                  content: Text(
                                    canCheck ? '출근을 하시겠습니까?' : '출근할 수 없는 위치입니다.',
                                  ),
                                  actions: [
                                    TextButton(
                                        // 취소를 누르면 false 반환
                                        onPressed: (){
                                          Navigator.of(context).pop(false);
                                         },
                                        child:Text('취소'),
                                     ),

                                        if (canCheck)
                                          TextButton(
                                              onPressed: (){
                                                Navigator.of(context).pop(true);
                                              },
                                              child: Text('출근하기'),
                                          ),
                                  ],
                                );
                              },
                          );
                        },
                        child: Text('출근하기!'),
                      ),
                    ],
                  ),
                  ),
                ],
              );
            }
            // 권한 없는 상태
            return Center(
              child: Text(
                snapshot.data.toString(),
              ),
            );
          },
      ),
    );
  }



}//CLASS