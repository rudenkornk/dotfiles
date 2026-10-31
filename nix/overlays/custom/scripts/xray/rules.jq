def domains:
  [ .[] |
    (.domain[]? | "full:" + .),
    (.domain_suffix[]? |
      if startswith(".") then
        "regexp:" + gsub("\\."; "\\.") + "$"
      else "domain:" + . end)
  ] | unique;

($ru[0].rules + $category[0].rules + $inside[0].rules | domains) as $direct |
($ads[0].rules | domains) as $blocked |
($direct + ["full:crates.io", "full:cache.nixos.org", "full:lazyvim.org", "full:pypi.org"] | unique) as $direct |
$base[0] |
.dns.servers[0].domains = $direct |
.routing.rules += [
  {"domain": $blocked, "outboundTag": "block", "ruleTag": "adblock"},
  {"ip": ["geoip:private"], "outboundTag": "direct", "ruleTag": "private-direct"},
  {"ip": [$ip[0].rules[].ip_cidr[]], "outboundTag": "direct", "ruleTag": "ru-ip-direct"},
  {"domain": $direct, "outboundTag": "direct", "ruleTag": "domain-direct"}
]
