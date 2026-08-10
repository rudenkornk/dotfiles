# Fingerprint sensor security — summary

Core principle: a fingerprint is an identifier, not a secret — it cannot be rotated and you leave copies everywhere, including on the device itself.
Every sane design therefore uses the match only as a gate in front of a real cryptographic secret.

## 1. MoC vs MoH

- **Match-on-host (MoH)**: the sensor is a camera; it ships images to the OS, which stores templates on disk and matches in software.
  Templates and matching live inside the attackable OS.
- **Match-on-chip (MoC)**: the sensor's own microcontroller stores templates in its flash and matches internally; templates never leave the chip.
  The host receives only a verdict — which is worthless unless the channel is authenticated, since anything on the bus can say "yes".
- Modern laptop sensors are typically MoC.

## 2. How MoC enrollment and matching work

- Enrollment: finger is scanned several times, the template is assembled and stored inside the sensor under a template ID.
- The host (fprintd) keeps only a bookkeeping record: "user U, finger F → template #N on sensor serial S" (~150 bytes, no biometric data).
- Matching: host asks "verify against template #N"; the chip captures, matches internally, answers matched / not matched.
- This pinning to a recorded template ID protects against attacking with side-loaded keys to sensor (i.e. using a live OS).
  The new template gets a fresh ID that no host record references, so an identify-then-check-ID verify rejects it.
- Without an authenticated channel this bookkeeping is mostly useless.
  If the attacker learns the victim's template-ID string (some sensors allow to read it from chip), they can delete it
  and re-enroll their own finger forcing the same ID, which every host record already trusts.

## 3. How the OS verifies login with SDCP (Windows model)

SDCP = Microsoft's Secure Device Connection Protocol; spec is public.

- **Factory**: vendor burns a unique per-device ECDSA key into the sensor, certified via a chain up to the vendor root;
  immutable boot ROM measures and attests sensor firmware.
- **Pairing (every connection)**: host challenges; sensor answers with cert chain, firmware attestation, and a signature by its factory key over an ECDH exchange.
  Host verifies the chain, both derive a session key; all further sensor messages are MAC'd with it.
  Defeats fake/impersonated hardware and bus MitM. Certificates prove *class* (genuine sensor), the session binding proves *instance*.
- **Enrollment**: "created template #N" arrives sealed, and #N is a MAC over a sensor nonce under the session secret, not a host-chosen value.
- **Login**: host sends a fresh nonce; sensor answers sealed: "nonce + template #N matched".
  Freshness kills replay; naming #N kills maliciously added templates; the seal kills spoofed devices.
- A sensor swapped from an identical laptop passes the certificate check (it is genuine) but fails instance binding: host records name the original device identity,
  and under SDCP that identity is the factory key, which cannot be faked. Result is fallback to password, not a breach.

## 4. Current state on Linux

- **Today**: no SDCP. fprintd talks plaintext USB and trusts any device that claims to be the sensor; no nonce, no seal, no identity proof.
  Device binding is by self-reported serial — honest-hardware bookkeeping only.
  The verdict is reduced to a yes/no over D-Bus to PAM, and a match unlocks nothing cryptographic: keyring stays locked, LUKS/sops have separate TPM paths.
  Trust chain: PAM → root daemon (faith) → any alleged sensor (faith) → finger.
- **In progress**: SDCP host support exists in community forks (EgisTec `egismoc`) and Ubuntu's libfprint TOD fork (1.95.0+tod1, Feb 2026); upstream MR pending.
  Driven by necessity: newest EgisTec firmware refuses to persist enrollments without SDCP.
- **After SDCP lands**: the sensor→fprintd hop becomes real crypto; the fprintd→PAM hop stays a boolean, and the TPM remains uninvolved.
  For the login gate itself that is rough parity with non-enclave Windows; the remaining gaps (enclave for the middleman, secrets behind the gate) are about what login *yields*.

## 5. Strong sensor \<-> TPM connection

Goal: no software in the trusted path — the TPM itself verifies that a match just happened, so even kernel-level malware cannot forge an unseal.
The TPM is not on the USB bus and verifies only proofs made with key material it was given in advance; hence the sensor must persistently hold a key the TPM can check.

Two equivalent schemes:

1. **Asymmetric**: register the sensor's public key in the TPM; per match, the sensor signs "TPM nonce + matched identity"; TPM verifies via `PolicySigned` and unseals.
   Clean provisioning (no secret changes hands), but no firmware exposes per-match signatures — the factory key signs only during pairing, which attests presence, not a match.
   Also: ECDSA is expensive for the MCU, the factory key is unrotatable and a permanent identifier.
1. **Symmetric (what Windows ships as "secure sensors")**: on first sight the OS generates a secret, installs one copy in the sensor and one in the TPM, then forgets it.
   Per login: OS obtains a nonce from the TPM, passes it to the sensor; on match the sensor returns HMAC(secret, nonce + matched user identity); the OS relays it;
   the TPM recomputes the HMAC with its copy and unseals. The HMAC expires in seconds.
   HMAC is the TPM's native session-authorization language, nearly free on the MCU, and the shared secret *is* the instance pairing (a swapped sensor holds no valid secret).
   The OS is a one-time matchmaker and thereafter a courier that cannot forge.

Both require the signed/MAC'd message to contain the TPM's nonce (freshness) and the matched identity (pins to templates that existed at seal time).
Requires the "secure sensor" tier: matching in an isolated environment, secure sample input, secure credential release, presentation-attack detection.
Premium subset of sensors only; plain SDCP sensors fall back to the OS-trusting path.

## 6. What Linux lacks to implement scheme 2

Everything host-side already exists: measured boot + PCR policies, `tpm2-tools` HMAC-key import, HMAC session authorization, SDCP (in progress).
No kernel work — all userspace. Missing are exactly two sensor operations (Windows driver API names; per-vendor USB wire protocol undocumented):

1. `CreateKey` — "store this long-term secret".
1. `IdentifyFeatureSetSecure` — "match; on success return HMAC(secret, nonce + matched identity)".

Path to implementation: check the sensor reports `WINBIO_CAPABILITY_SECURE_SENSOR` under Windows, sniff the Windows driver's provisioning and secure-match traffic,
decode two message types, add to the libfprint driver, plus a small helper that seals TPM secrets under HMAC-session policy.
Nobody is publicly working on this tier; adjacent reverse engineering (python-validity, Goodix SPI, egismoc SDCP) proves feasibility.
Fallback without secure-sensor firmware: reuse the SDCP session key as the TPM-shared secret —
weaker custody (root present at pairing can copy it), still better than a D-Bus boolean.

## 7. Brute-force protection on the sensor — missing

- Consumer sensors target FAR ≈ 1/50,000 per attempt; physical presentation (fabricate + press a fake finger per try) is the only real rate limiter.
  A lifted print (off the laptop chassis itself) beats brute force anyway.
- Electronic image injection is blocked by MoC packaging (imaging array wired directly to the matcher, no "match this image" command) — not by any lockout.
- Throttling: phones keep an escalating lockout counter in the secure world, surviving reboots.
  On PCs the lockout is conventionally the host's job (Windows counts failures and falls back to PIN) — useless against a stolen sensor, since the attacker brings their own host.
  Microsoft's secure-sensor spec does *not* mandate anti-hammering.
- Empirical result (one laptop MoC sensor, 60 consecutive false attempts via `fprintd-verify`): flat latency, no lockout, no errors — **no firmware anti-hammering**.
  Irrelevant today (a stolen sensor unlocks nothing), but it becomes the weak link under scheme 2, where the chip would hold the TPM-shared secret.

## One-line trust chains

- **Windows secure-sensor tier**: TPM \<-> sensor share a secret directly (OS introduced them once, then forgot) → sensor trusts finger. OS is a courier.
- **Windows default / post-SDCP Linux goal**: TPM ← measured OS ← factory-signed sensor ← finger;
  the OS is the trusted joint (Windows armors it with a VBS enclave; Linux has a root daemon).
- **Linux today**: nothing ← root daemon ← any alleged sensor ← finger; a match releases no secret at all.
