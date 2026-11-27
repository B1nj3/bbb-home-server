# Security hardening: removing the public Greenlight portal and moving admin access to Tailscale

| | |
| --- | --- |
| **Date** | November 2026 |
| **System** | Self-hosted BigBlueButton class server (`class.<domain>`) |
| **Trigger** | After upgrading BigBlueButton from 3.0 to 4.0, the site root served a public Greenlight Sign in / Sign up page |
| **Category** | Security misconfiguration / unneeded attack surface (OWASP Top 10: A05) |
| **Status** | Fixed and verified |

## Summary

The class server only needs to be reached through the school website, which creates and joins meetings with signed API calls. After an upgrade, the root of the site started serving **Greenlight v3**, an optional front end with public **Sign in** and **Sign up** forms. I took Greenlight out of nginx. That first caused a `500 Internal Server Error`, which I diagnosed and fixed by restoring the default front-end page. I also moved all server administration onto a private **Tailscale** network, so SSH is never reachable from the internet.

## Objectives

1. **Reduce the public attack surface.** No public login or self-registration portal on the media server.
2. **Keep the site root working.** The domain should answer with the default BigBlueButton page, not an error.
3. **Make remote administration private.** SSH only over an encrypted private network, never through the router.

## 1. Finding: a public login portal

Opening `https://class.<domain>/` in a private browser window showed Greenlight's sign-in page with a working **Sign up** link.

| Risk | Detail |
| --- | --- |
| Unauthorised use | Anyone could register, create rooms and run meetings on the server, using its bandwidth, CPU and recording storage. |
| Safeguarding and reputation | The server carries children's lessons. Strangers could host any content under the school's domain. |
| Brute force and spam | A public login form invites password guessing, credential stuffing and fake sign-ups. |
| Reconnaissance | Every public web interface is a fingerprint that automated scanners look for. |

## 2. Fix: take Greenlight out of nginx

BigBlueButton serves optional front ends through small nginx snippet files in `/usr/share/bigbluebutton/nginx/`. I disabled Greenlight's snippet by renaming it:

```bash
sudo mv /usr/share/bigbluebutton/nginx/greenlight-v3.nginx \
        /usr/share/bigbluebutton/nginx/greenlight-v3.nginx.disabled
```

## 3. Problem: `500 Internal Server Error` on the root domain

After that change, the domain returned a `500` error.

**Root cause:** when Greenlight was installed, the installer had also disabled the default front end (`default-fe.nginx` → `default-fe.nginx.disabled`). With **both** snippets disabled, nginx had no handler for `/`.

**Resolution:** re-enable the default front end, test the configuration, then reload:

```bash
sudo mv /usr/share/bigbluebutton/nginx/default-fe.nginx.disabled \
        /usr/share/bigbluebutton/nginx/default-fe.nginx
sudo nginx -t && sudo systemctl reload nginx
```

`nginx -t` comes first, so a broken configuration is caught before it can take the site down. The same steps are in [`scripts/05-remove-greenlight.sh`](../scripts/05-remove-greenlight.sh).

## 4. Private remote administration with Tailscale

SSH (port 22) is not forwarded by the router. For off-site administration, both the server and the admin workstation join a private Tailscale network (WireGuard-encrypted, peer to peer):

```bash
# on the server
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
sudo tailscale set --ssh      # Tailscale SSH: identity-based login, no SSH keys to manage

# from the admin workstation (also signed in to the same tailnet)
ssh <admin-user>@<tailscale-ip-of-server>
```

The server is reachable for administration from anywhere, but SSH stays invisible to the public internet.

## Verification

| Check | How | Result |
| --- | --- | --- |
| Front page | `https://class.<domain>/` in a private window | "Welcome to BigBlueButton" |
| No sign-up | `https://class.<domain>/signup` | No sign-up form |
| nginx | `sudo nginx -t` | Syntax OK |
| Remote admin | SSH over the Tailscale IP from outside the home network | Connected |
| SSH not public | Port 22 not forwarded on the router | Not reachable from the internet |

## Security outcome

- **No public login portals** on the media server: no password-guessing or self-registration route.
- **Meetings only through the API.** Every create and join call must carry a checksum made with the server's private shared secret, which only the school website holds.
- **Private administration.** SSH only over Tailscale; nothing administrative is exposed to the internet.

## Follow-ups

- [ ] Stop the Greenlight containers as well. Disabling the nginx snippet removes public access, but the containers keep running in the background and still hold a copy of the shared secret: `cd ~/greenlight-v3 && sudo docker compose down` (keeps its data). Remove the data once it is confirmed unneeded.
- [ ] When re-running `bbb-install.sh`, never add `-g` (the option that installs Greenlight).
- [ ] After every upgrade:
  - open the site in a private window;
  - run `docker ps`;
  - run `sudo bbb-conf --check`;
  - run an API test.

## Lessons learned

1. **Upgrades can change what is public.** After every upgrade, check what the internet can see, not just whether the service still runs.
2. **Remove what you don't use.** Every unused interface is something to patch, monitor and secure.
3. **Know what you are switching off.** Disabling one nginx handler without a fallback took the site down. Test with `nginx -t` and check the result straight away.
