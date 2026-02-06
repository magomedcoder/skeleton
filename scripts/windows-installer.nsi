!define APP_NAME "Skeleton"

!ifndef APP_VERSION
!define APP_VERSION "1.0.0"
!endif
!define COMPANY_NAME "Skeleton"

OutFile "SkeletonSetup.exe"
InstallDir "$PROGRAMFILES\\${APP_NAME}"
InstallDirRegKey HKLM "Software\\${COMPANY_NAME}\\${APP_NAME}" "Install_Dir"

Page directory
Page instfiles
UninstPage uninstConfirm
UninstPage instfiles

Section "Install"
  SetOutPath "$INSTDIR"

  File /r "..\\client-side\\build\\windows\\x64\\runner\\Release\\*.*"

  WriteRegStr HKLM "Software\\${COMPANY_NAME}\\${APP_NAME}" "Install_Dir" "$INSTDIR"

  CreateShortCut "$DESKTOP\\${APP_NAME}.lnk" "$INSTDIR\\skeleton.exe"

  CreateDirectory "$SMPROGRAMS\\${APP_NAME}"
  CreateShortCut "$SMPROGRAMS\\${APP_NAME}\\${APP_NAME}.lnk" "$INSTDIR\\skeleton.exe"
  CreateShortCut "$SMPROGRAMS\\${APP_NAME}\\Uninstall.lnk" "$INSTDIR\\uninstall.exe"

  WriteUninstaller "$INSTDIR\\uninstall.exe"
SectionEnd

Section "Uninstall"
  Delete "$DESKTOP\\${APP_NAME}.lnk"
  Delete "$SMPROGRAMS\\${APP_NAME}\\${APP_NAME}.lnk"
  Delete "$SMPROGRAMS\\${APP_NAME}\\Uninstall.lnk"
  RMDir "$SMPROGRAMS\\${APP_NAME}"

  Delete "$INSTDIR\\uninstall.exe"
  RMDir /r "$INSTDIR"

  DeleteRegKey HKLM "Software\\${COMPANY_NAME}\\${APP_NAME}"
SectionEnd
