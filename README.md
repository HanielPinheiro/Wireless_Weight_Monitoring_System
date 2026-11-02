# PreciousWeight

An end-to-end IoT system for **weighing infants in neonatal care**. It is made of
four parts that talk to each other:

```
 ESP32 scale  ──MQTT/TLS──►  Mosquitto broker  ──MQTT/tcp──►  Spring Boot API  ──JDBC──►  MySQL
                                                                     ▲
                                                                     │ HTTPS
                                                                     │
                                                              Flutter mobile app
```

* the **scale** (ESP32 + load cell) publishes weight samples;
* the **broker** (Mosquitto) carries the messages;
* the **API** (Java / Spring Boot) stores and audits everything in MySQL;
* the **app** (Flutter) is what the nursing staff uses.

This document is a hands-on guide: it tells you what to install, which files to
edit, in which order to start the pieces, and how to confirm that everything
works. Installation procedures themselves are not described here.

---

## 1. What you need

| Tool                | Version / notes                                              |
| ------------------- | ------------------------------------------------------------ |
| **JDK**             | Java 21 (Temurin or equivalent)                              |
| **Maven**           | any recent version; the project ships a wrapper (`mvnw`)      |
| **MySQL**           | 8.x (server and client)                                       |
| **Mosquitto**       | 2.x, including the `mosquitto_passwd`, `mosquitto_pub` and `mosquitto_sub` utilities |
| **IDE**             | IntelliJ IDEA (backend) and/or VS Code                        |
| **Flutter SDK**     | stable channel, Dart 3+ (mobile app only)                     |
| **ESP-IDF**         | v5.x (only if you have the physical scale)                    |
| **OpenSSL**         | to generate the JWT key pair and the MQTT certificates        |
| **Docker**          | optional — only if you prefer to run MySQL as a container      |

---

## 2. Files you must edit before running anything

Nothing in this repository contains a working credential. You must supply your
own values in the places below.

| # | File | What to change |
| - | ---- | -------------- |
| 1 | `deploy/mosquitto/mosquitto.conf` | nothing, unless you move the folder (the paths are relative) |
| 2 | `Api_Java/spring.security/docker/.env.example` | copy it to `.env` and set your own database and broker passwords |
| 3 | `Api_Java/spring.security/src/main/resources/app.key` and `app.pub` | **do not exist** — you must generate them (step 3) |
| 4 | `App_Flutter/lib/repository/helper/constants.dart` | `address_api` — the address of your backend |
| 5 | `Esp32_Codigo/CodigoPrincipal/config/config.h` | `WIFI_DEVICE_NAME`, `MQTT_SERVICE_NAME`, `MQTT_POP` |
| 6 | `Esp32_Codigo/CodigoPrincipal/comm/mqtt_config/mqtt3.h` | `MQTT_ADDRESS` — the address of your broker |
| 7 | `Esp32_Codigo/CodigoPrincipal/comm/mqtt_config/certs/` | **empty** — you must add `ca.crt`, `client.crt`, `client.key` (step 6) |

---

## 3. Step 1 — Start the MQTT broker

Everything in `deploy/mosquitto/` is a ready-to-use boilerplate:

* `mosquitto.conf` — the broker configuration;
* `acl.conf` — who is allowed to publish/subscribe on which topics.

The configuration enables a single plain listener on `127.0.0.1:5278` with
`allow_anonymous false`, so a username and password are mandatory, and it points
to a password file named `passwd` in the same folder.

Open a terminal **inside `deploy/mosquitto/`** (the paths in the configuration
file are relative) and run these three commands:

```bash
# 1. create the password file and define the backend user
mosquitto_passwd -c passwd pw_api
#    you will be asked for the password twice - remember it, you need it later

# 2. create the folder used to persist messages
mkdir data

# 3. start the broker
mosquitto -c mosquitto.conf
```

On Windows the binary is called `mosquitto_passwd.exe`; run the same commands
from `cmd` or PowerShell inside the same folder.

You should see a line saying it is listening on port 5278. Leave this terminal
open.

> The broker user **must be `pw_api`** unless you also edit the `user pw_api`
> block in `acl.conf`, otherwise the backend will be refused.

> The TLS listener on port 8883 is commented out at the bottom of
> `mosquitto.conf`. It is only needed for the physical scale — see step 6.

---

## 4. Step 2 — Create the database

Two schemas are used: `auth_db` (users, roles, enrolled scales) and `app_db`
(clinical data). The API user needs access to both.

**Option A — Docker (easier).** Go to `Api_Java/spring.security/docker/`, copy
`.env.example` to `.env`, edit the values, then:

```bash
docker compose up -d
```

The `init.sql` file in the same folder creates `auth_db` automatically. The
value you put in `PW_DB_APP_USER` must stay `admin` (that is the user the
`GRANT` statement in `init.sql` refers to), unless you also edit that file.

**Option B — your own MySQL server.** Create the schemas and the user by hand:

```sql
CREATE DATABASE IF NOT EXISTS auth_db;
CREATE DATABASE IF NOT EXISTS app_db;
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'your-password-here';
GRANT ALL PRIVILEGES ON auth_db.* TO 'admin'@'localhost';
GRANT ALL PRIVILEGES ON app_db.*  TO 'admin'@'localhost';
FLUSH PRIVILEGES;
```

The tables themselves are created by the application on first start.

---

## 5. Step 3 — Generate the JWT key pair

The API signs its access tokens with an RSA key pair that is **not** shipped.
Generate it and place both files in
`Api_Java/spring.security/src/main/resources/`:

```bash
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out app.key
openssl rsa -pubout -in app.key -out app.pub
```

Two format requirements: the private key must be **PKCS#8** (it starts with
`-----BEGIN PRIVATE KEY-----`) and the public key must be **SPKI** (it starts
with `-----BEGIN PUBLIC KEY-----`). Anything else and the application will not
start.

If you prefer to keep the keys outside the source tree, set the environment
variables `PW_JWT_PUB` and `PW_JWT_PRIV` to their absolute locations — for
example `file:/opt/pw/app.pub` and `file:/opt/pw/app.key`.

> `app.key` is a secret and is listed in `.gitignore`. Never commit it.

---

## 6. Step 4 — Start the backend

The backend reads every sensitive value from environment variables. Define them
(use the same values you chose in step 2 and step 1):

```bash
# Linux / macOS
export PW_DB_AUTH_USER=admin
export PW_DB_AUTH_PASS=your-db-password
export PW_DB_APP_USER=admin
export PW_DB_APP_PASS=your-db-password
export MQTT_BROKER_USER=pw_api
export MQTT_BROKER_PASS=your-broker-password
```

```powershell
# Windows PowerShell
$env:PW_DB_AUTH_USER="admin"
$env:PW_DB_AUTH_PASS="your-db-password"
$env:PW_DB_APP_USER="admin"
$env:PW_DB_APP_PASS="your-db-password"
$env:MQTT_BROKER_USER="pw_api"
$env:MQTT_BROKER_PASS="your-broker-password"
```

| Variable | Default if omitted |
| -------- | ------------------ |
| `PW_DB_AUTH_URL` | `jdbc:mysql://localhost:3306/auth_db` |
| `PW_DB_APP_URL`  | `jdbc:mysql://localhost:3306/app_db` |
| `MQTT_BROKER_URL`| `tcp://localhost:5278` |
| `PW_JWT_PUB`     | `classpath:app.pub` |
| `PW_JWT_PRIV`    | `classpath:app.key` |

`PW_DB_AUTH_USER`, `PW_DB_AUTH_PASS`, `PW_DB_APP_USER`, `PW_DB_APP_PASS`,
`MQTT_BROKER_USER` and `MQTT_BROKER_PASS` have **no** default — the application
refuses to start without them, on purpose.

Now build and run:

```bash
cd Api_Java/spring.security
./mvnw clean package
java -jar target/spring.security-0.0.1-SNAPSHOT.jar
```

Wait for the two lines below in the output; they mean the server is up:

```
Tomcat started on port 8080 (http) with context path '/'
Started Application in ... seconds
```

The API is now on **http://localhost:8080**. Logs are written to the `logs/`
folder, relative to where you launched the jar.

### The default administrator

On the very first start the application creates the roles `ADMIN` and `BASIC`
and one administrator account, defined in
`src/main/java/precious_weight/config/auth/AdminUserConfig.java`:

```
e-mail:   teste@teste.com
password: 123
```

Use this to log in for the first time, then change it. **Do not keep these
values in any deployment that is reachable from the network.**

---

## 7. Step 5 — Run the mobile app

Point the app at your backend by editing `address_api` in
`App_Flutter/lib/repository/helper/constants.dart`:

```dart
const address_api = "http://192.168.0.10:8080";   // your machine's LAN address
```

Values to keep in mind:

| Where the app runs | What to use |
| ------------------ | ----------- |
| Physical phone on the same Wi-Fi | your PC's LAN IP, e.g. `http://192.168.0.10:8080` |
| Android emulator | `http://10.0.2.2:8080` (the emulator's alias for the host) |
| Backend with a real HTTPS certificate | `https://your-domain` |

Then:

```bash
cd App_Flutter
flutter pub get
flutter run
```

Log in with the administrator account from step 4.

> `kDebugMode` in the same file must stay `false`. Set it to `true` **only** if
> you point the app at a host whose TLS certificate is not trusted yet — in that
> mode the app accepts that single host's certificate. For this to work you must
> also replace the `COLOCAR_IP_AQUI` placeholder inside
> `lib/repository/services/api_service.dart` with that host address.

---

## 8. Step 6 — (optional) Flash the scale

Only needed if you have the hardware. Three things must be filled in first.

**a) Device identity** — `Esp32_Codigo/CodigoPrincipal/config/config.h`:

```c
#define WIFI_DEVICE_NAME  "PW_<YOUR_MAC>"   // BLE name, must start with PW_
#define MQTT_SERVICE_NAME "<YOUR_MAC>"      // device id used in the MQTT topics
#define MQTT_POP          "<YOUR_POP>"      // proof of possession asked by the app
```

**b) Broker address** — `Esp32_Codigo/CodigoPrincipal/comm/mqtt_config/mqtt3.h`:

```c
#define MQTT_ADDRESS "mqtts://<YOUR_BROKER_HOST>:8883"
```

The host name **must** match the `server.crt` certificate, because the firmware
verifies it.

**c) Certificates** — put `ca.crt`, `client.crt` and `client.key` in
`Esp32_Codigo/CodigoPrincipal/comm/mqtt_config/certs/`. These three files are
compiled into the binary, so the project does not build without them. The
generation commands are in the `README.md` of that folder.

After that, uncomment the `listener 8883` block in
`deploy/mosquitto/mosquitto.conf`, put `ca.crt` / `server.crt` / `server.key`
in `deploy/mosquitto/certs/`, and add the certificate Common Name to
`deploy/mosquitto/acl.conf` (there is a commented example ready for that).
Then build and flash:

```bash
cd Esp32_Codigo/CodigoPrincipal
idf.py set-target esp32
idf.py build
idf.py -p <YOUR_SERIAL_PORT> flash monitor
```

---

## 9. How to check that it works

**The API answers:**

```bash
curl -X POST http://localhost:8080/login \
  -H "Content-Type: application/json" \
  -d '{"email":"teste@teste.com","password":"123"}'
```

A JSON body with `accessToken` means everything up to step 4 is fine. Note that
this API answers **400** for a wrong password or an unknown user, not 401.

**The broker accepts the backend user** (from inside `deploy/mosquitto/`, in
another terminal):

```bash
mosquitto_sub -h 127.0.0.1 -p 5278 -u pw_api -P 'your-broker-password' -t /status/# -v
```

Publish a test message from a third terminal:

```bash
mosquitto_pub -h 127.0.0.1 -p 5278 -u pw_api -P 'your-broker-password' -t /status/TEST -m "hello"
```

The subscriber must print `hello`. If it does not, check the username in
`acl.conf`.

**The backend is really connected to the broker.** In the API log you should
find:

```
MqttConfig - TRYING TO CONNECT to MQTT broker...
MqttConfig - CONNECTED
MqttSubscriberService - Subscription request sent for topic: /weights/#
```

---

## 10. Troubleshooting

| Symptom | Likely cause |
| ------- | ------------ |
| `Connection Refused: not authorised` from Mosquitto | wrong user or password; check `passwd` and `acl.conf` |
| The API exits immediately with `Could not resolve placeholder 'PW_DB_...'` | the environment variables of step 4 are not set in the terminal that launched the jar |
| The API starts but logs `Lost conn with MQTT BROKER` in a loop | the broker is not running, or the ACL block for `pw_api` is missing |
| `HTTP 400` on `/login` | wrong e-mail/password **or** malformed JSON — check the response body to tell them apart |
| The scale connects to the broker but nothing arrives | the certificate Common Name is not listed in `acl.conf` |
| `mbedtls_ssl_handshake returned -0x2700` in the firmware | the host in `MQTT_ADDRESS` does not match the `server.crt` certificate |

---

## 11. Reference

### 11.1 MQTT topics

`{id}` is the device identifier — the value of `MQTT_SERVICE_NAME` in `config.h`.

| Topic | Direction | Payload |
| ----- | --------- | ------- |
| `/weights/{id}` | device → backend | weight samples |
| `/status/{id}`  | device → backend | connection status; the last will is `DISCONNECTED` |
| `/wifi/{id}`    | device → backend | Wi-Fi signal strength |
| `/scales/{id}`  | backend → device | commands (measure now, tare, set baby, …) |

### 11.2 REST endpoints

| Method | Path | Access |
| ------ | ---- | ------ |
| POST | `/login` | public |
| POST | `/login/reset_password` | public |
| POST | `/users/new` | public (creates a `BASIC` user) |
| POST | `/users/list` | ADMIN |
| POST | `/babies/list`, `/babies/save`, `/babies/update/{code}`, `/babies/search/{code}`, `/babies/enable/{code}`, `/babies/disable/{code}`, `/babies/qr/{code}`, `/babies/image/{code}` | JWT |
| POST | `/scales/list`, `/scales/set/{hash}`, `/scales/baby/set`, `/scales/baby/unset`, `/scales/measure_now/{code}`, `/scales/tare/{code}`, `/scales/wifi_strength/{code}`, `/scales/change_wifi/{code}`, `/scales/hash/{hash}` | JWT |
| POST | `/weight/list`, `/weight/save`, `/weight/babies/{code}`, `/weight/scales/{code}` | JWT |
| POST | `/audit/babies/{code}`, `/audit/scales/{code}`, `/audit/weights/{code}` | JWT |
| POST | `/scale_data/search/{hash}`, `/scale_data/qr/{hash}` | JWT |

### 11.3 Databases

**`auth_db`** — `users`, `roles`, `user_roles_rel`, `scales`
(`mac` and `pop` fields identify a scale).

**`app_db`** — `babies`, `scales`, `weights`, `wifi_connectivity`,
`wifi_strengths`. Every table has a companion `*_AUDIT` table filled in by
Hibernate Envers, plus `CustomRevisionEntity` holding revision metadata.

### 11.4 Metrological specification

* resolution `d = 1 g`
* verification scale interval `e = 10 g`
* series 1 / 2 / 5 × 10ⁿ

Three test families are part of the validation protocol: **eccentricity**
(off-centre loading), **fidelity** (comparison against reference masses) and
**mobility/sensitivity** (load equal to the smallest division).

### 11.5 Limitations

This is a **research prototype**, not certified medical equipment. It must not
be used for clinical decisions without proper metrological certification and
regulatory approval. Two behaviours are intentional in this release and are
documented so they are not mistaken for defects:

* `POST /users/new` and `POST /login/reset_password` are public — the API does
  not treat the seeded administrator password as a security boundary;
* the firmware disables TLS Common Name verification only when a broker is
  addressed by IP; a proper host name and a matching `server.crt` are required
  in production.

---

## 12. License

See [`LICENSE`](LICENSE). If you use this work in academic research, please cite
the corresponding PreciousWeight publication (UNIFESP).
