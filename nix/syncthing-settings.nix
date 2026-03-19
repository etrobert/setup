{ dataDir }:
{
  options.urAccepted = -1; # Disable usage reporting/telemetry
  devices = {
    "phone".id = "HXCEJSO-YRJ7XSQ-B2MTHEW-6WXVLAF-IOMVQK6-SE7CITW-346VKQA-D2PSNAO";
    "leod".id = "5DCR24L-XI2U2AF-7AMMGXE-S4R7TQK-PDOYLGT-5UZLZNV-SERXLIT-BJ6QEAY";
    "tower".id = "3IIJQ3X-2BY72RR-YVNBZBQ-OAB6PM5-SPS3WPG-MCPTFVD-YSQ33SS-X4Q5DA3";
    "pi".id = "EOXLGRM-GCJUBN3-6HD656O-KYXFYEX-N425OIL-SLBL7XJ-VN2RSXW-F7VJMAI";
    "etiennerobert@aaron".id = "JSQOTCO-D4X3GSX-ECPK33M-22LUG5V-AGG6ARY-EQAP7PB-JGOMRQK-ZRVJDAL";
  };
  folders = {
    "sync" = {
      path = "${dataDir}/sync";
      devices = [
        "phone"
        "leod"
        "tower"
        "pi"
        "etiennerobert@aaron"
      ];
      versioning = {
        type = "staggered";
        params.maxAge = "2592000"; # 30 days
      };
    };
  };
}
