function monitor(event) {
  // 緯度
  var latitude = event.coords.latitude;
  document.querySelector('#latitude').textContent = latitude;
  // 経度
  var longitude = event.coords.longitude;
  document.querySelector('#longitude').textContent = longitude;
  // 緯度・経度の精度
  var accuracy = event.coords.accuracy;
  document.querySelector('#accuracy').textContent = accuracy;
  // GPS 高度
  var altitude = event.coords.altitude;
  document.querySelector('#altitude').textContent = altitude;
  // GPS 高度の精度
  var altitudeAccuracy = event.coords.altitudeAccuracy;
  document.querySelector('#altitudeAccuracy').textContent = altitudeAccuracy;
  // 移動方向
  var heading = event.coords.heading;
  document.querySelector('#heading').textContent = heading;
  // 移動速度
  var speed = event.coords.speed;
  document.querySelector('#speed').textContent = speed;
  // タイムスタンプ
  var date = event.timestamp;
  if( typeof(date) == "number" ) {
    date = new Date(date);
  }
  document.querySelector('#timestamp').textContent = date.toString();
}
