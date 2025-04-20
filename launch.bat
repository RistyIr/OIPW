@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: -----------------------------------------------------------
:: Configuration des chemins de base
:: -----------------------------------------------------------
set "BASE=PATH\Deploiement"
set "WIMFILE=%BASE%\wim\install.wim"
set "MOUNTDIR=%BASE%\mount"
set "BOOTWIM=%BASE%\boot\boot.wim"
set "BOOTMOUNT=%BASE%\bootmount"
set "EXPORTDIR=%BASE%\export"

:: Création des dossiers si inexistants
if not exist "%MOUNTDIR%" mkdir "%MOUNTDIR%"
if not exist "%BOOTMOUNT%" mkdir "%BOOTMOUNT%"
if not exist "%EXPORTDIR%" mkdir "%EXPORTDIR%"

:: -----------------------------------------------------------
:: Vérification et sélection de l'édition Windows
:: -----------------------------------------------------------
if not exist "%WIMFILE%" (
    echo [ERREUR] Le fichier install.wim est introuvable !
    pause
    exit /b 1
)

echo [INFO] Affichage des informations de install.wim
DISM /Get-WimInfo /WimFile:"%WIMFILE%"
echo.
set /p INDEX="Entrez l'index de l'édition Windows à modifier : "

:: Vérification que l'index est un nombre
for /f "delims=0123456789" %%i in ("%INDEX%") do (
    echo [ERREUR] Index invalide !
    pause
    exit /b 1
)


echo [INFO] Montage de install.wim
if not exist "%MOUNTDIR%\Windows" (
    DISM /Mount-Wim /WimFile:"%WIMFILE%" /Index:%INDEX% /MountDir:"%MOUNTDIR%"
    if %errorlevel% neq 0 (
        echo [ERREUR] Échec du montage de install.wim.
        pause
        exit /b 1
    )
)

echo [INFO] Montage de install.wim réussi.

goto MENU

:: -----------------------------------------------------------
:: Menu principal
:: -----------------------------------------------------------
:MENU
cls
echo.
echo ==================================================
echo  Menu de personnalisation
echo    1. Ajout de mises à jour
echo    2. Ajout de pilotes
echo    3. Ajout d'applications
echo    4. Personnaliser fond d'écran
echo    5. Finaliser et quitter
echo ==================================================
set /p CHOICE="Votre choix (1-5) : "

if "%CHOICE%"=="1" goto SUBMENU_UPDATES
if "%CHOICE%"=="2" goto INJECT_DRIVERS
if "%CHOICE%"=="3" goto ADD_APPS
if "%CHOICE%"=="4" goto CUSTOM_WALLPAPER
if "%CHOICE%"=="5" goto FINALIZE

echo [ERREUR] Option invalide. Veuillez choisir entre 1 et 5.
pause
goto MENU

:: -----------------------------------------------------------
:: Sous-menu Mises à jour
:: -----------------------------------------------------------
:SUBMENU_UPDATES
cls
echo.
echo ==================================================
echo  Sélectionnez le type de mises à jour à intégrer
echo    1. Windows 11 24H2  (Deploiement\updates)
echo    2. Windows 11 23H2  (Deploiement\updatele)
echo    3. Windows 10       (Deploiement\updateten)
echo    4. Retour au menu principal
echo ==================================================
set /p updateChoice="Votre choix (1-4) : "
if "%updateChoice%"=="1" (
    set "UPDATES=%BASE%\updates"
    set "VERSION_UPDATE=Windows 11 24H2"
) else if "%updateChoice%"=="2" (
    set "UPDATES=%BASE%\updatele"
    set "VERSION_UPDATE=Windows 11 23H2"
) else if "%updateChoice%"=="3" (
    set "UPDATES=%BASE%\updateten"
    set "VERSION_UPDATE=Windows 10"
) else if "%updateChoice%"=="4" (
    goto MENU
) else (
    echo [ERREUR] Option invalide.
    pause
    goto SUBMENU_UPDATES
)
echo [ACTION] Ajout des mises à jour pour %VERSION_UPDATE%
DISM /Add-Package /Image:"%MOUNTDIR%" /PackagePath:"%UPDATES%"
if %errorlevel% neq 0 (
    echo [ERREUR] Échec de l'ajout des mises à jour.
    pause
    goto ERROR_EXIT
) else (
    echo [INFO] Mises à jour ajoutées.
)
goto MENU

:: -----------------------------------------------------------
:: Sous-menu Pilotes
:: -----------------------------------------------------------
:INJECT_DRIVERS
cls
echo [ACTION] Intégration des pilotes

:: Injection dans boot.wim
if exist "%BASE%\drivers\bootInsert" (
    if exist "%BOOTWIM%" (
        echo [INFO] Montage de boot.wim
        DISM /Mount-Wim /WimFile:"%BOOTWIM%" /Index:2 /MountDir:"%BOOTMOUNT%"
        if %errorlevel% neq 0 (
            echo [ERREUR] Échec du montage de boot.wim.
            pause
            goto ERROR_EXIT
        )
    ) else (
        echo [ERREUR] Le fichier boot.wim est introuvable !
        pause
        goto ERROR_EXIT
    )
    echo [INFO] Injection des pilotes dans boot.wim depuis %BASE%\drivers\bootInsert
    DISM /Add-Driver /Image:"%BOOTMOUNT%" /Driver:"%BASE%\drivers\bootInsert" /Recurse
    if %errorlevel% neq 0 (
        echo [ERREUR] Échec de l'ajout des pilotes dans boot.wim.
    ) else (
        echo [INFO] Pilotes injectés dans boot.wim
    )
) else (
    echo [INFO] Aucun pilote à injecter dans boot.wim ^(dossier %BASE%\drivers\bootInsert introuvable^)
)


:: Injection dans install.wim
if exist "%BASE%\drivers\finalInsert" (
    echo [INFO] Injection des pilotes dans install.wim depuis %BASE%\drivers\finalInsert
    DISM /Add-Driver /Image:"%MOUNTDIR%" /Driver:"%BASE%\drivers\finalInsert" /Recurse
    if %errorlevel% neq 0 (
        echo [ERREUR] Échec de l'ajout des pilotes dans install.wim.
    ) else (
        echo [INFO] Pilotes injectés dans install.wim.
    )
) else (
    echo [INFO] Aucun pilote à injecter dans install.wim ^(dossier %BASE%\drivers\finalInsert introuvable^)
)
goto MENU

:: -----------------------------------------------------------
:: Sous-menu Applications
:: -----------------------------------------------------------
:ADD_APPS
cls
echo [ACTION] Ajout des applications...
if not exist "%MOUNTDIR%\install" mkdir "%MOUNTDIR%\install"
xcopy "%BASE%\applications\*.*" "%MOUNTDIR%\install\" /s /y
if not exist "%MOUNTDIR%\Windows\Setup\Scripts" mkdir "%MOUNTDIR%\Windows\Setup\Scripts"
(
  echo @echo off
  echo echo Installation des applications en cours
  echo for %%F in ("%%SystemDrive%%\install\*.exe") do (
  echo.    start /wait "" "%%F" /silent
  echo )
  echo exit 0
) > "%MOUNTDIR%\Windows\Setup\Scripts\SetupComplete.cmd"
echo [INFO] Applications ajoutées et script SetupComplete.cmd créé.
pause
goto MENU

:: -----------------------------------------------------------
:: Personnalisation du fond d'écran
:: -----------------------------------------------------------
:CUSTOM_WALLPAPER
cls
echo [ACTION] Personnalisation du fond d'écran
set /p WALLPAPER_NAME="Entrez le nom du fichier dans %BASE%\wallpapers : "
if not exist "%BASE%\wallpapers\%WALLPAPER_NAME%" (
    echo [ERREUR] Image introuvable !
    pause
    goto MENU
)

:: Copie l'image dans le dossier de Windows
if not exist "%MOUNTDIR%\Windows\Web\Wallpaper\Windows" mkdir "%MOUNTDIR%\Windows\Web\Wallpaper\Windows"
copy /Y "%BASE%\wallpapers\%WALLPAPER_NAME%" "%MOUNTDIR%\Windows\Web\Wallpaper\Windows\%WALLPAPER_NAME%"

:: --- Modification du profil par défaut ---
echo [INFO] Modification du profil par défaut
reg load HKU\DefaultUser "%MOUNTDIR%\Users\Default\NTUSER.DAT"
if %errorlevel% neq 0 (
    echo [ERREUR] Impossible de charger le registre offline
    pause
    goto MENU
)
reg add "HKU\DefaultUser\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "C:\Windows\Web\Wallpaper\Windows\%WALLPAPER_NAME%" /f
reg add "HKU\DefaultUser\Control Panel\Desktop" /v WallpaperStyle /t REG_SZ /d "2" /f
reg unload HKU\DefaultUser

:: --- Création d'un script post-installation ---
echo [INFO] Création du script post-installation pour appliquer le fond d'écran au premier démarrage
if not exist "%MOUNTDIR%\Windows\Setup\Scripts" mkdir "%MOUNTDIR%\Windows\Setup\Scripts"
(
    echo @echo off
    echo reg add "HKCU\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "C:\Windows\Web\Wallpaper\Windows\%WALLPAPER_NAME%" /f
    echo reg add "HKCU\Control Panel\Desktop" /v WallpaperStyle /t REG_SZ /d "2" /f
    echo RUNDLL32.EXE USER32.DLL,UpdatePerUserSystemParameters
) > "%MOUNTDIR%\Windows\Setup\Scripts\set_wallpaper.bat"

if not exist "%MOUNTDIR%\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup" mkdir "%MOUNTDIR%\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
copy /Y "%MOUNTDIR%\Windows\Setup\Scripts\set_wallpaper.bat" "%MOUNTDIR%\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\"

echo [INFO] Fond d'écran personnalisé appliqué
goto MENU


:: -----------------------------------------------------------
:: Finalisation et Exportation
:: -----------------------------------------------------------
:FINALIZE
cls
echo [INFO] Finalisation des modifications...
goto EXPORT_WIM

:EXPORT_WIM
echo [INFO] Enregistrement des fichiers WIM modifiés
if exist "%MOUNTDIR%\Windows" (
    DISM /Unmount-Wim /MountDir:"%MOUNTDIR%" /Commit
    if %errorlevel% neq 0 (
        echo [ERREUR] Échec de sauvegarde de install
        pause
        goto ERROR_EXIT
    )
)
if exist "%BOOTMOUNT%\Windows" (
    DISM /Unmount-Wim /MountDir:"%BOOTMOUNT%" /Commit
    if %errorlevel% neq 0 (
        echo [ERREUR] Échec de sauvegarde de boot
        pause
        goto ERROR_EXIT
    )
)
DISM /Export-Image /SourceImageFile:"%WIMFILE%" /SourceIndex:%INDEX% /DestinationImageFile:"%EXPORTDIR%\install.wim" /Compress:max /CheckIntegrity
if %errorlevel% neq 0 (
    echo [ERREUR] Échec de l'exportation de install.wim
    pause
)
DISM /Export-Image /SourceImageFile:"%BOOTWIM%" /SourceIndex:2 /DestinationImageFile:"%EXPORTDIR%\boot.wim" /Compress:max /CheckIntegrity
if %errorlevel% neq 0 (
    echo [ERREUR] Échec de l'exportation de boot.wim
    pause
)
echo [INFO] Exportation et démontage terminés avec succès
pause
exit /b

:ERROR_EXIT
echo [INFO] Une erreur est survenue, démontage en mode DISCARD
if exist "%MOUNTDIR%\Windows" (
    DISM /Unmount-Wim /MountDir:"%MOUNTDIR%" /Discard
)
if exist "%BOOTMOUNT%\Windows" (
    DISM /Unmount-Wim /MountDir:"%BOOTMOUNT%" /Discard
)
pause
exit /b 1