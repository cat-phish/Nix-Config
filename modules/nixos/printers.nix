{
  config,
  inputs,
  lib,
  pkgs,
  pkgs-stable,
  ...
}: {
  imports = [
  ];
  config = {
    # Enable CUPS to print documents.
    services.printing.enable = true;

    # Enable IPP printer discovery
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    hardware.printers = {
      ensurePrinters = [
        {
          name = "Brother_DCP-L2550DW_series";
          location = "Home";
          deviceUri = "dnssd://Brother%20DCP-L2550DW%20series._ipp._tcp.local/?uuid=e3248000-80ce-11db-8000-3c2af47e31d5";
          model = "drv:///sample.drv/generpcl.ppd";
          ppdOptions = {
            PageSize = "Letter";
          };
        }
      ];
      ensureDefaultPrinter = "Brother_DCP-L2550DW_series";
    };

    environment.systemPackages =
      (with pkgs; [
        gutenprint # generic printer drivers
      ])
      ++ (with pkgs-stable; [
        ]);
  };
}
