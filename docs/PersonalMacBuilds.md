# Install the macOS input-fix build

Quit Deskflow, copy `Deskflow.app` into `/Applications`, and replace the previous
copy. Do not run the app from the DMG or keep alternating between official and
personal builds. For different Windows/Mac input methods, keep **Use server's
keyboard language on this computer** disabled on the Mac.

This branch preserves IME character mapping and combines local Mac keyboard
modifiers with shared mouse events. It does not add file transfer support.

## Authorize the new signing identity once

Earlier personal builds were ad-hoc signed. Their code identity changed with the
binary, which could invalidate Accessibility and Input Monitoring grants.
New builds use the persistent `Deskflow Personal Builds (b1ghawk119)` certificate,
with certificate-pinned designated requirements for `org.deskflow.deskflow`
and `deskflow-core`. Bundle identifiers and installation paths remain stable.

The first transition from an ad-hoc or official build may require reauthorization
in **System Settings > Privacy & Security > Accessibility / Input Monitoring**.
If an old enabled entry does not work, remove that Deskflow entry, add the newly
installed app, enable it, and restart Deskflow. Add the bundled core only if macOS
asks for it. Later builds in this branch keep the same signing identity.

This is a self-signed personal build, not an Apple-notarized distribution. If
Gatekeeper blocks the first launch, use **Privacy & Security > Open Anyway**.
Do not disable Gatekeeper, SIP, or edit the TCC database. Users do not need to
install the signing certificate as a trusted root.

## Maintain the release identity

The public certificate is `deploy/mac/input-build-signing.cer`. The private
identity is stored in GitHub Actions secrets `MAC_INPUT_CODESIGN_P12` and
`MAC_INPUT_CODESIGN_P12_PASSWORD`. Reuse them for subsequent releases; replacing
the certificate changes the identity and can require a new permission grant.
Never commit the private key or PKCS#12 archive.

`MAC_INPUT_CODESIGN_IDENTITY` enables package-only signing without the development
entitlements enabled by `APPLE_CODESIGN_DEV`. The default upstream build path is
unchanged. CI mounts the final DMG and verifies the bundle, core, architecture,
and certificate-pinned identity. It also verifies that a different binary signed
by this identity satisfies each shipped requirement, while an ad-hoc binary with
the same identifier is rejected. The result is attached as `signature-report.txt`.

These checks establish signature continuity. Confirm actual TCC grant retention
on the user's Mac when installing the next build, and test Sogou input plus local
Cmd/Shift/Control with the remote mouse after installation.
