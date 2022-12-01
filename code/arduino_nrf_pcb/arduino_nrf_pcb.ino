#include <bluefruit.h>
#include <Adafruit_LittleFS.h>
#include <InternalFileSystem.h>

// BLE Service
BLEUart bleuart; // uart over ble

#define LED_PIN 8
#define SW1_PIN 38

#define BATT_SENSE_PIN 2
#define VIBRO_SENSE_PIN 29
#define EMS_SENSE_PIN 31
#define EPM_1_PIN 32
#define EPM_2_PIN 42
#define EPM_3_PIN 45
#define EPM_4_PIN 47
#define VIBRO_PIN 15
#define EMS_PIN 13

int batt_sense = 0;
int vibro_sense = 0;
int ems_sense = 0;
unsigned long last_time, current_time;


void setup() {
  pinMode(LED_PIN, OUTPUT);
  pinMode(EPM_1_PIN, OUTPUT);
  pinMode(EPM_2_PIN, OUTPUT);
  pinMode(EPM_3_PIN, OUTPUT);
  pinMode(EPM_4_PIN, OUTPUT);
  pinMode(VIBRO_PIN, OUTPUT);
  pinMode(EMS_PIN, OUTPUT);
  pinMode(BATT_SENSE_PIN, INPUT);
  pinMode(VIBRO_SENSE_PIN, INPUT);
  pinMode(EMS_SENSE_PIN, INPUT);
  pinMode(SW1_PIN, INPUT_PULLUP);
  
  digitalWrite(EPM_1_PIN, LOW);
  digitalWrite(EPM_2_PIN, LOW);
  digitalWrite(EPM_3_PIN, LOW);
  digitalWrite(EPM_4_PIN, LOW);
  digitalWrite(VIBRO_PIN, LOW);
  digitalWrite(EMS_PIN, LOW);

  start_ble();
}

void loop() {
  if ( bleuart.available() )
  {
    uint8_t ch;
    ch = (uint8_t) bleuart.read();
    int cmd = ch - '0';

    // turn off everything
    if (cmd == 0) {
      digitalWrite(EPM_1_PIN, LOW);
      digitalWrite(EPM_2_PIN, LOW);
      digitalWrite(EPM_3_PIN, LOW);
      digitalWrite(EPM_4_PIN, LOW);
      // report vibro
      ems_sense = analogRead(EMS_SENSE_PIN);
      bleuart.print(ems_sense);
      bleuart.println();
    }

    // EPM out (unclutch)
    if (cmd == 1) {
      digitalWrite(EPM_1_PIN, HIGH);
      digitalWrite(EPM_3_PIN, HIGH);
      digitalWrite(EPM_2_PIN, LOW);
      digitalWrite(EPM_4_PIN, LOW);
    }
    // EPM in (clutch)
    if (cmd == 2) {
      digitalWrite(EPM_1_PIN, LOW);
      digitalWrite(EPM_3_PIN, LOW);
      digitalWrite(EPM_2_PIN, HIGH);
      digitalWrite(EPM_4_PIN, HIGH);
    }
    // EPM out (unclutch) with timing
    if (cmd == 3) {
      digitalWrite(EPM_1_PIN, HIGH);
      digitalWrite(EPM_3_PIN, HIGH);
      digitalWrite(EPM_2_PIN, LOW);
      digitalWrite(EPM_4_PIN, LOW);
      delay(500);
      digitalWrite(EPM_1_PIN, LOW);
      digitalWrite(EPM_3_PIN, LOW);
      digitalWrite(EPM_2_PIN, LOW);
      digitalWrite(EPM_4_PIN, LOW);
    }
    // EPM in (clutch) with timing
    if (cmd == 4) {
      digitalWrite(EPM_1_PIN, LOW);
      digitalWrite(EPM_3_PIN, LOW);
      digitalWrite(EPM_2_PIN, HIGH);
      digitalWrite(EPM_4_PIN, HIGH);
      delay(500);
      digitalWrite(EPM_1_PIN, LOW);
      digitalWrite(EPM_3_PIN, LOW);
      digitalWrite(EPM_2_PIN, LOW);
      digitalWrite(EPM_4_PIN, LOW);
    }

    // vibration motor short vibration
    if (cmd == 5) {
      tone(VIBRO_PIN, 170);
      delay(300);
      noTone(VIBRO_PIN);
    }
    // long vibration
    if (cmd == 6) {
      tone(VIBRO_PIN, 170);
      delay(900);
      noTone(VIBRO_PIN);
    }

    // EMS
    if (cmd == 7) {
      int repeat = 20;
      for (int i = 0; i<repeat; i++) {
        digitalWrite(EMS_PIN, HIGH);
        delayMicroseconds(200);
        digitalWrite(EMS_PIN, LOW);
        delay(20); //ms
      }
    }

    // long ems
    if (cmd == 8) {
      int repeat = 40;
      for (int i = 0; i<repeat; i++) {
        digitalWrite(EMS_PIN, HIGH);
        delayMicroseconds(200);
        digitalWrite(EMS_PIN, LOW);
        delay(20); //ms
      }
    }
    
    if (cmd == 9) {
      // report battery
      batt_sense = analogRead(BATT_SENSE_PIN);
      bleuart.print(batt_sense);
      bleuart.println();
//      // report vibro
//      vibro_sense = analogRead(VIBRO_SENSE_PIN);
//      bleuart.print(vibro_sense);
//      bleuart.println();
    }
  }

  delay(100); // important to save power
}

void start_ble()
{
  Bluefruit.autoConnLed(false);
  Bluefruit.begin();
  Bluefruit.setTxPower(-16);    // Check bluefruit.h for supported values
  Bluefruit.setName("Harvest");
  //Bluefruit.setName(getMcuUniqueID()); // useful testing with multiple central connections
  Bluefruit.Periph.setConnectCallback(connect_callback);
  Bluefruit.Periph.setDisconnectCallback(disconnect_callback);
  // Configure and Start BLE Uart Service
  bleuart.begin();
  // Set up and start advertising
  startAdv();
}

void startAdv(void)
{
  // Advertising packet
  Bluefruit.Advertising.addFlags(BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE);
  // Bluefruit.Advertising.addTxPower();

  // Include bleuart 128-bit uuid
  Bluefruit.Advertising.addService(bleuart);

  // Secondary Scan Response packet (optional)
  // Since there is no room for 'Name' in Advertising packet
  Bluefruit.ScanResponse.addName();

  /* Start Advertising
     - Enable auto advertising if disconnected
     - Interval:  fast mode = 20 ms, slow mode = 152.5 ms
     - Timeout for fast mode is 30 seconds
     - Start(timeout) with timeout = 0 will advertise forever (until connected)

     For recommended advertising interval
     https://developer.apple.com/library/content/qa/qa1931/_index.html
  */
  Bluefruit.Advertising.restartOnDisconnect(true);
  Bluefruit.Advertising.setInterval(244, 244);    // in unit of 0.625 ms
  Bluefruit.Advertising.setFastTimeout(0);      // number of seconds in fast mode
  Bluefruit.Advertising.start(0);                // 0 = Don't stop advertising after n seconds
}

// callback invoked when central connects
void connect_callback(uint16_t conn_handle)
{
  // Get the reference to current connection
  BLEConnection* connection = Bluefruit.Connection(conn_handle);

  char central_name[32] = { 0 };
  connection->getPeerName(central_name, sizeof(central_name));

  //  Serial.print("Connected to ");
  //  Serial.println(central_name);
}

/**
   Callback invoked when a connection is dropped
   @param conn_handle connection where this event happens
   @param reason is a BLE_HCI_STATUS_CODE which can be found in ble_hci.h
*/
void disconnect_callback(uint16_t conn_handle, uint8_t reason)
{
  (void) conn_handle;
  (void) reason;

  //  Serial.println();
  //  Serial.print("Disconnected, reason = 0x"); Serial.println(reason, HEX);
}
