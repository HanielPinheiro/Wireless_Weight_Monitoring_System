#include "HX711.h"
#include <cfloat>

// ============================================================
// PINAGEM
// ============================================================

const int SCALE1_DOUT_PIN = 21;
const int SCALE1_SCK_PIN = 22;

const int SCALE2_DOUT_PIN = 16;
const int SCALE2_SCK_PIN = 14;

const int SCALE3_DOUT_PIN = 32;
const int SCALE3_SCK_PIN = 33;

const int SCALE4_DOUT_PIN = 25;
const int SCALE4_SCK_PIN = 26;

// ============================================================
// HX711
// ============================================================

HX711 scale1;
HX711 scale2;
HX711 scale3;
HX711 scale4;

HX711 *scales[4] = { &scale1, &scale2, &scale3, &scale4 };

// ============================================================
// FATORES DE CALIBRAÇÃO PURIFICADOS (REGRESSÃO LINEAR SEM ANOMALIAS)
// ============================================================
// Ajustados após correção do peso real de 2093g (antigo 2005g)
// float calibration_factor[4] = { 399.65f, 404.81f, 390.79f, 398.76f }; // V3 +-1g de erro
float calibration_factor[4] = { 399.65f, 404.1f, 390.1f, 398.1f };

// ============================================================
// OFFSETS (TARA INICIAL DOS SENSORES)
// ============================================================
float offset[4] = { 405827.2f, 217586.3f, 316564.5f, 310181.5f };

// ============================================================
// INSERTION SORT (FILTRO DE MEDIANA)
// ============================================================

void insertionSort(float arr[], int n) {
  for (int i = 1; i < n; i++) {
    float key = arr[i];
    int j = i - 1;

    while (j >= 0 && arr[j] > key) {
      arr[j + 1] = arr[j];
      j--;
    }

    arr[j + 1] = key;
  }
}

// ============================================================
// LEITURA FILTRADA DO HX711
// ============================================================

float readFilteredRaw(HX711 &scale) {
  const int TOTAL_SAMPLES = 7;
  float samples[TOTAL_SAMPLES];

  for (int i = 0; i < TOTAL_SAMPLES; i++) {
    samples[i] = scale.read();
    delay(10);
  }

  insertionSort(samples, TOTAL_SAMPLES);

  float sum = 0.0;
  for (int i = 2; i < TOTAL_SAMPLES - 2; i++) {
    sum += samples[i];
  }

  return sum / 3.0f;
}

// ============================================================
// LEITURA DOS 4 SENSORES
// ============================================================

void readAllRaw(float raw[4]) {
  for (int i = 0; i < 4; i++) {
    raw[i] = readFilteredRaw(*scales[i]);
  }
}

// ============================================================
// CONVERSÃO DELTA -> PESO
// ============================================================

void calculateSensorWeights(float raw[4], float sensorWeights[4], float deltas[4]) {
  for (int i = 0; i < 4; i++) {
    deltas[i] = raw[i] - offset[i];
    sensorWeights[i] = deltas[i] / calibration_factor[i];
  }
}

// ============================================================
// PESO TOTAL BASE (SOMA LINEAR DOS SENSORES)
// ============================================================

float calculateBaseWeight(float sensorWeights[4]) {
  return sensorWeights[0] + sensorWeights[1] + sensorWeights[2] + sensorWeights[3];
}

// ============================================================
// AUTO-ZERO
// ============================================================

void updateAutoZero(float raw[4], float &finalWeight) {
  if (finalWeight > -20.0f && finalWeight < 20.0f) {
    finalWeight = 0.0f;
  }

  if (finalWeight > -5.0f && finalWeight < 5.0f) {
    for (int i = 0; i < 4; i++) {
      offset[i] += (raw[i] - offset[i]) * 0.03f;
      scales[i]->set_offset(offset[i]);
    }
  }
}

// ============================================================
// INICIALIZA SENSOR
// ============================================================

void turnOnSensor(HX711 &scale, int dout, int sck, float calFactor, float &sensorOffset) {
  scale.begin(dout, sck);

  scale.power_down();
  delay(10);
  scale.power_up();

  delay(1500);

  scale.set_scale(calFactor);
  scale.tare(40);

  sensorOffset = scale.get_offset();
}

// ============================================================
// SETUP
// ============================================================

void setup() {
  Serial.begin(115200);

  delay(1000);

  Serial.println();
  Serial.println("============================================================");
  Serial.println(" CALIBRACAO ESPACIAL V4 - MODELO LINEAR PERFEITO");
  Serial.println("============================================================");

  Serial.println(" Realizando tara...");

  turnOnSensor(scale1, SCALE1_DOUT_PIN, SCALE1_SCK_PIN, calibration_factor[0], offset[0]);
  turnOnSensor(scale2, SCALE2_DOUT_PIN, SCALE2_SCK_PIN, calibration_factor[1], offset[1]);
  turnOnSensor(scale3, SCALE3_DOUT_PIN, SCALE3_SCK_PIN, calibration_factor[2], offset[2]);
  turnOnSensor(scale4, SCALE4_DOUT_PIN, SCALE4_SCK_PIN, calibration_factor[3], offset[3]);

  Serial.println();
  Serial.println("Offsets iniciais:");
  Serial.printf("S1: %.1f | S2: %.1f | S3: %.1f | S4: %.1f\n", offset[0], offset[1], offset[2], offset[3]);
  Serial.printf("Fatores de Calibracao: S1: %.2f | S2: %.2f | S3: %.2f | S4: %.2f\n", 
                calibration_factor[0], calibration_factor[1], calibration_factor[2], calibration_factor[3]);
  Serial.println("============================================================");
}

// ============================================================
// LOOP PRINCIPAL
// ============================================================

void loop() {
  float raw[4];
  float deltas[4];
  float sensorWeights[4];

  readAllRaw(raw);
  calculateSensorWeights(raw, sensorWeights, deltas);

  float baseWeight = calculateBaseWeight(sensorWeights);
  float finalWeight = baseWeight;

  updateAutoZero(raw, finalWeight);

  Serial.println();
  Serial.println("============================================================");
  Serial.printf("RAW      | S1: %.1f | S2: %.1f | S3: %.1f | S4: %.1f\n", raw[0], raw[1], raw[2], raw[3]);
  Serial.printf("DELTAS   | S1: %.1f | S2: %.1f | S3: %.1f | S4: %.1f\n", deltas[0], deltas[1], deltas[2], deltas[3]);
  Serial.printf("WEIGHTS  | S1: %.2f | S2: %.2f | S3: %.2f | S4: %.2f\n", sensorWeights[0], sensorWeights[1], sensorWeights[2], sensorWeights[3]);
  Serial.println("------------------------------------------------------------");
  Serial.printf("PESO MEDIDO (SOMA LINEAR) : %8.2f g\n", finalWeight);
  Serial.println("============================================================");

  delay(200);
}
