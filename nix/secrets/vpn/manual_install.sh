#!/usr/bin/env bash

sudo openvpn --config CONFIG.ovpn --auth-user-pass AUTH.auth
sudo nmcli c import type openvpn file CONFIG.ovpn
