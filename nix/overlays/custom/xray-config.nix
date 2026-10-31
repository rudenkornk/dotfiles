final: _prev:

let
  sources = {
    geoip-ru = final.fetchurl {
      url = "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/3a27e598be95d745b8652860b1337157a8822943/geo/geoip/ru.srs";
      hash = "sha256-85f5NbXUhJMBNGUqhTX3RAIN26aRuZXSz8snl1IWJjY=";
    };
    geosite-ru = final.fetchurl {
      url = "https://raw.githubusercontent.com/hiddify/hiddify-geo/0c36d5b84bec2713c7c4553ae9f853845ee563b1/country/geosite-ru.srs";
      hash = "sha256-J9bzV/+ZshSVIQFtb7b+TPfb5PdLAkbCGt+pJGbe248=";
    };
    geosite-category-ru = final.fetchurl {
      url = "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/3a27e598be95d745b8652860b1337157a8822943/geo/geosite/category-ru.srs";
      hash = "sha256-KLUvYHi6UNqllv9ja+X77TMOhlTrm042x7eGb4EUYDQ=";
    };
    geosite-ru-available-only-inside = final.fetchurl {
      url = "https://raw.githubusercontent.com/runetfreedom/russia-v2ray-rules-dat/f9efdce701f73895cbfad5ef44f8d1f25ec39590/sing-box/rule-set-geosite/geosite-ru-available-only-inside.srs";
      hash = "sha256-1rpX1H0ZCJep9ERf0tGeGA3h2XMiuiq2DBavbgW0kgI=";
    };
    throne-adblocksingbox = final.fetchurl {
      url = "https://raw.githubusercontent.com/217heidai/adblockfilters/0f4071765fad803c9b5b61a6eae01e2ad454d76e/rules/adblocksingbox.srs";
      hash = "sha256-7Pn8JKXq5VIt8aIK+dbWLIyavYgsZaiSTukc15ItsFY=";
    };
  };
in
final.runCommand "xray-config"
  {
    nativeBuildInputs = [
      final.sing-box
      final.jq
    ];
  }
  ''
    ${final.lib.concatStringsSep "\n" (
      final.lib.mapAttrsToList (name: source: ''
        sing-box rule-set decompile ${source} -o ${name}.json
      '') sources
    )}
    mkdir -p "$out"
    jq -n \
      --slurpfile ip geoip-ru.json \
      --slurpfile ru geosite-ru.json \
      --slurpfile category geosite-category-ru.json \
      --slurpfile inside geosite-ru-available-only-inside.json \
      --slurpfile ads throne-adblocksingbox.json \
      --slurpfile base ${./scripts/xray/config.json} \
      -f ${./scripts/xray/rules.jq} > "$out/config.json"
  ''
