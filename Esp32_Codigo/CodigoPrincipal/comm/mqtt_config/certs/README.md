# MQTT TLS certificates (not included)

This directory intentionally ships **without** certificates. The three files
below are embedded into the firmware image at build time by
[`../CMakeLists.txt`](../CMakeLists.txt) via `target_add_binary_data`, so the
project will not build until you create them.

| File         | Content                                              |
| ------------ | ---------------------------------------------------- |
| `ca.crt`     | PEM certificate of the CA that signs the broker       |
| `client.crt` | PEM client certificate (its CN becomes the MQTT user) |
| `client.key` | PEM client private key (PKCS#8)                       |

Generate a throw-away CA and client certificate for local development, e.g.:

```bash
# 1. CA
openssl req -new -x509 -days 3650 -nodes \
  -keyout ca.key -out ca.crt -subj "/CN=pw-local-ca"

# 2. Client key + CSR
openssl req -new -nodes -newkey rsa:2048 \
  -keyout client.key -out client.csr -subj "/CN=ESP32"

# 3. Sign the client certificate
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out client.crt -days 3650
```

The broker must be configured with the same `ca.crt` and with
`require_certificate true` / `use_identity_as_username true` if you want the
certificate CN to act as the MQTT username.

> **Never commit real certificates or private keys.** `*.key`, `*.crt` and
> `*.csr` are already listed in the repository `.gitignore`.
