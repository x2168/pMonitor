#include <Servo.h>

const byte trigPin = 11;      //超音波測距 Trig Pin
const byte echoPin = 10;      //超音波測距 Echo Pin
const byte PIRSensorPIN = 9;  // 紅外線動作感測器連接的腳位
const byte doorSwPIN = 8;     //關門 感測腳位，關門1

Servo sGate, sDoor;
char command = 'i';
String statusString = "door:C,gate:D,car:N,guest:A";
//                     123456789012345678901234567
void carSensor(){
  long duration, cm;
  
  digitalWrite(trigPin, LOW);
  delayMicroseconds(5);
  digitalWrite(trigPin, HIGH);     // 給 Trig 高電位，持續 10微秒
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  duration = pulseIn(echoPin, HIGH);   // 收到高電位時的時間
  cm = (duration/2) / 29.1;
  //cm=5;
  if( cm>0 && cm< 10){      // 0 ~ 10 cm 模擬表示有車
     //Serial.println("Yes Car");
     statusString.replace('N', 'Y');
  } else {
    //Serial.println("No Car");
     statusString.replace('Y', 'N');
  }  
}

void guestSensor() {
  int sensorPIR = digitalRead(PIRSensorPIN);    //擷取人體紅外線感測
  if (sensorPIR == 1) {        // 感測有人
     //Serial.println("Yes Guest ");
     statusString.replace('A', 'P');
  }
  else {                      
     //Serial.println("No Guest");
     statusString.replace('P', 'A');
  }
}

void doorClosedSensor() {
  if(digitalRead( doorSwPIN) == 1){     //微動開關被壓，        
    //Serial.println("Door is Closed");
     statusString.replace('O', 'C'); 
  }
  else {                         
    //Serial.println("Door is open");
     statusString.replace('C', 'O');
  }
}

void setup()
{
   sGate.attach(5);          //servo control with pin D5 for 閘馬達
   sDoor.attach(6);          //servo control with pin D6 for 門馬達
   Serial1.begin(57600);      //open internal serial connection to MT7688 duo
   Serial.begin(115200);
   pinMode(trigPin, OUTPUT);  //超音波測距 trig 接腳為 output mode  
   pinMode(echoPin, INPUT);   //超音波測距 echo 接腳為 input mode
   pinMode(doorSwPIN, INPUT);     // 感測開關門動作 (關:1)，(其他:0)
   pinMode(PIRSensorPIN, INPUT);  //人體紅外線感測 輸入   
}

//byte hasWrite = 1;
String commandStr;
void loop()
{     
  //接收 Lua 程式之 昇/降閘、開門指令
  commandStr= "";
  command = 'i';
  while( Serial1.available()) { //if serail1 buffer is not empty
    command = Serial1.read(); // read from MT7688
    commandStr += command;
    // Serial.print(command);  
  }
  /*
  if (command != 'i'){
    Serial.print("commandStr: ");
    Serial.println( commandStr );
  } */
     
  if( commandStr.indexOf('3') != -1 ) {     //降閘
    Serial.println("gate down");
    sGate.write(140);
    statusString.replace('U', 'D');
  }
  if(commandStr.indexOf('2') != -1 ) {      //升閘
    Serial.println("gate Up");
    statusString.replace('D', 'U');
    sGate.write(70);
  }
  if(commandStr.indexOf('1') != -1 ) {      //開門
    Serial.println("door open");
    statusString.replace('C', 'O');
    sDoor.write(140);
    delay(2000);
    sDoor.write(50);
  }

  //感測狀態傳給 Lua 程式
  if( commandStr.indexOf('#') != -1 ) {  
    carSensor();                  //感測是否 有車，並設定感測狀態
    guestSensor();                //感測是否 有人，並設定感測狀態
    doorClosedSensor();           //感測是否 關門，並設定感測狀態
    Serial1.print(statusString);  //感測狀態傳給 Lua 程式
    Serial1.print('\n');
  }

  delay(100);
}
