import netP5.*;
import oscP5.*;


OscP5 oscP5;

/* a NetAddress contains the ip address and port number of a remote location in the network. */
NetAddress oscPythonBroadcastLocation; 
NetAddress oscUnityBroadcastLocation; 

// OSC sercer address and port
int port_in = 5005;
//String ip_python = "169.254.0.1";
String ip_python = "10.150.30.79";
//String ip_python = "192.168.0.102";
int port_out_python = 5006;
//String ip_unity = "169.254.207.164";
String ip_unity = "10.150.26.114";
//String ip_unity = "192.168.0.1";
int port_out_unity = 5007;

int power = 0;

int timerStart = 0;
int timerInterval = 1000;

int movingAvgSize = 20;
int[] movingArray = new int[20];
int movingArrayIdx = 0;

int emergencyLowPower = 500;
int stableThreshold = 650;
int maxVibroTimes = 10;
int currentVibroTimes = 0;

boolean connected = false;
boolean stable = false;
boolean emergencyStep = false;

PrintWriter log;

void setup() {
  size(400,400);
  frameRate(25);
  
  oscP5 = new OscP5(this, port_in);
  oscPythonBroadcastLocation = new NetAddress(ip_python, port_out_python);
  oscUnityBroadcastLocation = new NetAddress(ip_unity, port_out_unity);
  
  timerStart = millis();
  
  for (int i = 0; i<movingAvgSize; i+=1) {
    movingArray[i] = 0;
  }
  
  log = createWriter("log-"+year()+"-"+month()+"-"+day()+"-"+hour()+"-"+minute()+"-"+second()+".csv"); 
  log.println("hour,minute,second,game_state,device_state");
}


void draw() {
  background(0);
  
  textSize(18);
  fill(255, 255, 255);
  text("python " + ip_python, 10, 30);
  text("unity " + ip_unity, 10, 50);
  
  textSize(28);
  
  if (connected && stable && emergencyStep) {
    text("emergency " + str(power), 10, 120);
  } else if (connected && stable) {
    text("stable " + str(power), 10, 120);
  } else if (connected) {
    text("connected " + str(power), 10, 120);
  } else {
    text("dead", 10, 120);
  }
  
  text("BLE: 0 (off), 1 (in), 2 (out)", 10, 180);
  text("     3 (in timer), 4 (out timer)", 10, 210);
  text("     5 (vib short) 6 (vib long) ", 10, 240);
  text("     7 (ems), 9 (connect)", 10, 270);
  text("VR:  s (stable) d (dying)", 10, 300);
  text("LOG: g (start) e (end)", 10, 330);
  
  // if connected, check power at times
  if (millis() - timerStart > timerInterval) {
    if (connected) {
      sendMessageToBLE(9);
    }
    timerStart = millis();
  }
  
  // estimatation of vibro power
  //if (currentVibroTimes >= maxVibroTimes) {
  //  println("send OSC to Unity: dying because run out of vibro power");
  //  log.println(timestamp()+","+"vibro_cemergency");
  //  log.flush();
  //}
  

  
}

void keyPressed() {
  OscMessage m;
  if (key == CODED) {
    if (keyCode == UP) {
      
    } else if (keyCode == DOWN) {
      
    } else if (keyCode == LEFT) {
      
    } else if (keyCode == RIGHT) {
     
    }
  } else {
    switch(key) {
      case('1'):
        sendMessageToBLE(1);
        log.println(timestamp()+","+"manual_clutch");
        log.flush();
        break;
      case('2'):
        sendMessageToBLE(2);
        log.println(timestamp()+","+"manual_unclutch");
        log.flush();
        break;
      case('3'):
        sendMessageToBLE(3);
        log.println(timestamp()+","+"manual_clutch_timeout");
        log.flush();
        break;
      case('4'):
        sendMessageToBLE(4);
        log.println(timestamp()+","+"manual_unclutch_timeout");
        log.flush();
        break;
      case('5'):
        sendMessageToBLE(5);
        log.println(timestamp()+","+"manual_vibro");
        log.flush();
        break;
      case('6'):
        sendMessageToBLE(6);
        log.println(timestamp()+","+"manual_vibro_long");
        log.flush();
        break;
      case('7'):
        sendMessageToBLE(7);
        log.println(timestamp()+","+"manual_ems");
        log.flush();
        break;
      case('8'):
        sendMessageToBLE(8);
        break;
      case('9'):
        sendMessageToBLE(9);
        break;
      case('0'):
        sendMessageToBLE(0);
        break;
      case(' '):
        sendMessageToBLE(3);
        log.println(timestamp()+","+"manual_unclutch_timeout");
        log.flush();
        break;
      case('a'):
        sendMessageSOSToBLE();
        break;
      case('b'):
        sendMessageVibrosToBLE();
        break;
      case('g'):
        println("log > game start");
        log.println(timestamp()+"game_start");
        log.flush();
        break;
      case('e'):
        println("log > game end");
        log.println(timestamp()+"game_end");
        log.flush();
        break;
      case('s'):
        sendMessageToUnity(1);
        println("send OSC to Unity: stable");
        log.println(timestamp()+","+"manual_stable");
        log.flush();
        break;
      case('d'):
        sendMessageToUnity(2);
        println("send OSC to Unity: dying");
        log.println(timestamp()+","+"manual_emergency");
        log.flush();
        break;
      //case('f'):
      //  sendVRMessage(3);
      //  break;
      //case('g'):
      //  sendVRMessage(4);
      //  break;
    }  
  }
}

void sendMessageToBLE(int n) {
  OscMessage myOscMessage = new OscMessage("/ble");
  myOscMessage.add(n);
  oscP5.send(myOscMessage, oscPythonBroadcastLocation);
}

void sendMessageSOSToBLE() {
  println("send SOS to BLE");
  sendMessageToBLE(5);
  delay(300);
  delay(300);
  sendMessageToBLE(5);
  delay(300);
  delay(300);
  sendMessageToBLE(5);
  delay(300);
  delay(900);
  sendMessageToBLE(6);
  delay(900);
  delay(300);
  sendMessageToBLE(6);
  delay(900);
  delay(300);
  sendMessageToBLE(6);
  delay(900);
  delay(900);
  sendMessageToBLE(5);
  delay(300);
  sendMessageToBLE(5);
  delay(300);
  delay(300);
  sendMessageToBLE(5);
}

void sendMessageVibrosToBLE() {
  println("send sereis of vibro to BLE");
  sendMessageToBLE(8);
  delay(110);
  sendMessageToBLE(8);
  delay(110);
  sendMessageToBLE(8);
}

void sendMessageToUnity(int n) {
  OscMessage myOscMessage = new OscMessage("/vr");
  myOscMessage.add(n);
  oscP5.send(myOscMessage, oscUnityBroadcastLocation);
}

void oscEvent(OscMessage theOscMessage) {
  if(theOscMessage.checkAddrPattern("/power")==true) {
    int firstValue = theOscMessage.get(0).intValue(); 
    // println("osc > power "+firstValue);
    power = firstValue;
    log.println(timestamp()+",power,"+power);
    log.flush();
    connected = true;
    
    if (!stable) {
      movingArray[movingArrayIdx] = power;
      movingArrayIdx += 1;
      if (movingArrayIdx>=movingAvgSize) {
        movingArrayIdx = 0;
      }
      int powerAvg = computeAvg(movingArray, movingAvgSize);
      println("power avg: "+ powerAvg);
      if (powerAvg > stableThreshold) {
        stable = true;
        sendMessageToUnity(1);
        println("send OSC to Unity: stable");
        log.println(timestamp()+","+"stable");
        log.flush();
      }
    }   // if connected, stable, but enter emergency
    else if (!emergencyStep) {
      if (power < emergencyLowPower) {
        sendMessageToBLE(4);
        println("emergency!");
        sendMessageToUnity(2);
        println("send OSC to Unity: dying");
        emergencyStep = true;
        log.println(timestamp()+","+"emergency");
        log.flush();
      } 
    } else {
      if (power > stableThreshold) {
        emergencyStep = false;
      }
    }
  }
  else if(theOscMessage.checkAddrPattern("/connected")==true) {
    println("osc > connected");
    connected = true;
    for (int i = 0; i<movingAvgSize; i+=1) {
      movingArray[i] = 0;
    }
    emergencyStep = false;
    currentVibroTimes = 0;
    log.println(timestamp()+","+"connected");
    log.flush();
  }
  else if(theOscMessage.checkAddrPattern("/disconnected")==true) {
    println("osc > disconnected");
    connected = false;
    stable = false;
    log.println(timestamp()+","+"disconnected");
    log.flush();
  }
  else if(theOscMessage.checkAddrPattern("/unclutch")==true) {
    println("osc > unclutch");
    sendMessageToBLE(1);
    log.println(timestamp()+","+"unclutch");
    log.flush();
  }
  else if(theOscMessage.checkAddrPattern("/clutch")==true) {
    println("osc > clutch");
    sendMessageToBLE(2);
    log.println(timestamp()+","+"clutch");
    log.flush();
  }
  else if(theOscMessage.checkAddrPattern("/vibro")==true) {
    println("osc > vibro");
    currentVibroTimes += 1;
    println("vibro "+currentVibroTimes);
    sendMessageToBLE(5);
    log.println(timestamp()+","+"vibro");
    log.flush();
  }
  else if(theOscMessage.checkAddrPattern("/ems")==true) {
    println("osc > ems");
    sendMessageToBLE(7);
    log.println(timestamp()+","+"ems");
    log.flush();
  }
  else if(theOscMessage.checkAddrPattern("/high")==true) {
    println("osc > high");
    sendMessageToBLE(2);
    log.println(timestamp()+","+"high");
    log.flush();
  }
  else if(theOscMessage.checkAddrPattern("/off")==true) {
    println("osc > off");
    sendMessageToBLE(0);
    log.println(timestamp()+","+"off");
    log.flush();
  }
  else if(theOscMessage.checkAddrPattern("/sos")==true) {
    println("osc > sos");
    sendMessageSOSToBLE();
    log.println(timestamp()+","+"sos");
    log.flush();
  }
  else if(theOscMessage.checkAddrPattern("/vibros")==true) {
    println("osc > vibro series");
    sendMessageVibrosToBLE();
    log.println(timestamp()+","+"vibros");
    log.flush();
  }
  else if(theOscMessage.checkAddrPattern("/coconut_island")==true) {
    println("osc > coconut_island");
    log.println(timestamp()+"coconut_island");
    log.flush();
  }
  else if(theOscMessage.checkAddrPattern("/carrot_island")==true) {
    println("osc > carrot_island");
    log.println(timestamp()+"carrot_island");
    log.flush();
  }
  else if(theOscMessage.checkAddrPattern("/battery_island")==true) {
    println("osc > battery_island");
    log.println(timestamp()+"battery_island");
    log.flush();
  }
  else if(theOscMessage.checkAddrPattern("/get_on_boat")==true) {
    println("osc > get_on_boat");
    log.println(timestamp()+"get_on_boat");
    log.flush();
  }
  else if(theOscMessage.checkAddrPattern("/island_sinks")==true) {
    println("osc > island_sinks");
    log.println(timestamp()+"island_sinks");
    log.flush();
  }
  else if(theOscMessage.checkAddrPattern("/row")==true) {
    println("osc > row");
    log.println(timestamp()+"row");
    log.flush();
  }
  else if(theOscMessage.checkAddrPattern("/swim")==true) {
    println("osc > swim");
    log.println(timestamp()+"swim");
    log.flush();
  }
  else if(theOscMessage.checkAddrPattern("/hit_tree")==true) {
    println("osc > hit_tree");
    log.println(timestamp()+"hit_tree");
    log.flush();
  }
  else if(theOscMessage.checkAddrPattern("/crack_coconut")==true) {
    println("osc > crack_coconut");
    log.println(timestamp()+"crack_coconut");
    log.flush();
  }
  else if(theOscMessage.checkAddrPattern("/crab_pinch")==true) {
    println("osc > crab_pinch");
    log.println(timestamp()+"crab_pinch");
    log.flush();
  }
  else if(theOscMessage.checkAddrPattern("/pull_carrot")==true) {
    println("osc > pull_carrot");
    log.println(timestamp()+"pull_carrot");
    log.flush();
  }
  else if(theOscMessage.checkAddrPattern("/insert_battery")==true) {
    println("osc > insert_battery");
    log.println(timestamp()+"insert_battery");
    log.flush();
  }
  else if(theOscMessage.checkAddrPattern("/go_through_bush")==true) {
    println("osc > go_through_bush");
    log.println(timestamp()+"go_through_bush");
    log.flush();
  }
}

int computeAvg(int[] array, int size) {
  int total = 0;
  for (int i = 0; i<size; i+=1) {
    total += array[i];
  }
  return total/size;
}

String timestamp() {
  return hour()+","+minute()+","+second()+",";
}
