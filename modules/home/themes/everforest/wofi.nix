{ config, pkgs, ... }:

{
  programs.wofi = {
    enable = true;
    style = ''
      window {
        background-color: #2b3339;
        color: #d3c6aa;
        border: 3px solid #a7c080;
        border-radius: 12px;
      }
      #input {
        background-color: #3a454a;
        color: #d3c6aa;
        border: none;
      }
      #inner-box {
        background-color: #2b3339;
      }
      #outer-box {
        background-color: #2b3339;
      }
      #text {
        color: #d3c6aa;
      }
      #entry:selected {
        background-color: #a7c080;
      }
      #entry:selected #text {
        color: #2b3339;
      }
    '';
    settings = {
      allow_images = true;
      allow_markup = true;
      term = "foot";
      width = 600;
      height = 400;
    };
  };
}
