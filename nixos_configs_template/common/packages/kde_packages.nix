{ pkgs, ... }:
{
  # Add KDE system packages
  environment.systemPackages = with pkgs; [
    kdePackages.filelight         # Disk usage analyzer
    kdePackages.kate              # Advanced text editor
    kdePackages.kcalc             # Scientific calculator
    kdePackages.partitionmanager  # Disk partition manager
    kdePackages.print-manager     # Printer management
    konsave                       # KDE configuration manager
  ];
}