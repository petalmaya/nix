{ ... }:

{
  services.swaync = {
    enable = true;
    settings = {
      timeout = 4;
      timeout-low = 2;
      notification-window-width = 500;
      widgets = [
        "title"
        "volume"
        "menubar"
        "dnd"
        "notifications"
      ];
    };
    style = ''
      * {
          font-family: DejaVuSansMono;
          font-size: 20px;
          padding: 5px;
          color: #e8e4b1;
      }

      .notification {
          background-color: rgba(53, 39, 24, 0.95);
      }

      .control-center {
          background-color: rgba(53, 39, 24, 0.95);
      }
    '';
  };
}
