_: final: _: {
  ThroneRun = final.writeShellApplication {
    name = "ThroneRun";
    runtimeInputs = [ final.throne ];
    text = builtins.readFile ./ThroneRun/ThroneRun.sh;
  };
}
