#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <Wire.h>

// อัปเดตขา I2C ใหม่ตามการต่อสายจริง
#define I2C_SDA 6
#define I2C_SCL 7

Adafruit_MPU6050 mpu;

void setup() {
  Serial.begin(115200);
  while (!Serial) { delay(10); }

  Serial.println("กำลังเริ่มทดสอบ MPU-6050...");

  // เริ่มต้นการเชื่อมต่อ I2C ด้วยขา 6 และ 7
  Wire.begin(I2C_SDA, I2C_SCL);

  if (!mpu.begin(0x68, &Wire)) {
    Serial.println("❌ ไม่พบเซ็นเซอร์ MPU-6050 โปรดตรวจสอบสายอีกครั้ง");
    while (1) { delay(10); }
  }
  Serial.println("✅ พบเซ็นเซอร์ MPU-6050 แล้ว!");

  mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
  mpu.setGyroRange(MPU6050_RANGE_500_DEG);
  mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
  
  delay(100);
}

void loop() {
  sensors_event_t a, g, temp;
  mpu.getEvent(&a, &g, &temp);

  Serial.print("ความเร่ง X: "); Serial.print(a.acceleration.x);
  Serial.print(", Y: "); Serial.print(a.acceleration.y);
  Serial.print(", Z: "); Serial.print(a.acceleration.z);

  Serial.print(" | ไจโร X: "); Serial.print(g.gyro.x);
  Serial.print(", Y: "); Serial.print(g.gyro.y);
  Serial.print(", Z: "); Serial.println(g.gyro.z);

  delay(500);
}