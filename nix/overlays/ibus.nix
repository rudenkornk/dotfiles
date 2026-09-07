_: final: prev: {

  # IBus generates this registry before NixOS adds custom XKB layouts, so register their engines explicitly.
  ibus-with-plugins = prev.ibus-with-plugins.overrideAttrs (oldAttrs: {
    pathsToLink = oldAttrs.pathsToLink ++ [ "/share/ibus/component" ]; # Materialize the directory for replacement.
    postBuild = (oldAttrs.postBuild or "") + ''
        unlink "$out/share/ibus/component/simple.xml"
        substitute "${final.ibus}/share/ibus/component/simple.xml" "$out/share/ibus/component/simple.xml" \
          --replace-fail \
            '    </engines>' \
            '        <engine>
              <name>xkb:qwerty_rnk::eng</name>
              <language>en</language>
              <license>GPL</license>
              <author>Rudenko Roman</author>
              <layout>qwerty_rnk</layout>
              <longname>English (qwerty, rnk)</longname>
              <description>English (qwerty, rnk)</description>
              <icon>ibus-keyboard</icon>
              <rank>50</rank>
          </engine>
          <engine>
              <name>xkb:jcuken_rnk::rus</name>
              <language>ru</language>
              <license>GPL</license>
              <author>Rudenko Roman</author>
              <layout>jcuken_rnk</layout>
              <longname>Russian (jcuken, rnk)</longname>
              <description>Russian (jcuken, rnk)</description>
              <icon>ibus-keyboard</icon>
              <rank>50</rank>
          </engine>
      </engines>'
    '';
  });
}
